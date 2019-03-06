//
//  JavaModelRenderer.swift
//  Core
//
//  Created by Rahul Malik on 1/4/18.
//

import Foundation

public struct JavaModelRenderer: JavaFileRenderer {
    let rootSchema: SchemaObjectRoot
    let params: GenerationParameters

    init(rootSchema: SchemaObjectRoot, params: GenerationParameters) {
        self.rootSchema = rootSchema
        self.params = params
    }

    func renderModelConstructor() -> JavaIR.Method {
        let args = (self.transitiveProperties.map { param, schemaObj in
            self.typeFromSchema(param, schemaObj) + " " + param.snakeCaseToPropertyName()
        } + ["int _bits"]).joined(separator: ",\n")

        return JavaIR.method([.private], self.className + "(" + args + ")") {
            self.transitiveProperties.map { param, _ in
                "this." + param.snakeCaseToPropertyName() + " = " + param.snakeCaseToPropertyName() + ";"
            } + ["this._bits = _bits;"]
        }
    }

    func renderModelHashCode() -> JavaIR.Method {
        let bodyHashCode = self.transitiveProperties.map { param, _ in
            param.snakeCaseToPropertyName()
            }.joined(separator: ",\n")

        return JavaIR.method(annotations: ["Override"], [.public], "int hashCode()") {[
            "return Objects.hash(" + bodyHashCode + ");"
            ]
        }
    }

    func renderModelEquals() -> JavaIR.Method {
        let bodyEquals = self.transitiveProperties.map { param, _ in
            "Objects.equals(this." + param.snakeCaseToPropertyName() + ", that." + param.snakeCaseToPropertyName() + ")"
            }.joined(separator: " &&\n")

        return JavaIR.method(annotations: ["Override"], [.public], "boolean equals(Object o)") {[
            JavaIR.ifBlock(condition: "this == o", body: ["return true;"]),
            JavaIR.ifBlock(condition: "o == null || getClass() != o.getClass()", body: ["return false;"]),
            self.className + " that = (" + self.className + ") o;",
            "return " + bodyEquals + ";"
            ]
        }
    }

    func renderModelProperties(modifiers: JavaModifier = [.private]) -> [JavaIR.Property] {
        let props = self.transitiveProperties.map { param, schemaObj in
            JavaIR.Property(annotations: ["SerializedName(\"\(param)\")"], modifiers: [.private], type: self.typeFromSchema(param, schemaObj), name: param.snakeCaseToPropertyName(), initialValue: "")
        }

        let bits = JavaIR.Property(annotations: [], modifiers: [.private], type: "int", name: "_bits", initialValue: "0")

        var bitmasks: [JavaIR.Property] = []
        var index = 0
        self.transitiveProperties.forEach { param, _ in
            bitmasks.append(JavaIR.Property(annotations: [], modifiers: [.private, .static, .final], type: "int", name: param.uppercased() + "_SET", initialValue: "1 << " + String(index)))
            index += 1
        }

        return props + bitmasks + [bits]
    }

    func renderModelGetters(modifiers: JavaModifier = [.public]) -> [JavaIR.Method] {
        let getters = self.transitiveProperties.map { param, schemaObj in
            JavaIR.method(modifiers, self.typeFromSchema(param, schemaObj) + " get" + param.snakeCaseToCapitalizedPropertyName() + "()") {[
                "return this." + param.snakeCaseToPropertyName() + ";"
                ]}
        }
        return getters
    }

    func renderModelIsSetCheckers(modifiers: JavaModifier = [.public]) -> [JavaIR.Method] {
        let getters = self.transitiveProperties.map { param, _ in
            JavaIR.method(modifiers, "boolean get" + param.snakeCaseToCapitalizedPropertyName() + "IsSet()") {[
                "return (this._bits & " + param.uppercased() + "_SET) == " + param.uppercased() + "_SET;"
            ]}
        }
        return getters
    }

    func renderModelMergeWith() -> JavaIR.Method {
        return JavaIR.method([.public], self.className + " mergeWith(" + self.className + " model)") {[
            self.className + ".Builder builder = this.toBuilder();",
            "builder.mergeWith(model);",
            "return builder.build();"
        ]}
    }

    func renderModelToBuilder() -> JavaIR.Method {
        return JavaIR.method([.public], self.className + ".Builder toBuilder()") {["return new " + self.className + ".Builder(this);"]}
    }

    func renderModelBuilder() -> JavaIR.Method {
        return JavaIR.method([.public, .static], self.className + ".Builder builder()") {[
            "return new \(className).Builder();"
        ]}
    }

    func renderBuilderConstructors() -> [JavaIR.Method] {
        let emptyConstructor = JavaIR.method([.private], "Builder()") {[]}

        let privateConstructor = JavaIR.method([.private], "Builder(@NonNull " + self.className + " model)") {
            self.transitiveProperties.map { param, _ in
                "this." + param.snakeCaseToPropertyName() + " = model." + param.snakeCaseToPropertyName() + ";"
            } + ["this._bits = model._bits;"]
        }

        return [emptyConstructor, privateConstructor]
    }

    func renderBuilderBuild() -> JavaIR.Method {
        let params = (self.transitiveProperties.map { param, _ in
            "this." + param.snakeCaseToPropertyName()
        } + ["this._bits"]).joined(separator: ",\n")
        return JavaIR.method([.public], "\(self.className) build()") {["return new " + self.className + "(", params, ");"]}
    }

