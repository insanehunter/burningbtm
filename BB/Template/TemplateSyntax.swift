/*
 * (c) Kotiki, 2015
 */
public indirect enum TemplateASTNode: CustomStringConvertible {
    case RawText(String)
    case Key(String, negate: Bool, [TemplateASTNode])
    
    public var description: String {
        return self.description("")
    }
    
    public func description(offset: String) -> String {
        switch self {
            case let .RawText(text):
                let prettyText = text.characters.split("\n").map(String.init)
                        .map({ offset + "    " + $0 }).joinWithSeparator("\n")
                return offset + "RawText(\n\(prettyText))\n"
            
            case let .Key(name, negate, nodes):
                let id = negate ? "!Key" : "Key"
                return offset + "\(id)(\(name))\n" +
                    nodes.map({ $0.description(offset + "    ") })
                         .joinWithSeparator("\n")
        }
    }
}

public func toRawText() -> Transformer<String, TemplateASTNode> {
    return Transformer(
        transformValue: { return .RawText($0) }
    )
}

public func toKeyNode() -> Transformer<((String?, String), [TemplateASTNode]),
                                        TemplateASTNode> {
    return Transformer(
        transformValue: { (args, nodes) in
            let (not, name) = args
            return .Key(name, negate: not != nil, nodes)
        }
    )
}

public func unescape() -> Transformer<String, String> {
    return Transformer(
        transformValue: { String($0.characters.dropFirst()) }
    )
}

public let rawText =
    try! Regexp("[^\\\\\\[\\]]+", options: .DotMatchesLineSeparators,
                name: "text") |> toRawText()

public let escapedBrackets =
    AnyOf(Literal("\\["), Literal("\\]")) |> unescape() |> toRawText()

public func tag() -> AnyCombinator<TemplateASTNode> {
    return AnyCombinator(
            (Literal("[") >+ Maybe(Literal("!")) +>+ identifier("tag") +>+
                (Maybe(Literal(" ")) >+ RepeatUntil(textOrTag, Literal("]"),
                            allowZeroMatches: true)) |> first()) |> toKeyNode()
    )
}

public let textOrTag = AnyOf(Lazy({ tag() }), AnyOf(rawText, escapedBrackets))

public let templateSpec = RepeatUntil(textOrTag, EndOfStream()) |> first()
