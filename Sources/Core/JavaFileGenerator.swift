//
//  JavaFileGenerator
//  plank
//
//  Created by Rahul Malik on 1/4/18.
//

import Foundation

struct JavaGeneratorManager: FileGeneratorManager {

    static func filesToGenerate(descriptor: SchemaObjectRoot, generatorParameters: GenerationParameters) -> [FileGenerator] {
        let modelRenderer = JavaModelRenderer(rootSchema: descriptor, params: generatorParameters)
        return [

            JavaFileGenerator(roots: modelRenderer.renderRoots(), className: descriptor.className(with: generatorParameters))
        ]
    }

    static func runtimeFiles() -> [FileGenerator] {
        return []
    }
}

struct JavaFileGenerator: FileGenerator {
    let roots: [JavaIR.Root]
    let className: String

    var fileName: String {
        return "\(className).java"
    }

    func renderFile() -> String {
        return (
            [self.renderCommentHeader()] +
                self.roots.map { $0.renderImplementation().joined(separator: "\n") }
            )
            .map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
            .map { $0.replacingOccurrences(of: "  ", with: " ") }
            .filter { $0 != "" }
            .joined(separator: "\n\n")
    }

    var indent: Int {
        return 4
    }
}
