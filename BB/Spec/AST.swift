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
            "clientName": TemplateParameter.Value(clientName),
            "serverName": TemplateParameter.Value(serverName),
            "first":      TemplateParameter.Value(isFirst),
            "last":       TemplateParameter.Value(isLast)
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

    public func template(isFirst: Bool, _ isLast: Bool) -> TemplateParameter {
        var dict: [String : TemplateParameter] = [
            "name":  name.template(false, false),
            "type":  type.template(false, false),
            "first": TemplateParameter.Value(isFirst),
            "last":  TemplateParameter.Value(isLast)
        ]
        if let defaultValue = defaultValue {
            dict["defaultValue"] = .Value(defaultValue)
        }
        return .Dict(dict)
    }
}

public enum ASTNode: CustomStringConvertible {
    case Struct(name: QualifiedName, protocols: [String], fields: [Variable])
    case Class(name: QualifiedName, protocols: [String], fields: [Variable])
    
    case Func(name: QualifiedName, arguments: [Variable], returnType: Type)
    case CastFunc(name: QualifiedName, arguments: [Variable])
    
    
    public var description: String {
        switch self {
            case let .Struct(name, protocols, fields):
                let protoStr = protocols.joinWithSeparator(", ")
                let proto = protoStr.isEmpty ? "" : ": \(protoStr)"
                return "struct \(name)\(proto) {\n  " +
                            fields.map({ $0.description }).joinWithSeparator(",\n  ") +
                       "\n}"
            
            case let .Class(name, protocols, fields):
                let protoStr = protocols.joinWithSeparator(", ")
                let proto = protoStr.isEmpty ? "" : ": \(protoStr)"
                return "class \(name)\(proto) {\n  " +
                            fields.map({ $0.description }).joinWithSeparator(",\n  ") +
                       "\n}"
            
            case let .Func(name, args, returnType):
                return "func \(name)(" +
                            args.map({ $0.description }).joinWithSeparator(", ") +
                       ") -> " + returnType.description
            
            case let .CastFunc(name, args):
                return "@cast func \(name)(" +
                            args.map({ $0.description }).joinWithSeparator(", ") +
                       ")"
        }
    }
    
    public var template: TemplateParameter {
        switch self {
            case let .Struct(name, protocols, fields):
                return structTemplate(name, protocols: protocols, fields: fields)
            
            case let .Class(name, protocols, fields):
                return structTemplate(name, protocols: protocols, fields: fields)
            
            case let .Func(name, args, returnType):
                return .Dict(["func":
                    .Dict([
                        "name":       name.template(false, false),
                        "args":       TemplateParameter.Array(args.mapWithFirstLast {
                                          $0.template($1, $2)
                                      }),
                        "returnType": returnType.template(false, false)
                    ])])
            
            case let .CastFunc(name, args):
                return .Dict(["castFunc":
                    .Dict([
                        "name": name.template(false, false),
                        "args": TemplateParameter.Array(args.mapWithFirstLast {
                                    $0.template($1, $2)
                                })
                    ])])
        }
    }
    
    public func structTemplate(name: QualifiedName, protocols: [String],
                               fields: [Variable]) -> TemplateParameter
    {
        return .Dict(["struct":
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
                                $0.template($1, $2)
                             }),
                "optionalFields":
                    TemplateParameter.Array(fields.filter({
                            $0.type.isOptional
                        })
                        .mapWithFirstLast {
                            $0.template($1, $2)
                        }),
                "nonOptionalFields":
                    TemplateParameter.Array(fields.filter({
                            !$0.type.isOptional
                        })
                        .mapWithFirstLast {
                            $0.template($1, $2)
                        }),
                "nonOptionalNonDefaultFields":
                    TemplateParameter.Array(fields.filter({
                            !$0.type.isOptional && $0.defaultValue == nil
                        })
                        .mapWithFirstLast {
                            $0.template($1, $2)
                        }),
                "defaultFields":
                    TemplateParameter.Array(fields.filter({
                            $0.defaultValue != nil
                        })
                        .mapWithFirstLast {
                            $0.template($1, $2)
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
