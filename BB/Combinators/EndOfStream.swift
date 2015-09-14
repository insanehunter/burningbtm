/*
 * (c) Kotiki, 2015
 */
public struct EndOfStream : Combinator {
    public typealias ValueType = Void
    
    public let description = "end of stream"
    
    public init() {}
    
    public func match(context: ParserContext)
                    throws -> (value: ValueType, context: ParserContext,
                               expectation: Expectation) {
        do {
            try context.stream.read(1, context: context)
        }
        catch {
            return (value: (), context: context,
                    expectation: _expectation(.Fulfilled))
        }
        throw FailedExpectation(description, context, children: (nil, nil))
    }
    
    public var untested: Expectation {
        return _expectation(.Untested)
    }
    
    private func _expectation(resolution: Expectation.Resolution) -> Expectation {
        return Expectation(resolution, description, children: (nil, nil))
    }
}
