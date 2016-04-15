/*
 * (c) Kotiki, 2015
 */
public protocol Combinator: CustomStringConvertible {
    associatedtype ValueType
    
    func match(context: ParserContext)
            throws -> (value: ValueType, context: ParserContext,
                       expectation: Expectation)
    
    var untested: Expectation { get }
}

// Type-erased combinator.
public struct AnyCombinator<V>: Combinator {
    public typealias ValueType = V
    
    public init<C: Combinator where C.ValueType == V>(_ combinator: C) {
        description = combinator.description
        _untested = { combinator.untested }
        _match = combinator.match
    }
    
    public func match(context: ParserContext)
                    throws -> (value: ValueType, context: ParserContext,
                               expectation: Expectation) {
        return try _match(context)
    }
    
    public var untested: Expectation {
        return _untested()
    }
    
    public let description: String
    
    
    private let _match: (ParserContext) throws -> (value: ValueType,
                                                   context: ParserContext,
                                                   expectation: Expectation)
    private let _untested: () -> Expectation
}
