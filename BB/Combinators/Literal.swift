/*
 * (c) Kotiki, 2015
 */
public struct Literal<T>: Combinator {
    public typealias ValueType = T
    
    public let description: String
    
    public init(_ literal: T) {
        _literalValue = literal
        _literalString = "\(literal)"
        description = "'\(literal)'"
    }
    
    public func match(context: ParserContext)
                    throws -> (value: ValueType, context: ParserContext,
                               expectation: Expectation) {
        let length = _literalString.characters.count
        do {
            let (str, ctx) = try context.stream.read(length, context: context)
            if str == _literalString {
                return (value: _literalValue, context: ctx,
                        expectation: _expectation(.Fulfilled))
            }
        } catch {}
        throw FailedExpectation(description, context, children: (nil, nil))
    }
    
    public var untested: Expectation {
        return _expectation(.Untested)
    }
    
    private func _expectation(resolution: Expectation.Resolution) -> Expectation {
        return Expectation(resolution, description, children: (nil, nil))
    }
    
    private let _literalValue: ValueType
    private let _literalString: String
}
