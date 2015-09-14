/*
 * (c) Kotiki, 2015
 */
infix operator +|+ {associativity left precedence 140}
public func +|+ <C1: Combinator, C2: Combinator
                        where C1.ValueType == C2.ValueType>
                (first: C1, second: C2) -> AnyOf<C1, C2> {
    return AnyOf(first, second)
}

infix operator +>+ {associativity left precedence 140}
public func +>+ <C1: Combinator, C2: Combinator>(first: C1, second: C2)
                        -> InOrder<C1, C2> {
    return InOrder(first, second)
}

infix operator +> {associativity left precedence 140}
public func +> <C1: Combinator, C2: Combinator>(first: C1, second: C2)
        -> Transform<InOrder<C1, C2>, C1.ValueType> {
    let transformer = Transformer<(C1.ValueType, C2.ValueType), C1.ValueType>(
        transformValue: {
            return $0.0
        }
    )
    return Transform(InOrder(first, second), transformer: transformer)
}

infix operator >+ {associativity left precedence 140}
public func >+ <C1: Combinator, C2: Combinator>(first: C1, second: C2)
        -> Transform<InOrder<C1, C2>, C2.ValueType> {
    let transformer = Transformer<(C1.ValueType, C2.ValueType), C2.ValueType>(
        transformValue: {
            return $0.1
        }
    )
    return Transform(InOrder(first, second), transformer: transformer)
}

infix operator *>* {associativity left precedence 140}
public func *>* <C1: Combinator, C2: Combinator>(first: C1, second: C2)
        -> AnyCombinator<(C1.ValueType, C2.ValueType)> {
    return AnyCombinator(first +> skip +>+ second)
}

infix operator *> {associativity left precedence 140}
public func *> <C1: Combinator, C2: Combinator>(first: C1, second: C2)
        -> AnyCombinator<C1.ValueType> {
    return AnyCombinator((first +> skip) +> second)
}

infix operator >* {associativity left precedence 140}
public func >* <C1: Combinator, C2: Combinator>(first: C1, second: C2)
        -> AnyCombinator<C2.ValueType> {
    return AnyCombinator(first >+ (skip >+ second))
}

infix operator |> {associativity left precedence 170}
public func |> <C: Combinator, U>(combinator: C,
                                  transformer: Transformer<C.ValueType, U>)
                        -> Transform<C, U> {
    return Transform(combinator, transformer: transformer)
}
