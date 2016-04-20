/*
 * (c) Kotiki, 2015
 */
public struct ParserContext {
    public let stream: ParserStream
    public let position: ParserStream.PositionType
}

public struct EndOfStreamError: ErrorType {
    let context: ParserContext
}

public struct ParserStream {
    public typealias PositionType = String.UTF16Index
    
    public init(stream: String) {
        self.string = stream
        self.stream = stream.utf16
    }
    
    public func initialContext() -> ParserContext {
        return ParserContext(stream: self, position: stream.startIndex)
    }
    
    public func read(characters: Int, context: ParserContext)
                    throws -> (string: String, context: ParserContext)
    {
        assert(characters > 0)
        
        let start = context.position
        guard start <= stream.endIndex else {
            assertionFailure()
            throw EndOfStreamError(context: context)
        }
        
        let end = start.advancedBy(characters, limit: stream.endIndex)
        let slice = stream[start..<end]
        guard slice.count == characters else {
            throw EndOfStreamError(context: context)
        }
        let context = ParserContext(stream: self, position: end)
        return (string: String(slice), context: context)
    }
    
    public func charactersLeft(context: ParserContext) -> Int {
        return context.position.distanceTo(stream.endIndex)
    }
    
    public func location(context: ParserContext) -> (line: Int, column: Int) {
        var line = 1, col = 1
        let characters = string.characters
        for index in stream.startIndex..<context.position {
            col += 1
            guard let index = String.CharacterView.Index(index, within: string)
                else { continue }
            if characters[index] == "\n" {
                line += 1
                col = 1
            }
        }
        return (line: line, column: col)
    }
    
    public func restOfLine(context: ParserContext) -> String {
        let characters = string.characters
        for streamIndex in context.position..<stream.endIndex {
            guard let index = String.CharacterView.Index(streamIndex, within: string)
                else { continue }
            if characters[index] == "\n" {
                return String(stream[context.position..<streamIndex])
            }
        }
        return String(stream[context.position..<stream.endIndex])
    }
    
    private let string: String
    private let stream: String.UTF16View
}
