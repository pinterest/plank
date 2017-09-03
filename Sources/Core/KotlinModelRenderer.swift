//
//  KotlinModelRenderer.swift
//  Core
//
//  Created by Levi McCallum on 9/3/17.
//

import Foundation

struct KotlinModelRenderer: KotlinFileRenderer {
    let rootSchema: SchemaObjectRoot
    let params: GenerationParameters
    
    init(rootSchema: SchemaObjectRoot, params: GenerationParameters) {
        self.rootSchema = rootSchema
        self.params = params
    }
    
    func renderRoots() -> [KotlinIR.Root] {
        return [
        ]
    }
}
