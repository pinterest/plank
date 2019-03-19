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
        let parentName = resolveClassName(parentDescriptor)
        let props: [SimpleProperty] = properties.map { param, prop in
            (param, typeFromSchema(param, prop), prop, .readonly)
        }

        return [JSIR.Root.imports(classNames: self.renderReferencedClasses(), myName: self.className, parentName: parentName)] +
            renderAdtTypeRoots() +
            renderEnumRoots() +
            [JSIR.Root.typeDecl(name: self.className, extends: parentName, properties: props)]
    }

    static func enumTypeName(className: String, propertyName: String) -> String {
        return "\(className)\(Languages.flowtype.snakeCaseToCamelCase(propertyName))"
    }

    func renderEnumRoots() -> [JSIR.Root] {
        return properties.flatMap { (param, prop) -> [JSIR.Root] in
            switch prop.schema {
            case let .enumT(enumValues):
                return [JSIR.Root.enumDecl(name: JSModelRenderer.enumTypeName(className: self.className, propertyName: param), values: enumValues)]
            default: return []
            }
        }
    }
}
