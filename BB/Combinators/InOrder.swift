/*
 * (c) Kotiki, 2015
 */
public struct InOrder<C1: Combinator, C2: Combinator> : Combinator {
    public typealias ValueType = (C1.ValueType, C2.ValueType)
    
    public let description = "InOrder"
    
    public init(_ first: C1, _ second: C2) {
        _first = first
        _second = second
    }
    
    public func match(context: ParserContext)
                    throws -> (value: ValueType, context: ParserContext,
                               expectation: Expectation) {
        do {
            let (val1, newCtx, exp1) = try _first.match(context)
            do {
                let (val2, finalCtx, exp2) = try _second.match(newCtx)
                return (value: (val1, val2), context: finalCtx,
                        expectation: _expectation(.Fulfilled, (exp1, exp2)))
            }
            catch let exp2 as FailedExpectation {
                throw FailedExpectation(description, newCtx,
                                        children: (exp1, exp2.failedExpectation))
            }
        }
        catch let first as FailedExpectation {
            throw FailedExpectation(description, context,
                                    children: (first.failedExpectation,
                                               _second.untested))
        }
    }
    
    public var untested: Expectation {
        return _expectation(.Untested, (_first.untested, _second.untested))
    }
    
    private func _expectation(resolution: Expectation.Resolution,
                              _ children: (Expectation?, Expectation?))
                    -> Expectation
    {
        return Expectation(resolution, description, children: children)
    }
    
    private let _first: C1
    private let _second: C2
}
