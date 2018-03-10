//
//  JSModelRenderer.swift
//  plank
//
//  Created by Michael Schneider
//
//

import Foundation

public struct JSModelRenderer: JSFileRenderer {
    let rootSchema: SchemaObjectRoot
    let params: GenerationParameters

    init(rootSchema: SchemaObjectRoot, params: GenerationParameters) {
        self.rootSchema = rootSchema
        self.params = params
    }

    func renderRoots() -> [JSIR.Root] {
        let parentName = resolveClassName(self.parentDescriptor)
        let props: [SimpleProperty] = properties.map { param, prop in
            return (param, typeFromSchema(param, prop), prop, .readonly)
        }

        return [JSIR.Root.imports(classNames: self.renderReferencedClasses(), myName: self.className, parentName: parentName)] +
                self.renderAdtTypeRoots() +
                self.renderEnumRoots() +
                [JSIR.Root.typeDecl(name: self.className, extends: parentName, properties: props)]
    }

    static func enumTypeName(className: String, propertyName: String) -> String {
        return "\(className)\(propertyName.snakeCaseToCamelCase())"
    }

    func renderEnumRoots() -> [JSIR.Root] {
        return self.properties.flatMap { (param, prop) -> [JSIR.Root] in
            switch prop.schema {
            case .enumT(let enumValues):
                return [JSIR.Root.enumDecl(name: JSModelRenderer.enumTypeName(className: self.className, propertyName: param), values: enumValues)]
            default: return []
            }
        }
    }
}
