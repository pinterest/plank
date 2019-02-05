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

    func renderConstructor() -> JavaIR.Method {
        let args = self.transitiveProperties.map { param, schemaObj in
            self.typeFromSchema(param, schemaObj) + " " + param.snakeCaseToPropertyName()
        }.joined(separator: ",\n")
        
        return JavaIR.method([.private], self.className + "(" + args + ")") {
            self.transitiveProperties.map { param, schemaObj in
                "this." + param.snakeCaseToPropertyName() + " = " + param.snakeCaseToPropertyName() + ";"
            }
        }
    }
    
    func renderEquals() -> JavaIR.Method {
        let bodyHashCode = self.transitiveProperties.map { param, schemaObj in
            param.snakeCaseToPropertyName()
            }.joined(separator: ",\n")
        
        return JavaIR.method(annotations: ["Override"], [.public], "int hashCode()") {[
            "return Objects.hash(" + bodyHashCode + ");"
            ]
        }
    }
    
    func renderHashCode() -> JavaIR.Method {
        let bodyEquals = self.transitiveProperties.map { param, schemaObj in
            "Objects.equals(this." + param.snakeCaseToPropertyName() + ", that." + param.snakeCaseToPropertyName() + ")"
            }.joined(separator: " &&\n")
        
        return JavaIR.method(annotations: ["Override"], [.public], "boolean equals(Object o)") {[
            "if (this == o) return true;",
            "if (o == null || getClass() != o.getClass()) return false;",
            self.className + " that = (" + self.className + ") o;",
            "return " + bodyEquals + ";"
            ]
        }
    }
    
    func renderBuilder() -> JavaIR.Method {
        return JavaIR.method([.public, .static], "Builder builder()") {[
            "return new \(className).Builder();"
        ]}
    }
    
    func renderBuilderConstructors() -> [JavaIR.Method] {
        let emptyConstructor = JavaIR.method([.private], "Builder()") {[]}
        
        let privateConstructor = JavaIR.method([.private], "Builder(@NonNull " + self.className + " model)") {
            self.transitiveProperties.map { param, schemaObj in
                "this." + param.snakeCaseToPropertyName() + " = model." + param.snakeCaseToPropertyName()
            }
        }
        
        return [emptyConstructor, privateConstructor]
    }
    
    func renderBuilderBuild() -> JavaIR.Method {
        let params = self.transitiveProperties.map { param, schemaObj in
            "this." + param.snakeCaseToPropertyName()
        }.joined(separator: ",\n")
        return JavaIR.method([.public], "\(self.className) build()") {["return new " + self.className + "(", params,  ")"]}
    }

    func renderToBuilder() -> JavaIR.Method {
        return JavaIR.method([.public], "Builder toBuilder()") {["return new Builder(this);"]}
    }

    func renderBuilderSetters(modifiers: JavaModifier = [.public]) -> [JavaIR.Method] {
        let setters = self.transitiveProperties.map { param, schemaObj in
            JavaIR.method(modifiers, "Builder set\(param.snakeCaseToCamelCase())(\(self.typeFromSchema(param, schemaObj)) value)") {["this." + param.snakeCaseToPropertyName() + " = value;", "return this;"]}
        }
        return setters
    }

    func renderBuilderProperties(modifiers: JavaModifier = [.private]) -> [JavaIR.Property] {
        let props = self.transitiveProperties.map { param, schemaObj in
            JavaIR.Property(annotations: [], modifiers: [.private], type: self.typeFromSchema(param, schemaObj), name: param.snakeCaseToPropertyName())
        }
        return props
    }
    
    func renderModelProperties(modifiers: JavaModifier = [.private]) -> [JavaIR.Property] {
        let props = self.transitiveProperties.map { param, schemaObj in
            JavaIR.Property(annotations: ["SerializedName(\"\(param)\")"], modifiers: [.private], type: self.typeFromSchema(param, schemaObj), name: param.snakeCaseToPropertyName())
        }
        return props
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
            methods: self.renderBuilderConstructors() + self.renderBuilderSetters() + [
                self.renderBuilderBuild()
            ],
            enums: [],
            innerClasses: [],
            properties: self.renderBuilderProperties()
        )

        let modelClass = JavaIR.Root.classDecl(
            aClass: JavaIR.Class(
                annotations: ["AutoTypeAdapter"],
                modifiers: [.public],
                extends: nil,
                implements: nil,
                name: self.className,
                methods: [
                    self.renderConstructor(),
                    self.renderBuilder(),
                    self.renderToBuilder(),
                    self.renderEquals(),
                    self.renderHashCode(),
                ],
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
