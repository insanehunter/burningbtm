/*
 * (c) Kotiki, 2015
 */
public struct Lazy<C: Combinator> : Combinator {
    public typealias ValueType = C.ValueType
    
    public let description = "Lazy"
    
    public init(_ combinatorGenerator: () -> C) {
        _combinatorGenerator = combinatorGenerator
    }
    
    public func match(context: ParserContext)
                    throws -> (value: ValueType, context: ParserContext,
                               expectation: Expectation) {
        let combinator = _combinatorGenerator()
        let (val, newCtx, exp) = try combinator.match(context)
        return (value: val, context: newCtx, expectation: exp)
    }
    
    public var untested: Expectation {
        return Expectation(.Untested, "Lazy", children: (nil, nil))
    }
    
    private let _combinatorGenerator: () -> C
}
