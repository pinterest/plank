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

        func resolveClassName(_ schema: Schema?) -> String? {
            switch schema {
            case .some(.object(let root)):
                return root.className(with: self.params)
            case .some(.reference(with: let ref)):
                return resolveClassName(ref.force())
            default:
                return nil
            }
        }

        let parentName = resolveClassName(self.parentDescriptor)
        let props: [SimpleProperty] = properties.map { param, prop in
            return (param, flowTypeName(param, prop.schema), prop, .readonly)
        }

        return [JSIR.Root.imports(classNames: self.renderReferencedClasses(), myName: self.className, parentName: parentName)] +
                self.renderAdtTypeRoots() +
                self.renderEnumRoots() +
                [JSIR.Root.typeDecl(name: self.className, extends: parentName, properties: props)]
    }

    static func enumTypeName(className: String, propertyName: String) -> String {
        return "\(className)\(propertyName.snakeCaseToCamelCase())Type"
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
