/*
 * (c) Kotiki, 2015
 */
public struct QualifiedName: CustomStringConvertible {
    public let clientName: String
    public let serverName: String
    
    public var description: String {
        return clientName
    }
    
    public func template(isFirst: Bool, _ isLast: Bool) -> TemplateParameter {
        return .Dict([
            "clientName":
                TemplateParameter.Value(clientName),
            "capitalizedClientName":
                TemplateParameter.Value(clientName.customCapitalizedSting),
            "serverName":
                TemplateParameter.Value(serverName),
            "first":
                TemplateParameter.Value(isFirst),
            "last":
                TemplateParameter.Value(isLast)
        ])
    }
}

public struct Type: CustomStringConvertible {
    public static let Void = Type(name: "Void", isOptional: false)
    
    public let name: String
    public let isOptional: Bool
    
    public var description: String {
        return name + (isOptional ? "?" : "")
    }

    public func template(isFirst: Bool, _ isLast: Bool) -> TemplateParameter {
        return .Dict([
            "name":       TemplateParameter.Value(name),
            "isOptional": TemplateParameter.Value(isOptional),
            "first":      TemplateParameter.Value(isFirst),
            "last":       TemplateParameter.Value(isLast)
        ])
    }
}

public struct Variable: CustomStringConvertible {
    public let name: QualifiedName
    public let type: Type
    public let defaultValue: String?
    
    public var description: String {
        return name.description + ": " + type.description
    }

    public func template(parentName parentName: QualifiedName,
                         isFirst: Bool, isLast: Bool,
                         additionalFields: [String : TemplateParameter])
                    -> TemplateParameter
    {
        var dict: [String : TemplateParameter] = [
            "parentName": parentName.template(false, false),
            "name":  name.template(false, false),
            "type":  type.template(false, false),
            "first": TemplateParameter.Value(isFirst),
            "last":  TemplateParameter.Value(isLast)
        ]
        if let defaultValue = defaultValue {
            dict["defaultValue"] = .Value(defaultValue)
        }
        for (key, value) in additionalFields {
            dict[key] = value
        }
        return .Dict(dict)
    }
}

public enum ASTNode {
    case Protocol(name: QualifiedName, protocols: [String], fields: [Variable])
    case Struct(name: QualifiedName, protocols: [String], fields: [Variable])
    case Class(name: QualifiedName, protocols: [String], fields: [Variable])
    
    case Func(name: QualifiedName, arguments: [Variable], returnType: Type)
    case CastFunc(name: QualifiedName, arguments: [Variable])
    
    public var template: TemplateParameter {
        switch self {
            case let .Struct(name, protocols, fields):
                return structTemplate("struct", name: name,
                                      protocols: protocols, fields: fields)
            
            case let .Protocol(name, protocols, fields):
                return structTemplate("protocol", name: name,
                                      protocols: protocols, fields: fields)
            
            case let .Class(name, protocols, fields):
                return structTemplate("class", name: name,
                                      protocols: protocols, fields: fields)
            
            case let .Func(name, args, returnType):
                return .Dict(["func":
                    .Dict([
                        "name":       name.template(false, false),
                        "args":       TemplateParameter.Array(args.mapWithFirstLast {
                                          $0.template(parentName: name,
                                                      isFirst: $1, isLast: $2,
                                                      additionalFields: [:])
                                      }),
                        "returnType": returnType.template(false, false)
                    ])])
            
            case let .CastFunc(name, args):
                return .Dict(["castFunc":
                    .Dict([
                        "name": name.template(false, false),
                        "args": TemplateParameter.Array(args.mapWithFirstLast {
                                    $0.template(parentName: name,
                                                isFirst: $1, isLast: $2,
                                                additionalFields: [:])
                                })
                    ])])
        }
    }
    
    public func structTemplate(type: String,
                               name: QualifiedName, protocols: [String],
                               fields: [Variable]) -> TemplateParameter
    {
        let fieldsCopy = TemplateParameter.Array(fields.mapWithFirstLast {
            $0.template(parentName: name,
                        isFirst: $1, isLast: $2,
                        additionalFields: [:])
        })
        return .Dict([type:
            .Dict([
                "name":      name.template(false, false),
                "protocols": TemplateParameter.Array(
                                protocols.mapWithFirstLast({
                                    TemplateParameter.Dict([
                                        "name":  .Value($0),
                                        "first": .Value($1),
                                        "last":  .Value($2),
                                    ])
                                })),
                "fields":    TemplateParameter.Array(fields.mapWithFirstLast {
                                $0.template(parentName: name,
                                            isFirst: $1, isLast: $2,
                                            additionalFields: ["fields" : fieldsCopy])
                             }),
                "optionalFields":
                    TemplateParameter.Array(fields.filter({
                            $0.type.isOptional
                        })
                        .mapWithFirstLast {
                            $0.template(parentName: name,
                                        isFirst: $1, isLast: $2,
                                        additionalFields: [:])
                        }),
                "nonOptionalFields":
                    TemplateParameter.Array(fields.filter({
                            !$0.type.isOptional
                        })
                        .mapWithFirstLast {
                            $0.template(parentName: name,
                                        isFirst: $1, isLast: $2,
                                        additionalFields: [:])
                        }),
                "hasNonOptionalNonDefaultFields":
                    TemplateParameter.Value(!fields.filter({
                        !$0.type.isOptional && $0.defaultValue == nil
                    }).isEmpty),
                
                "doNotHaveNonOptionalNonDefaultFields":
                    TemplateParameter.Value(fields.filter({
                        !$0.type.isOptional && $0.defaultValue == nil
                    }).isEmpty),
                
                "nonOptionalNonDefaultFields":
                    TemplateParameter.Array(fields.filter({
                            !$0.type.isOptional && $0.defaultValue == nil
                        })
                        .mapWithFirstLast {
                            $0.template(parentName: name,
                                        isFirst: $1, isLast: $2,
                                        additionalFields: [:])
                        }),
                "defaultFields":
                    TemplateParameter.Array(fields.filter({
                            $0.defaultValue != nil
                        })
                        .mapWithFirstLast {
                            $0.template(parentName: name,
                                        isFirst: $1, isLast: $2,
                                        additionalFields: [:])
                        })
                    ])])
    }
}

private extension Array {
    func mapWithFirstLast<T>(transform: (Element, Bool, Bool) -> T) -> Array<T> {
        let lastIndex = self.count - 1
        var result = Array<T>()
        for (i, element) in self.enumerate() {
            result.append(transform(element, i == 0, i == lastIndex))
        }
        return result
    }
}

private extension String {
    var customCapitalizedSting: String {
        guard let firstChar = characters.first else { return "" }
        return String(firstChar).capitalizedString + String(characters.dropFirst())
    }
}
