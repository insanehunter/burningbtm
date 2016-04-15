/*
 * (c) Kotiki, 2015
 */
public struct Repeated<C: Combinator> : Combinator {
    public typealias ValueType = [C.ValueType]
    
    public let description = "Repeated"
  
    public init(_ combinator: C) {
        _combinator = combinator
    }

    public func match(context: ParserContext)
                    throws -> (value: ValueType, context: ParserContext,
                               expectation: Expectation) {
        var context = context
        var result = ValueType()
        do {
            while (true) {
                let (item, newCtx, _) = try _combinator.match(context)
                result.append(item)
                context = newCtx
            }
        }
        catch let err as FailedExpectation {
            if result.count == 0 {
                throw FailedExpectation(description, context,
                            children: (err.failedExpectation, nil))
            }
            let exp = err.failedExpectation
            let expectation = Expectation(.Fulfilled, exp.description,
                                          children: (exp.firstChild, exp.secondChild))
            return (value: result, context: context,
                    expectation: _expectation(.Fulfilled, expectation))
        }
    }
    
    public var untested: Expectation {
        return _expectation(.Untested, _combinator.untested)
    }
    
    private func _expectation(resolution: Expectation.Resolution,
                              _ child: Expectation) -> Expectation
    {
        return Expectation(resolution, description, children: (child, nil))
    }
    
    private let _combinator: C
}
