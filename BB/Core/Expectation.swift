/*
 * (c) Kotiki, 2015
 */
public class Expectation: CustomDebugStringConvertible {
    public enum Resolution {
        case Fulfilled
        case Untested
        case Failed(ParserContext)
    }
    
    public let resolution: Resolution
    public let description: String
    public let firstChild: Expectation?
    public let secondChild: Expectation?
    
    public init(_ resolution: Resolution, _ combinatorDescription: String,
                children: (Expectation?, Expectation?))
    {
        self.resolution = resolution
        description = combinatorDescription
        firstChild = children.0
        secondChild = children.1
    }
    
    public var debugDescription: String {
        switch resolution {
            case .Fulfilled: return "Fulfilled.\(description)"
            case .Untested: return "Untested.\(description)"
            case .Failed: return "Failed.\(description)"
        }
    }
    
    public func failureStack() -> [Expectation] {
        let stacks = _allFailureStacks()
        return stacks.reduce(stacks.first!,
            combine: { acc, element in
                return element.0 > acc.0 ? element : acc
            }).1
    }
    
    public var context: ParserContext? {
        guard case .Failed(let context) = resolution else { return nil }
        return context
    }
    
    private func _allFailureStacks()
                        -> [(ParserStream.PositionType, [Expectation])]
    {
        _buildParents()
        return _leaves()
            .filter({
                guard case .Failed = $0.resolution else { return false }
                return true
            })
            .map({ leaf -> (ParserStream.PositionType, [Expectation]) in
                let stack = leaf._reversedStack()
                return (leaf.context!.position, stack)
            })
    }
    
    private func _buildParents() {
        self.firstChild?._parent = self
        self.firstChild?._buildParents()
        
        self.secondChild?._parent = self
        self.secondChild?._buildParents()
    }

    private func _leaves() -> [Expectation] {
        if firstChild == nil && secondChild == nil {
            return [self]
        }
        return (firstChild?._leaves() ?? []) + (secondChild?._leaves() ?? [])
    }

    private func _reversedStack() -> [Expectation] {
        return [self] + (_parent.map({ $0._reversedStack() }) ?? [])
    }

    private weak var _parent: Expectation?
}

public struct FailedExpectation: ErrorType, CustomDebugStringConvertible {
    public let failedExpectation: Expectation
    public let context: ParserContext
    
    public init(_ combinatorDescription: String, _ context: ParserContext,
                children: (Expectation?, Expectation?))
    {
        self.failedExpectation =
            Expectation(.Failed(context), combinatorDescription,
                        children: children)
        self.context = context
    }
    
    public var description: String {
        let stack = failedExpectation.failureStack()
        let first = stack.first!
        let context = first.context!
        let (line, col) = context.stream.location(context)
        let restOfLine = context.stream.restOfLine(context)
        return "Error on line \(line), column \(col): " +
                    "expected \(first.description), " +
                    "got \'\(restOfLine)'"
    }
    
    public var debugDescription: String {
        let stacks = failedExpectation._allFailureStacks()
        return stacks
            .map({ (position: ParserStream.PositionType,
                    stack: [Expectation]) -> String in
                return "\(position):\n" + stack.map({ $0.debugDescription })
                                                .joinWithSeparator("\n")
            })
            .joinWithSeparator("\n\n") + "\n\n" + description
    }
}
