/*
 * (c) Kotiki, 2015
 */
public struct Transformer<T, U> {
    public let transformValue: T throws -> U
}

public struct ValidationError: ErrorType, CustomStringConvertible {
    public init(_ description: String) {
        self.description = description
    }
    
    public let description: String
}

public struct Transform<C: Combinator, U>: Combinator {
    public typealias ValueType = U
    public typealias TransformerType = Transformer<C.ValueType, U>
    
    public let description = "Transform"
    
    public init(_ combinator: C, transformer: TransformerType)
    {
        self._combinator = combinator
        self._transformer = transformer
    }

    public func match(context: ParserContext)
                    throws -> (value: ValueType, context: ParserContext,
                               expectation: Expectation)
    {
        let (value, context, exp) = try _combinator.match(context)
        do {
            let newValue = try _transformer.transformValue(value)
            return (value: newValue, context: context, expectation: exp)
        }
        catch let error as ValidationError {
            throw FailedExpectation(error.description, context,
                                    children: (exp, nil))
        }
    }
    
    public var untested: Expectation {
        return _combinator.untested
    }
    
    private let _combinator: C
    private let _transformer: TransformerType
}
