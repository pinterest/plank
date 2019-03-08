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

    // MARK: - Top-level Model

    func renderModelConstructor() -> JavaIR.Method {
        let args = -->(transitiveProperties.map { param, schemaObj in
            self.typeFromSchema(param, schemaObj) + " " + param.snakeCaseToPropertyName() + ","
        } + ["int _bits"])

        return JavaIR.method([.private], className + "(\n" + args + "\n)") {
            self.transitiveProperties.map { param, _ in
                "this." + param.snakeCaseToPropertyName() + " = " + param.snakeCaseToPropertyName() + ";"
            } + ["this._bits = _bits;"]
        }
    }

    func renderModelHashCode() -> JavaIR.Method {
        let bodyHashCode = transitiveProperties.map { param, _ in
            param.snakeCaseToPropertyName()
        }.joined(separator: ",\n")

        return JavaIR.method(annotations: ["Override"], [.public], "int hashCode()") { [
            "return Objects.hash(" + bodyHashCode + ");",
        ]
        }
    }

    func renderModelEquals() -> JavaIR.Method {
        let bodyEquals = transitiveProperties.map { param, _ in
            "Objects.equals(this." + param.snakeCaseToPropertyName() + ", that." + param.snakeCaseToPropertyName() + ")"
        }.joined(separator: " &&\n")

        return JavaIR.method(annotations: ["Override"], [.public], "boolean equals(Object o)") { [
            JavaIR.ifBlock(condition: "this == o") { [
                "return true;",
            ] },
            JavaIR.ifBlock(condition: "o == null || getClass() != o.getClass()") { [
                "return false;",
            ] },
            self.className + " that = (" + self.className + ") o;",
            "return " + bodyEquals + ";",
        ]
        }
    }

    func renderModelProperties(modifiers _: JavaModifier = [.private]) -> [[JavaIR.Property]] {
        let props = transitiveProperties.map { param, schemaObj in
            JavaIR.Property(annotations: ["SerializedName(\"\(param)\")"], modifiers: [.private], type: self.typeFromSchema(param, schemaObj), name: param.snakeCaseToPropertyName(), initialValue: "")
        }

        let bits = JavaIR.Property(annotations: [], modifiers: [.private], type: "int", name: "_bits", initialValue: "0")

        var bitmasks: [JavaIR.Property] = []
        var index = 0
        transitiveProperties.forEach { param, _ in
            bitmasks.append(JavaIR.Property(annotations: [], modifiers: [.private, .static, .final], type: "int", name: param.uppercased() + "_SET", initialValue: "1 << " + String(index)))
            index += 1
        }

        return [props, bitmasks, [bits]]
    }

    func renderModelGetters(modifiers: JavaModifier = [.public]) -> [JavaIR.Method] {
        let getters = transitiveProperties.map { param, schemaObj in
            JavaIR.method(modifiers, self.typeFromSchema(param, schemaObj) + " get" + param.snakeCaseToCapitalizedPropertyName() + "()") { [
                "return this." + param.snakeCaseToPropertyName() + ";",
            ] }
        }
        return getters
    }

    func renderModelIsSetCheckers(modifiers: JavaModifier = [.public]) -> [JavaIR.Method] {
        let getters = transitiveProperties.map { param, _ in
            JavaIR.method(modifiers, "boolean get" + param.snakeCaseToCapitalizedPropertyName() + "IsSet()") { [
                "return (this._bits & " + param.uppercased() + "_SET) == " + param.uppercased() + "_SET;",
            ] }
        }
        return getters
    }

    func renderModelMergeFrom() -> JavaIR.Method {
        return JavaIR.method([.public], className + " mergeFrom(" + className + " model)") { [
            self.className + ".Builder builder = this.toBuilder();",
            "builder.mergeFrom(model);",
            "return builder.build();",
        ] }
    }

    func renderModelToBuilder() -> JavaIR.Method {
        return JavaIR.method([.public], className + ".Builder toBuilder()") { ["return new " + self.className + ".Builder(this);"] }
    }

    func renderModelBuilder() -> JavaIR.Method {
        return JavaIR.method([.public, .static], className + ".Builder builder()") { [
            "return new \(className).Builder();",
        ] }
    }

    // MARK: - Model.Builder

    func renderBuilderConstructors() -> [JavaIR.Method] {
        let emptyConstructor = JavaIR.method([.private], "Builder()") { [] }

        let privateConstructor = JavaIR.method([.private], "Builder(@NonNull " + className + " model)") {
            self.transitiveProperties.map { param, _ in
                "this." + param.snakeCaseToPropertyName() + " = model." + param.snakeCaseToPropertyName() + ";"
            } + ["this._bits = model._bits;"]
        }

        return [emptyConstructor, privateConstructor]
    }

    func renderBuilderBuild() -> JavaIR.Method {
        let params = (transitiveProperties.map { param, _ in
            "this." + param.snakeCaseToPropertyName()
        } + ["this._bits"]).joined(separator: ",\n")
        return JavaIR.method([.public], "\(className) build()") { ["return new " + self.className + "(", params, ");"] }
    }

    func renderBuilderGetters(modifiers: JavaModifier = [.public]) -> [JavaIR.Method] {
        let getters = transitiveProperties.map { param, schemaObj in
            JavaIR.method(modifiers, self.typeFromSchema(param, schemaObj) + " get" + param.snakeCaseToCapitalizedPropertyName() + "()") { [
                "return this." + param.snakeCaseToPropertyName() + ";",
            ] }
        }
        return getters
    }

    func renderBuilderSetters(modifiers: JavaModifier = [.public]) -> [JavaIR.Method] {
        let setters = transitiveProperties.map { param, schemaObj in
            JavaIR.method(modifiers, "Builder set\(param.snakeCaseToCamelCase())(\(self.typeFromSchema(param, schemaObj)) value)") { [
                "this." + param.snakeCaseToPropertyName() + " = value;",
                "this._bits |= " + param.uppercased() + "_SET;",
                "return this;",
            ] }
        }
        return setters
    }

    func renderBuilderMerge() -> JavaIR.Method {
        let body = (transitiveProperties.map { param, _ in
            JavaIR.ifBlock(condition: "model.get" + param.snakeCaseToCapitalizedPropertyName() + "IsSet()") {
                ["this." + param.snakeCaseToPropertyName() + " = model." + param.snakeCaseToPropertyName() + ";"]
            }
        })
        return JavaIR.method([.public], "void mergeFrom(" + className + " model)") { body }
    }

    func renderBuilderProperties(modifiers _: JavaModifier = [.private]) -> [[JavaIR.Property]] {
        let props = transitiveProperties.map { param, schemaObj in
            JavaIR.Property(annotations: ["SerializedName(\"\(param)\")"], modifiers: [.private], type: self.typeFromSchema(param, schemaObj), name: param.snakeCaseToPropertyName(), initialValue: "")
        }

        let bits = JavaIR.Property(annotations: [], modifiers: [.private], type: "int", name: "_bits", initialValue: "0")

        return [props, [bits]]
    }

    // MARK: - TypeAdapterFactory

    func renderTypeAdapterFactoryMethods() -> [JavaIR.Method] {
        return [JavaIR.method(annotations: ["Override"], [.public], "<T> TypeAdapter<T> create(Gson gson, TypeToken<T> typeToken)") { [
            JavaIR.ifBlock(condition: "!" + className + ".class.isAssignableFrom(typeToken.getRawType())") { [
                "return null;",
            ] },
            "return (TypeAdapter<T>) new " + className + "TypeAdapter(gson, this, typeToken);",
        ] }]
    }

    // MARK: - TypeAdapter

    func renderTypeAdapterProperties() -> [[JavaIR.Property]] {
        let delegate = JavaIR.Property(
            annotations: [],
            modifiers: [.final, .private],
            type: "TypeAdapter<" + className + ">",
            name: "delegateTypeAdapter",
            initialValue: ""
        )

        let elementTypeAdapter = JavaIR.Property(
            annotations: [],
            modifiers: [.final, .private],
            type: "TypeAdapter<JsonElement>",
            name: "elementTypeAdapter",
            initialValue: ""
        )

        return [[delegate, elementTypeAdapter]]
    }

    func renderTypeAdapterMethods() -> [JavaIR.Method] {
        let constructor = JavaIR.method(
            annotations: [],
            [.public],
            className + "TypeAdapter(Gson gson, " + className + "TypeAdapterFactory factory, TypeToken typeToken)"
        ) { [
            "this.delegateTypeAdapter = gson.getDelegateAdapter(factory, typeToken);",
            "this.elementTypeAdapter = gson.getAdapter(JsonElement.class);",
        ] }

        let write = JavaIR.method(
            annotations: ["Override"],
            [.public],
            "void write(JsonWriter writer, " + className + " value) throws IOException"
        ) { [
            "this.delegateTypeAdapter.write(writer, value);",
        ] }

        let read = JavaIR.method(
            annotations: ["Override"],
            [.public],
            className + " read(JsonReader reader) throws IOException"
        ) { [
            "JsonElement tree = this.elementTypeAdapter.read(reader);",
            className + " model = this.delegateTypeAdapter.fromJsonTree(tree);",
            "Set<String> keys = tree.getAsJsonObject().keySet();",
            JavaIR.forBlock(condition: "String key : keys") { [
                JavaIR.switchBlock(variableToCheck: "key", defaultBody: ["break;"]) {
                    transitiveProperties.map { param, _ in
                        JavaIR.Case(
                            variableEquals: "\"" + param + "\"",
                            body: ["model._bits |= " + param.uppercased() + "_SET;"]
                        )
                    }
                },
            ] },
            "return model;",
        ] }

        return [constructor, write, read]
    }

    // MARK: - Render from root

    func renderRoots() -> [JavaIR.Root] {
        let packages = params[.packageName].flatMap {
            [JavaIR.Root.packages(names: [$0])]
        } ?? []

        let imports = [
            JavaIR.Root.imports(names: [
                "com.google.gson.Gson",
                "com.google.gson.annotations.SerializedName",
                "com.google.gson.JsonElement",
                "com.google.gson.TypeAdapter",
                "com.google.gson.TypeAdapterFactory",
                "com.google.gson.reflect.TypeToken",
                "com.google.gson.stream.JsonReader",
                "com.google.gson.stream.JsonWriter",
                "java.io.IOException",
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
            methods: renderBuilderConstructors() + renderBuilderSetters() + renderBuilderGetters() + [
                self.renderBuilderBuild(),
                self.renderBuilderMerge(),
            ],
            enums: [],
            innerClasses: [],
            properties: renderBuilderProperties()
        )

        let typeAdapterFactoryClass = JavaIR.Class(
            annotations: [],
            modifiers: [.public, .static],
            extends: nil,
            implements: ["TypeAdapterFactory"],
            name: className + "TypeAdapterFactory",
            methods: renderTypeAdapterFactoryMethods(),
            enums: [],
            innerClasses: [],
            properties: []
        )

        let typeAdapterClass = JavaIR.Class(
            annotations: [],
            modifiers: [.public, .static],
            extends: "TypeAdapter<" + className + ">",
            implements: nil,
            name: className + "TypeAdapter",
            methods: renderTypeAdapterMethods(),
            enums: [],
            innerClasses: [],
            properties: renderTypeAdapterProperties()
        )

        let modelClass = JavaIR.Root.classDecl(
            aClass: JavaIR.Class(
                annotations: [],
                modifiers: [.public],
                extends: nil,
                implements: nil,
                name: className,
                methods: [
                    self.renderModelConstructor(),
                    self.renderModelBuilder(),
                    self.renderModelToBuilder(),
                    self.renderModelMergeFrom(),
                    self.renderModelEquals(),
                    self.renderModelHashCode(),
                ] +
                    renderModelGetters() +
                    renderModelIsSetCheckers(),
                enums: enumProps,
                innerClasses: [
                    builderClass,
                    typeAdapterFactoryClass,
                    typeAdapterClass,
                ],
                properties: renderModelProperties()
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
