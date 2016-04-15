/*
 * (c) Kotiki, 2015
 */
public func first<T, U>() -> Transformer<(T, U), T> {
    return Transformer(
        transformValue: { return $0.0 }
    )
}

public func toVoid<T>() -> Transformer<T, Void> {
    return Transformer(
        transformValue: { _ in return }
    )
}

public func toQualifiedName() -> Transformer<(String, String?), QualifiedName> {
    return Transformer(
        transformValue: { (clientName, serverName) in
            guard !clientName.isEmpty else {
                throw ValidationError("identifier is empty")
            }
            guard !(serverName?.isEmpty ?? false) else {
                throw ValidationError("server identifier is empty")
            }
            return QualifiedName(clientName: clientName,
                                 serverName: serverName ?? clientName)
        }
    )
}

public func toType() -> Transformer<(String, String?), Type> {
    return Transformer(
        transformValue: { (name, optionalMark) in
            guard !name.isEmpty else {
                throw ValidationError("type name is empty")
            }
            return Type(name: name, isOptional: (optionalMark != nil))
        }
    )
}

public func toVariable()
    -> Transformer<((QualifiedName, Type), String?), Variable> {
    return Transformer(
        transformValue: { (arg0, defaultValue) in
            let (identifier, type) = arg0
            return Variable(name: identifier, type: type, defaultValue: defaultValue)
        }
    )
}

public func toArray<T>() -> Transformer<([T], T), [T]> {
    return Transformer(
        transformValue: { (allButLast, last) in
            return allButLast + [last]
        }
    )
}

public func toArray<T>() -> Transformer<T, [T]> {
    return Transformer(
        transformValue: { value in
            return [value]
        }
    )
}

public func toStruct() -> Transformer<((QualifiedName, [String]?), [Variable]), ASTNode> {
    return Transformer(
        transformValue: { (arg0, fields) in
            let (name, protocols) = arg0
            return .Struct(name: name, protocols: protocols ?? [], fields: fields)
        }
    )
}

public func toProtocol() -> Transformer<((QualifiedName, [String]?), [Variable]), ASTNode> {
    return Transformer(
        transformValue: { (arg0, fields) in
            let (name, protocols) = arg0
            return .Protocol(name: name, protocols: protocols ?? [], fields: fields)
        }
    )
}

public func toClass() -> Transformer<((QualifiedName, [String]?), [Variable]), ASTNode> {
    return Transformer(
        transformValue: { (arg0, fields) in
            let (name, protocols) = arg0
            return .Class(name: name, protocols: protocols ?? [], fields: fields)
        }
    )
}

public func toFuncArgs() -> Transformer<Void, [Variable]> {
    return Transformer(
        transformValue: { _ in
            return []
        }
    )
}

public func toFuncArgs() -> Transformer<Variable, [Variable]> {
    return toArray()
}

public func toFuncArgs() -> Transformer<([Variable], Variable), [Variable]> {
    return toArray()
}

public func toFunc() -> Transformer<(((String?, QualifiedName), [Variable]), Type?), ASTNode> {
    return Transformer(
        transformValue: { (arg0, type) in
            let (arg1, args) = arg0
            let (castMark, name) = arg1
            
            if castMark != nil {
                return .CastFunc(name: name, arguments: args)
            }
            else {
                return .Func(name: name, arguments: args,
                             returnType: type ?? Type.Void)
            }
        }
    )
}
