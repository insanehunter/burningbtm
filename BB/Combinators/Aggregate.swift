/*
 * (c) Kotiki, 2015
 */
public struct Aggregate<C: Combinator> : Combinator {
    public typealias ValueType = C.ValueType
    
    public let description: String
  
    public init(_ combinator: C, name: String) {
        _combinator = combinator
        description = name
    }

    public func match(context: ParserContext)
                    throws -> (value: ValueType, context: ParserContext,
                               expectation: Expectation) {
        do {
            let (val, newCtx, _) = try _combinator.match(context)
            return (value: val, context: newCtx,
                    expectation: _expectation(.Fulfilled))
        }
        catch let err as FailedExpectation {
            throw FailedExpectation(description, err.context,
                                    children: (nil, nil))
        }
    }
    
    public var untested: Expectation {
        return _expectation(.Untested)
    }
    
    private func _expectation(resolution: Expectation.Resolution) -> Expectation {
        return Expectation(resolution, description, children: (nil, nil))
    }
    
    private let _combinator: C
}