    func renderBuilderGetters(modifiers: JavaModifier = [.public]) -> [JavaIR.Method] {
        let getters = self.transitiveProperties.map { param, schemaObj in
            JavaIR.method(modifiers, self.typeFromSchema(param, schemaObj) + " get" + param.snakeCaseToCapitalizedPropertyName() + "()") {[
                "return this." + param.snakeCaseToPropertyName() + ";"
                ]}
        }
        return getters
    }

    func renderBuilderSetters(modifiers: JavaModifier = [.public]) -> [JavaIR.Method] {
        let setters = self.transitiveProperties.map { param, schemaObj in
            JavaIR.method(modifiers, "Builder set\(param.snakeCaseToCamelCase())(\(self.typeFromSchema(param, schemaObj)) value)") {[
                "this." + param.snakeCaseToPropertyName() + " = value;",
                "this._bits |= " + param.uppercased() + "_SET;",
                "return this;"
            ]}
        }
        return setters
    }

    func renderBuilderMerge() -> JavaIR.Method {
        let body = (self.transitiveProperties.map { param, _ in
            JavaIR.ifBlock(condition: "model.get" + param.snakeCaseToCapitalizedPropertyName() + "IsSet()", body: ["this." + param.snakeCaseToPropertyName() + " = model." + param.snakeCaseToPropertyName() + ";"])
        })
        return JavaIR.method([.public], "void mergeWith(" + self.className + " model)") { body }
    }

    func renderBuilderProperties(modifiers: JavaModifier = [.private]) -> [JavaIR.Property] {
        let props = self.transitiveProperties.map { param, schemaObj in
            JavaIR.Property(annotations: ["SerializedName(\"\(param)\")"], modifiers: [.private], type: self.typeFromSchema(param, schemaObj), name: param.snakeCaseToPropertyName(), initialValue: "")
        }

        let bits = JavaIR.Property(annotations: [], modifiers: [.private], type: "int", name: "_bits", initialValue: "0")

        return props + [bits]
    }

    func renderRoots() -> [JavaIR.Root] {
        let packages = params[.packageName].flatMap {
            [JavaIR.Root.packages(names: [$0])]
        } ?? []

        let imports = [
            JavaIR.Root.imports(names: [
                "com.google.gson.Gson",
                "com.google.gson.annotations.SerializedName",
                "com.google.gson.TypeAdapter",
                "java.util.Date",
                "java.util.Map",
                "java.util.Set",
                "java.util.List",
                "java.util.Objects",
                "java.lang.annotation.Retention",
                "java.lang.annotation.RetentionPolicy",
                "android.support.annotation.IntDef",
                "android.support.annotation.NonNull",
                "android.support.annotation.Nullable",
                "android.support.annotation.StringDef",
            ]),
        ]

        let enumProps = properties.flatMap { (param, prop) -> [JavaIR.Enum] in
            switch prop.schema {
            case let .enumT(enumValues):
                return [
                    JavaIR.Enum(
                        name: enumTypeName(propertyName: param, className: self.className),
                        values: enumValues
                    ),
                ]
            default: return []
            }
        }

        let adtRoots = properties.flatMap { (param, prop) -> [JavaIR.Root] in
            switch prop.schema {
            case let .oneOf(types: possibleTypes):
                let objProps = possibleTypes.map { $0.nullableProperty() }
                return adtRootsForSchema(property: param, schemas: objProps)
            case let .array(itemType: .some(itemType)):
                switch itemType {
                case let .oneOf(types: possibleTypes):
                    let objProps = possibleTypes.map { $0.nullableProperty() }
                    return adtRootsForSchema(property: param, schemas: objProps)
                default: return []
                }
            case let .map(valueType: .some(additionalProperties)):
                switch additionalProperties {
                case let .oneOf(types: possibleTypes):
                    let objProps = possibleTypes.map { $0.nullableProperty() }
                    return adtRootsForSchema(property: param, schemas: objProps)
                default: return []
                }
            default: return []
            }
        }

        let builderClass = JavaIR.Class(
            annotations: [],
            modifiers: [.public, .static],
            extends: nil,
            implements: nil,
            name: "Builder",
            methods: self.renderBuilderConstructors() + self.renderBuilderSetters() + self.renderBuilderGetters() + [
                self.renderBuilderBuild(),
                self.renderBuilderMerge()
            ],
            enums: [],
            innerClasses: [],
            properties: self.renderBuilderProperties()
        )

        let modelClass = JavaIR.Root.classDecl(
            aClass: JavaIR.Class(
                annotations: [],
                modifiers: [.public],
                extends: nil,
                implements: nil,
                name: self.className,
                methods: [
                    self.renderModelConstructor(),
                    self.renderModelBuilder(),
                    self.renderModelToBuilder(),
                    self.renderModelMergeWith(),
                    self.renderModelEquals(),
                    self.renderModelHashCode()] +
                    self.renderModelGetters() +
                    self.renderModelIsSetCheckers(),
                enums: enumProps,
                innerClasses: [
                    builderClass,
                ],
                properties: self.renderModelProperties()
            )
        )

        let roots: [JavaIR.Root] =
            packages +
            imports +
            adtRoots +
            [modelClass]

        return roots
    }
}
