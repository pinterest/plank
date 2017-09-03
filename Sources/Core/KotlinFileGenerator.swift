//
//  KotlinFileGenerator.swift
//  Core
//
//  Created by Levi McCallum on 9/3/17.
//

import Foundation

struct KotlinFileGenerator: FileGeneratorManager {
    
    static func filesToGenerate(descriptor: SchemaObjectRoot, generatorParameters: GenerationParameters) -> [FileGenerator] {
        let rootsRenderer = KotlinModelRenderer(rootSchema: descriptor, params: generatorParameters)
        return [
            KotlinFile(roots: rootsRenderer.renderRoots(), className: rootsRenderer.className)
        ]
    }
    
    static func runtimeFiles() -> [FileGenerator] {
        return [KotlinRuntimeFile()]
    }
    
}

fileprivate extension FileGenerator {
    var kotlinDefaultIndent: Int {
        return 4
    }
}

struct KotlinFile: FileGenerator {
    let roots: [KotlinIR.Root]
    let className: String
    
    var fileName: String {
        return "\(className).kt"
    }
    
    var indent: Int {
        return kotlinDefaultIndent
    }
    
    func renderFile() -> String {
        return render(lines: [ renderCommentHeader() ] +
            roots.flatMap { $0.render().joined(separator: "\n") }
        )
    }
}

struct KotlinRuntimeFile: FileGenerator {
    var fileName: String {
        return "PlankRuntime.kt"
    }
    
    var indent: Int {
        return kotlinDefaultIndent
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
