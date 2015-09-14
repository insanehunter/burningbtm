/*
 * (c) Kotiki, 2015
 */
public struct Maybe<C: Combinator> : Combinator {
    public typealias ValueType = C.ValueType?
    
    public let description = "Maybe"
    
    public init(_ combinator: C) {
        _combinator = combinator
    }
    
    public func match(context: ParserContext)
                    throws -> (value: ValueType, context: ParserContext,
                               expectation: Expectation) {
        do {
            let (val, newCtx, exp) = try _combinator.match(context)
            return (value: val, context: newCtx,
                    expectation: _expectation(.Fulfilled, exp))
        }
        catch let err as FailedExpectation {
            return (value: nil, context: context,
                    expectation: _expectation(.Fulfilled, err.failedExpectation))
        }
    }
    
    public var untested: Expectation {
        return _expectation(.Untested, _combinator.untested)
    }
    
    private func _expectation(resolution: Expectation.Resolution,
                              _ child: Expectation?) -> Expectation
    {
        return Expectation(resolution, description, children: (child, nil))
    }
    
    private let _combinator: C
}
