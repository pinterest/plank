//
//  SwiftModelRenderer.swift
//  Core
//
//  Created by Levi McCallum on 9/2/17.
//

import Foundation

struct SwiftModelRenderer: SwiftFileRenderer {
    let rootSchema: SchemaObjectRoot
    let params: GenerationParameters

    init(rootSchema: SchemaObjectRoot, params: GenerationParameters) {
        self.rootSchema = rootSchema
        self.params = params
    }

    func renderRoots() -> [SwiftIR.Root] {
        return [
            SwiftIR.Root.importDecl(name: "Foundation"),
            SwiftIR.Root.structDecl(
                access: .publicDecl,
                name: className,
                protocols: ["Codable"],
                properties: properties.map { dict in
                    let (param, prop) = dict
                    return (.publicDecl, .variable, param, swiftType(schema: prop.schema, param: param))
                },
                body: [
                    SwiftIR.Root.enumDecl(
                        access: .publicDecl,
                        name: "CodingKeys",
                        type: "String",
                        protocols: ["CodingKey"],
                        cases: properties.map { dict in
                            let (param, _) = dict
                            return (name: param, value: "\"\(param)\"")
                        }
                    )
                ]
            )
        ]
    }
}
