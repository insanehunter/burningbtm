/*
 * (c) Kotiki, 2015
 */
public struct RepeatUntil<C1: Combinator, C2: Combinator> : Combinator {
    public typealias ValueType = ([C1.ValueType], C2.ValueType)
    
    public let description = "RepeatUntil"
    
    public init(_ first: C1, _ second: C2, allowZeroMatches: Bool = false) {
        _first = first
        _second = second
        _allowZeroMatches = allowZeroMatches
    }

    public func match(context: ParserContext)
                    throws -> (value: ValueType, context: ParserContext,
                               expectation: Expectation) {
        var context = context
        var result: [C1.ValueType] = []
        do {
            while (true) {
                let (item, newCtx, _) = try _first.match(context)
                result.append(item)
                context = newCtx
            }
        }
        catch let err as FailedExpectation {
            if result.count == 0 && !_allowZeroMatches {
                throw FailedExpectation(description, context,
                        children: (err.failedExpectation, _second.untested))
            }
            do {
                let (item, newCtx, err2) = try _second.match(context)
                return (value: (result, item), context: newCtx,
                        expectation: _expectation(.Fulfilled,
                                                  (err.failedExpectation, err2)))
            }
            catch let err2 as FailedExpectation {
                throw FailedExpectation(description, context,
                        children: (err.failedExpectation, err2.failedExpectation))
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
    
    private let _first: C1
    private let _second: C2
    private let _allowZeroMatches: Bool
}
