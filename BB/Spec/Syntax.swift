/*
 * (c) Kotiki, 2015
 */
public let whitespaces =
    AnyOf(Repeated(Literal(" ")) |> toVoid(),
        AnyOf(Repeated(Literal("\t")) |> toVoid(),
            AnyOf(Literal("\n") |> toVoid(),
                  Literal("\r") |> toVoid())))

public let singleLineCommentStart = Literal("//")
public let singleLineCommentEnd = try! Regexp(".*", name: "comment")
public let singleLineComment =
    InOrder(singleLineCommentStart, singleLineCommentEnd) |> toVoid()

public let multiLineCommentStart = Literal("/*")
public let multiLineCommentEnd =
    try! Regexp(".*?\\*/", options: .DotMatchesLineSeparators,
                name: "multiline comment")
public let multiLineComment =
    InOrder(multiLineCommentStart, multiLineCommentEnd) |> toVoid()

public let skip =
    Aggregate(
        Maybe(Repeated(whitespaces +|+ singleLineComment +|+ multiLineComment)),
        name: "whitespaces")

public func identifier(name: String) -> AnyCombinator<String> {
    return AnyCombinator(try! Regexp("[a-zA-Z_][a-zA-Z0-9_]*", name: name))
}

public let clientName = identifier("client name")

public let serverName =
    Literal("\"") >+ (try! Regexp("[a-zA-Z_][a-zA-Z0-9._]*",
                                  name: "server identifier")) +> Literal("\"")

public let qualifiedName =
    (clientName *>* Maybe(Literal("as") >* serverName)) |> toQualifiedName()


public let numberValue =
    try! Regexp("\\d+(\\.\\d+)?", name: "number")

public let booleanValue =
    AnyOf(Literal("true"), Literal("false"))

public let stringValue =
    try! Regexp("\".*?\"", name: "string")

public let defaultValue =
    Literal("=") >* (numberValue +|+ stringValue +|+ booleanValue)

public let typeName = identifier("type name")

public let typeDefinition =
    (Literal(":") >* typeName *>* Maybe(Literal("?"))) |> toType()


public let protocolName = identifier("protocol name")

public let protocols =
    Literal(":") >* AnyOf(RepeatUntil(skip >+ protocolName *> Literal(","),
                                      skip >+ protocolName) |> toArray(),
                          protocolName |> toArray())

public let variableDefinition =
    (qualifiedName *>* typeDefinition *>* Maybe(defaultValue)) |> toVariable()

public let structField =
    Literal("let") >* variableDefinition

public let structFields =
    Literal("{") >* RepeatUntil(Maybe(skip) >+ structField,
                                Maybe(skip) >+ Literal("}")) |> first()

public let `struct` =
    (Literal("struct") >* qualifiedName *>*
        Maybe(protocols) *>* structFields) |> toStruct()

public let `class` =
    (Literal("class") >* qualifiedName *>*
        Maybe(protocols) *>* structFields) |> toClass()

public let funcArgs =
    Literal("(") >*
        AnyOf(Literal(")") |> toVoid() |> toFuncArgs(),
            AnyOf((variableDefinition *> Literal(")")) |> toFuncArgs(),
                  RepeatUntil(Maybe(skip) >+ variableDefinition *> Literal(","),
                              Maybe(skip) >+ variableDefinition *> Literal(")"))
                        |> toFuncArgs()))

public let funcType =
    (Literal("->") >* typeName *>* Maybe(Literal("?"))) |> toType()

public let `func` =
    (Maybe(Literal("@cast")) *> Literal("func") *>* qualifiedName *>*
        funcArgs *>* Maybe(funcType)) |> toFunc()

public let toplevel = Maybe(skip) >+ (`struct` +|+ `func` +|+ `class`)

public let spec = RepeatUntil(toplevel, Maybe(skip) >+ EndOfStream()) |> first()
