//
//  JavaADTRenderer.swift
//  Core
//
//  Created by Rahul Malik on 1/19/18.
//

import Foundation

extension JavaModelRenderer {
    /*
     interface FooADTVisitor<R> {
     R match(Pin);
     R match(Board);
     }
     public abstract class FooADT<R> {
     [properties here]
     private FooADT() {}
     public abstract R match Foo(FooADTVisitor<R>);

     }
     */
    func adtRootsForSchema(property: String, schemas: [SchemaObjectProperty]) -> [JavaIR.Root] {
        // Do we need to create a custom runtime type adapter factory?
        let adtName = "\(rootSchema.name)_\(property)"
        let formattedADTName = adtName.snakeCaseToCamelCase()
        let privateInit = JavaIR.method([.private], "\(formattedADTName)()") { [] }

        func interfaceMethods() -> [JavaIR.Method] {
            return schemas.enumerated()
                .map { (typeFromSchema("", $0.element), $0.offset) }
                .map { JavaIR.method([], "R match(\($0.0) value\($0.1))") { [] } }
        }

        let matcherInterface = JavaIR.Interface(modifiers: [],
                                                extends: nil,
                                                name: "\(formattedADTName)Matcher<R>",
                                                methods: interfaceMethods())

        let matcherMethod = JavaIR.method([.public], "R match\(formattedADTName)(\(formattedADTName)Matcher<R> matcher)") { [
            "// TODO: Implement this!",
            "return null;",
        ] }

        let internalProperties = schemas.enumerated()
            .map { (typeFromSchema("", $0.element), $0.offset) }
            .map { JavaIR.Property(annotations: [], modifiers: [.private], type: $0.0, name: "value\($0.1)", initialValue: "") }

        let enumOptions = schemas.enumerated()
            .map { (typeFromSchema("", $0.element.schema.unknownNullabilityProperty())
                    .split(separator: " ")
                    .filter { !String($0).hasPrefix("@") }
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .map { $0.replacingOccurrences(of: "<", with: "") }
                    .map { $0.replacingOccurrences(of: ">", with: "") }
                    .map { $0.replacingOccurrences(of: ",", with: "") }
                    .filter { $0 != "" }
                    .joined(separator: "_"), $0.offset) }
            .map { EnumValue<Int>(defaultValue: $0.1, description: $0.0) }

        let internalStorageEnum = JavaIR.Enum(name: "InternalStorage", values: .integer(enumOptions))

        let internalStorageProp = JavaIR.Property(annotations: [], modifiers: [.private, .static], type: "@InternalStorage int", name: "internalStorage", initialValue: "")
        let cls = JavaIR.Class(annotations: [],
                               modifiers: [.public, .static, .final],
                               extends: nil,
                               implements: nil,
                               name: "\(formattedADTName)<R>",
                               methods: [
                                   privateInit,
                                   matcherMethod,
                               ],
                               enums: [internalStorageEnum],
                               innerClasses: [],
                               properties: [internalProperties, [internalStorageProp]])
        return [
            // Interface
            JavaIR.Root.interfaceDecl(aInterface: matcherInterface),
            // Class
            JavaIR.Root.classDecl(aClass: cls),
            // - Properties
            // - Private Constructor
            // - Match method
        ]
    }
}
