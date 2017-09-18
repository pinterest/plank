//
//  JSIR.swift
//  plank
//
//  Created by Michael Schneider
//
//

import Foundation

public struct JSIR {

    static func type(_ name: String, shape: () -> [String], body: () -> [String]) -> String {
        return [
            "export type \(name)Type = $Shape<{|",
            -->shape(),
            "|}> & {",
            -->body(),
            "};\n"
        ].joined(separator: "\n")
    }

    static func cls(_ className: String, _ extends: String?, body: () -> [String]) -> String {
        let superclass = (extends != nil ? " extends \(extends!)" : "")
        return [
            "export default class \(className)\(superclass) {",
            -->body,
            "}"
        ].joined(separator: "\n")
    }

    static func method(_ signature: String, body: () -> [String]) -> JSIR.Method {
        return JSIR.Method(body: body(), signature: signature)
    }

    static func stmt(_ body: String) -> String {
        return "\(body);"
    }

    static func ifStmt(_ condition: String, body: () -> [String]) -> String {
        return [
            "if (\(condition)) {",
            -->body,
            "}"
        ].joined(separator: "\n")
    }

    static func elseIfStmt(_ condition: String, _ body:() -> [String]) -> String {
        return [
            " else if (\(condition)) {",
            -->body,
            "}"
        ].joined(separator: "\n")
    }

    static func elseStmt(_ body: () -> [String]) -> String {
        return [
            " else {",
            -->body,
            "}"
            ].joined(separator: "\n")
    }

    static func ifElseStmt(_ condition: String, body: @escaping () -> [String]) -> (() -> [String]) -> String {
        return { elseBody in [
            ObjCIR.ifStmt(condition, body: body),
            ObjCIR.elseStmt(elseBody)
        ].joined(separator: "\n") }
    }

    static func fileImportStmt(_ stmt: String, _ filename: String) -> String {
        return "import type { \(stmt) } from './\(filename).js';"
    }

    static func moduleImportStmt(_ stmt: String, _ filename: String) -> String {
        return "import type { \(stmt) } from '\(filename)';"
    }

    static func enumStmt(_ enumName: String, body: () -> [String]) -> String {
        return [
            "export type \(enumName) = ",
            -->[body().joined(separator: "\n")],
            ";"//,
            ].joined(separator: "\n")
    }

    static func optionEnumStmt(_ enumName: String, body: () -> [String]) -> String {
        return [
            "export type \(enumName) = ",
            -->[body().joined(separator: ",\n")],
            ";"//,
            ].joined(separator: "\n")
    }

    public struct Method {
        let body: [String]
        let signature: String

        func render() -> [String] {
            return [
                signature + " {",
                -->body,
                "}"
            ]
        }
    }

    // Handles printing out the representation for each type
    enum Root {
        case structDecl(name: String, fields: [String])
        case imports(classNames: Set<String>, myName: String, parentName: String?)
        case macro(String)
        case function(JSIR.Method)
        case typeDecl(
            name: String,
            extends: String?,
            properties: [SimpleProperty]
        )
        case classDecl(
            name: String,
            extends: String?,
            methods: [JSIR.Method],
            properties: [SimpleProperty],
            protocols: [String:[JSIR.Method]]
        )
        case enumDecl(name: String, values: EnumType)

        func renderImplementation() -> [String] {
            switch self {
            case .structDecl(name: _, fields: _):
                // Structs are not supported
                return []
            case .macro(let macro):
                return [macro]
            case .imports(let classNames, let myName, _):
                return [
                    JSRuntimeFile.runtimeImports(),
                    // TODO: JS: We should find a better way to remove a cyclic import as filtering it here
                    (classNames.filter { $0 != "\(myName)Type" } as [String])
                               .sorted()
                               .map { JSIR.fileImportStmt($0, $0) }
                               .joined(separator: "\n")
                ]
            case .typeDecl(name: let className, extends: _, properties: let properties):
                let nullability = { (prop: SchemaObjectProperty) -> String in
                    switch prop.nullability {
                    case .some(.nullable): return "?"
                    case .some(.nonnull), .none: return ""
                    }
                }
                return [
                    // Create flow type for class
                    JSIR.type(className, shape: { () -> [String] in
                        properties.map { (param, typeName, prop, _) in
                            return "+\(param): \(nullability(prop))\(typeName),"
                        }
                    }, body: {() -> [String] in [
                        // TODO: JS: For now we have the id as hard property in every type
                        "id: string"
                    ]})
                ].map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }.filter { $0 != "" }
            case .classDecl(name: _, extends: _, methods: _, properties: _, protocols: _):
                return [] // Currently no class definitino supported
            case .function(let method):
                return method.render()
            case .enumDecl(let name, let values):
                return [JSIR.enumStmt(name) {
                    switch values {
                    case .integer(let options):
                        return options.map { "| \($0.defaultValue) /* \($0.description) */"  }
                    case .string(let options, _):
                        return options.map { "| '\($0.defaultValue)'" }
                    }
                }]
            }
        }
    }
}
