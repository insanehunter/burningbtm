/*
 * (c) Kotiki, 2015
 */
import Foundation

public indirect enum TemplateParameter {
    case Dict(Dictionary<String, TemplateParameter>)
    case Array([TemplateParameter])
    case Value(TemplatePrimitiveType)
}

public protocol TemplatePrimitiveType {
    var templateDescription: String { get }
}

extension Bool: TemplatePrimitiveType {
    public var templateDescription: String {
        return self ? "true" : "false"
    }
}

extension String: TemplatePrimitiveType {
    public var templateDescription: String {
        return self
    }
}

public func renderTemplate(template: TemplateASTNode,
                           spec: TemplateParameter) -> String
{
    switch template {
        case let .RawText(text):
            return text
        
        case let .Key(name, negate: negate, nodes):
            let topLevelSpec = spec
            switch spec {
                case let .Value(val):
                    return val.templateDescription
                
                case let .Dict(dict):
                    if let spec = dict[name] {
                        switch spec {
                            case .Value(let val) where nodes.isEmpty:
                                return val.templateDescription
                            
                            case .Value(let val) where !nodes.isEmpty:
                                if let val = val as? Bool where (negate && !val) ||
                                                                (!negate && val) {
                                    return nodes.map({ renderTemplate($0, spec: topLevelSpec) })
                                        .joinWithSeparator("")
                                }
                                if !(val is Bool) {
                                    if negate { return "" }
                                    return nodes.map({ renderTemplate($0, spec: spec) })
                                        .joinWithSeparator("")
                                }
                                return ""
                            
                            case .Dict where !nodes.isEmpty:
                                return nodes.map({ renderTemplate($0, spec: spec) })
                                            .joinWithSeparator("")
                            
                            case .Array(let arr) where !nodes.isEmpty:
                                return arr.map({ spec in
                                    nodes.map({ renderTemplate($0, spec: spec) })
                                         .joinWithSeparator("")
                                }).joinWithSeparator("")
                            
                            default:
                                return ""
                        }
                    }
                    if negate {
                        return nodes.map({ renderTemplate($0, spec: spec) })
                                    .joinWithSeparator("")
                    }
                    return ""
                
                case let .Array(array):
                    return array.map({ spec in renderTemplate(template, spec: spec) })
                                .joinWithSeparator("")
            }
        
    }
}

public func prettifyRenderedTemplate(template: String) -> String {
    let s = (template as NSString).mutableCopy() as! NSMutableString
    
    let re1 = try! NSRegularExpression(pattern: "\n{2,}",
                                       options: .DotMatchesLineSeparators)
    
    re1.replaceMatchesInString(s, options: NSMatchingOptions(rawValue: 0),
                               range: NSMakeRange(0, s.length),
                               withTemplate: "\n\n")
    
    let re2 = try! NSRegularExpression(pattern: "\\{(\\s*\n){2,}",
                                       options: .DotMatchesLineSeparators)
    re2.replaceMatchesInString(s, options: NSMatchingOptions(rawValue: 0),
                               range: NSMakeRange(0, s.length),
                               withTemplate: "{\n")
    
    let re3 = try! NSRegularExpression(pattern: "\n(\\s+\n)+",
                                       options: .DotMatchesLineSeparators)
    re3.replaceMatchesInString(s, options: NSMatchingOptions(rawValue: 0),
                               range: NSMakeRange(0, s.length),
                               withTemplate: "\n")
    return s as String
}
