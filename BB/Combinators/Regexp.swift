/*
 * (c) Kotiki, 2015
 */
import Foundation

public struct Regexp: Combinator {
    public typealias ValueType = String
    
    public let description: String
    
    public init(_ pattern: String,
                options: NSRegularExpressionOptions =
                                NSRegularExpressionOptions(rawValue: 0),
                name: String) throws
    {
        _regexp = try NSRegularExpression(pattern: pattern, options: options)
        description = name
    }
    
    public func match(context: ParserContext)
                    throws -> (value: ValueType, context: ParserContext,
                               expectation: Expectation)
    {
        let length = context.stream.charactersLeft(context)
        guard length > 0 else {
            throw FailedExpectation(description, context, children: (nil, nil))
        }
        do {
            let (string, _) = try context.stream.read(length, context: context)
            if let result = _regexp.firstMatchInString(string, options: .Anchored,
                                                       range: NSMakeRange(0, length))
                    where result.range.location != NSNotFound &&
                          result.range.length > 0 {
                let (string, context) = try context.stream.read(result.range.length,
                                                                context: context)
                return (value: string, context: context,
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
    
    private let _regexp: NSRegularExpression
}
