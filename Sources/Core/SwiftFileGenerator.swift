//
//  SwiftFileGenerator.swift
//  Core
//
//  Created by Levi McCallum on 9/2/17.
//

import Foundation

struct SwiftFileGenerator: FileGeneratorManager {

    static func filesToGenerate(descriptor: SchemaObjectRoot, generatorParameters: GenerationParameters) -> [FileGenerator] {
        let rootsRenderer = SwiftModelRenderer(rootSchema: descriptor, params: generatorParameters)
        return [
            SwiftFile(roots: rootsRenderer.renderRoots(), className: rootsRenderer.className)
        ]
    }

    static func runtimeFiles() -> [FileGenerator] {
        return [SwiftRuntimeFile()]
    }

}

fileprivate extension FileGenerator {
    var swiftDefaultIndent: Int {
        return 4
    }
}
    
struct SwiftFile: FileGenerator {
    let roots: [SwiftIR.Root]
    let className: String

    var fileName: String {
        return "\(className).swift"
    }
    
    var indent: Int {
        return swiftDefaultIndent
    }
    
    func renderFile() -> String {
        return render(lines: [ renderCommentHeader() ] +
            roots.flatMap { $0.render().joined(separator: "\n") }
        )
    }

}

struct SwiftRuntimeFile: FileGenerator {
    var fileName: String {
        return "PlankModelRuntime.swift"
    }
    
    var indent: Int {
        return swiftDefaultIndent
    }
    
    func renderFile() -> String {
        let outputs: [String] = []
        return render(lines: [
            renderCommentHeader(),
            "import Foundation",
            outputs.joined(separator: "\n")
        ])
    }
}
