/*
 * (c) Kotiki, 2015
 */
public struct AnyOf<T1: Combinator, T2: Combinator
                    where T1.ValueType == T2.ValueType>: Combinator {
    public typealias ValueType = T1.ValueType
    
    public let description = "AnyOf"
    
    public init(_ first: T1, _ second: T2) {
        _first = first
        _second = second
    }
    
    public func match(context: ParserContext)
                    throws -> (value: ValueType, context: ParserContext,
                               expectation: Expectation)
    {
        do {
            let (value, newCtx, exp) = try _first.match(context)
            return (value, newCtx, _expectation(.Fulfilled,
                                                (exp, _second.untested)))
        }
        catch let first as FailedExpectation {
            do {
                let (value, newCtx, exp) = try _second.match(context)
                return (value, newCtx, _expectation(.Fulfilled,
                                                    (first.failedExpectation, exp)))
            }
            catch let second as FailedExpectation {
                throw FailedExpectation(description, context,
                                        children: (first.failedExpectation,
                                                   second.failedExpectation))
            }
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
    
    private let _first: T1
    private let _second: T2
}
