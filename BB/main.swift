/*
 * (c) Kotiki, 2015
 */
import Foundation

let toolVer = "0.0.1"

let specArgument =
        Argument(type: .Option, fullName: "spec", shortName: "s",
                 description: "Spec file path")
let templateArgument =
        Argument(type: .Option, fullName: "template", shortName: "t",
                 description: "Template file path")
let outputArgument =
        Argument(type: .Option, fullName: "output", shortName: "o",
                 description: "Output file path, defaults to STDOUT")
let usage = "Code generator."
let argue = Argue(usage: usage, arguments: [specArgument, templateArgument, outputArgument])

if let error = argue.parse() {
    print("Error parsing arguments: \(error.localizedDescription)")
    exit(1)
}

if argue.helpArgument.value != nil {
    print(argue.description)
    exit(0)
}

let fileManager = NSFileManager.defaultManager()
guard let specPath = specArgument.value as? String
    where fileManager.fileExistsAtPath(specPath) else {
        print("Spec file doesn't exist or was not specified")
        exit(1)
    }
guard let templatePath = templateArgument.value as? String
    where fileManager.fileExistsAtPath(templatePath) else {
        print("Template file doesn't exist or was not specified")
        exit(1)
    }

let outputPath = outputArgument.value as? String

let specString = try! NSString(contentsOfFile: specPath,
                               encoding: NSUTF8StringEncoding)
let specStream = ParserStream(stream: specString as String)

do {
    let (specNodes, _, _) = try spec.match(specStream.initialContext())
    let templateString = try! NSString(contentsOfFile: templatePath,
                                       encoding: NSUTF8StringEncoding)
    let templateStream = ParserStream(stream: templateString as String)
    do {
        let (items, _, _) = try templateSpec.match(templateStream.initialContext())
        let template = renderTemplate(.Key("template", negate: false, items),
            spec: .Dict(["template":
                    .Dict([
                        "toolVer": .Value(toolVer),
                        "ast": .Array(specNodes.map({ $0.template })),
                    ])
                  ]))
        let output = prettifyRenderedTemplate(template)
        if let outputPath = outputPath,
           let data = (output as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
            fileManager.createFileAtPath(outputPath, contents: data, attributes: nil)
        }
        else {
            print(output)
        }
    }
    catch let e as FailedExpectation {
        print("fatal error: " + e.debugDescription)
        exit(1)
    }
}
catch let e as FailedExpectation {
    print("fatal error: " + e.description)
    exit(1)
}
