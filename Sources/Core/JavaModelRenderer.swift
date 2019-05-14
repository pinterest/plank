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
            self.typeFromSchema(param, schemaObj) + " " + Languages.java.snakeCaseToPropertyName(param) + ","
        } + ["int _bits"])

        return JavaIR.method([.private], className + "(\n" + args + "\n)") {
            self.transitiveProperties.map { param, _ in
                "this." + Languages.java.snakeCaseToPropertyName(param) + " = " + Languages.java.snakeCaseToPropertyName(param) + ";"
            } + ["this._bits = _bits;"]
        }
    }

    func renderStaticTypeString() -> JavaIR.Property {
        return JavaIR.Property(annotations: [], modifiers: [.public, .static, .final], type: "String", name: "TYPE", initialValue: "\"" + rootSchema.typeIdentifier + "\"")
    }

    func renderModelHashCode() -> JavaIR.Method {
        let bodyHashCode = transitiveProperties.map { param, _ in
            Languages.java.snakeCaseToPropertyName(param)
        }.joined(separator: ",\n")

        return JavaIR.method(annotations: [JavaAnnotation.override], [.public], "int hashCode()") { [
            "return Objects.hash(" + bodyHashCode + ");",
        ]
        }
    }

    func renderModelEquals() -> JavaIR.Method {
        let bodyEquals = transitiveProperties.map { param, _ in
            "Objects.equals(this." + Languages.java.snakeCaseToPropertyName(param) + ", that." + Languages.java.snakeCaseToPropertyName(param) + ")"
        }.joined(separator: " &&\n")

        return JavaIR.method(annotations: [JavaAnnotation.override], [.public], "boolean equals(Object o)") { [
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
            JavaIR.Property(annotations: [.serializedName(name: param)], modifiers: [.private], type: self.typeFromSchema(param, schemaObj), name: Languages.java.snakeCaseToPropertyName(param), initialValue: "")
        }

        let bits = JavaIR.Property(annotations: [], modifiers: [.private], type: "int", name: "_bits", initialValue: "0")

        var bitmasks: [JavaIR.Property] = []
        var index = 0
        transitiveProperties.forEach { param, _ in
            bitmasks.append(JavaIR.Property(annotations: [], modifiers: [.private, .static, .final], type: "int", name: param.uppercased() + "_SET", initialValue: "1 << " + String(index)))
            index += 1
        }

        return [[renderStaticTypeString()], props, bitmasks, [bits]]
    }

    func propertyGetterForParam(param: String, schemaObj: SchemaObjectProperty) -> JavaIR.Method {
        let propertyName = Languages.java.snakeCaseToPropertyName(param)
        let capitalizedPropertyName = Languages.java.snakeCaseToCapitalizedPropertyName(param)

        // For Booleans, Integers and Doubles, make the getter method @NonNull and squash to a default value if necessary.
        // This makes callers less susceptible to null pointer exceptions.
        switch schemaObj.schema {
        case .boolean:
            return JavaIR.method([.public], "@NonNull Boolean get" + capitalizedPropertyName + "()") { [
                "return this." + propertyName + " == null ? Boolean.FALSE : this." + propertyName + ";",
            ]
            }
        case .integer:
            return JavaIR.method([.public], "@NonNull Integer get" + capitalizedPropertyName + "()") { [
                "return this." + propertyName + " == null ? 0 : this." + propertyName + ";",
            ]
            }
        case .float:
            return JavaIR.method([.public], "@NonNull Double get" + capitalizedPropertyName + "()") { [
                "return this." + propertyName + " == null ? 0 : this." + propertyName + ";",
            ]
            }
        default:
            return JavaIR.method([.public], typeFromSchema(param, schemaObj) + " get" + capitalizedPropertyName + "()") { [
                "return this." + propertyName + ";",
            ]
            }
        }
    }

    func renderModelPropertyGetters() -> [JavaIR.Method] {
        let getters = transitiveProperties.map { param, schemaObj in
            propertyGetterForParam(param: param, schemaObj: schemaObj)
        }
        return getters
    }

    func renderModelIsSetCheckers(modifiers: JavaModifier = [.public]) -> [JavaIR.Method] {
        let getters = transitiveProperties.map { param, _ in
            JavaIR.method(modifiers, "boolean get" + Languages.java.snakeCaseToCapitalizedPropertyName(param) + "IsSet()") { [
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
                "this." + Languages.java.snakeCaseToPropertyName(param) + " = model." + Languages.java.snakeCaseToPropertyName(param) + ";"
            } + ["this._bits = model._bits;"]
        }

        return [emptyConstructor, privateConstructor]
    }

    func renderBuilderBuild() -> JavaIR.Method {
        let params = (transitiveProperties.map { param, _ in
            "this." + Languages.java.snakeCaseToPropertyName(param)
        } + ["this._bits"]).joined(separator: ",\n")
        return JavaIR.method([.public], "\(className) build()") { ["return new " + self.className + "(", params, ");"] }
    }

    func renderBuilderGetters(modifiers: JavaModifier = [.public]) -> [JavaIR.Method] {
        let getters = transitiveProperties.map { param, schemaObj in
            JavaIR.method(modifiers, self.typeFromSchema(param, schemaObj) + " get" + Languages.java.snakeCaseToCapitalizedPropertyName(param) + "()") { [
                "return this." + Languages.java.snakeCaseToPropertyName(param) + ";",
            ] }
        }
        return getters
    }

    func renderBuilderSetters(modifiers: JavaModifier = [.public]) -> [JavaIR.Method] {
        let setters = transitiveProperties.map { param, schemaObj in
            JavaIR.method(modifiers, "Builder set\(Languages.java.snakeCaseToCamelCase(param))(\(self.typeFromSchema(param, schemaObj)) value)") { [
                "this." + Languages.java.snakeCaseToPropertyName(param) + " = value;",
                "this._bits |= " + param.uppercased() + "_SET;",
                "return this;",
            ] }
        }
        return setters
    }

    func renderBuilderMerge() -> JavaIR.Method {
        let body = (transitiveProperties.map { param, _ in
            JavaIR.ifBlock(condition: "model.get" + Languages.java.snakeCaseToCapitalizedPropertyName(param) + "IsSet()") {
                ["this." + Languages.java.snakeCaseToPropertyName(param) + " = model." + Languages.java.snakeCaseToPropertyName(param) + ";"]
            }
        })
        return JavaIR.method([.public], "void mergeFrom(" + className + " model)") { body }
    }

    func renderBuilderProperties(modifiers _: JavaModifier = [.private]) -> [[JavaIR.Property]] {
        let props = transitiveProperties.map { param, schemaObj in
            JavaIR.Property(annotations: [.serializedName(name: param)], modifiers: [.private], type: self.typeFromSchema(param, schemaObj), name: Languages.java.snakeCaseToPropertyName(param), initialValue: "")
        }

        let bits = JavaIR.Property(annotations: [], modifiers: [.private], type: "int", name: "_bits", initialValue: "0")

        return [props, [bits]]
    }

    // MARK: - TypeAdapterFactory

    func renderTypeAdapterFactoryMethods() -> [JavaIR.Method] {
        return [JavaIR.method(annotations: [JavaAnnotation.override], [.public], "<T> TypeAdapter<T> create(Gson gson, TypeToken<T> typeToken)") { [
            JavaIR.ifBlock(condition: "!" + className + ".class.isAssignableFrom(typeToken.getRawType())") { [
                "return null;",
            ] },
            "return (TypeAdapter<T>) new " + className + "TypeAdapter(gson, this, typeToken);",
        ] }]
    }

    // MARK: - TypeAdapter

    func typeAdapterVariableNameForType(_ type: String) -> String {
        return type.replacingNonAlphaNumericsWith("_").lowercaseFirst + "TypeAdapter"
    }

    func renderTypeAdapterProperties() -> [[JavaIR.Property]] {
        let delegate = JavaIR.Property(
            annotations: [],
            modifiers: [.final, .private],
            type: "TypeAdapter<" + className + ">",
            name: "delegateTypeAdapter",
            initialValue: ""
        )

        let types = Set(transitiveProperties.map { param, schemaObj in
            unwrappedTypeFromSchema(param, schemaObj.schema)
        }).sorted()

        let typeAdapters = types.map { type in
            JavaIR.Property(
                annotations: [],
                modifiers: [.final, .private],
                type: "TypeAdapter<\(type)>",
                name: typeAdapterVariableNameForType(type),
                initialValue: ""
            )
        }

        return [[delegate], typeAdapters]
    }

    func renderTypeAdapterMethods() -> [JavaIR.Method] {
        let constructor = JavaIR.method(
            annotations: [],
            [.public],
            className + "TypeAdapter(Gson gson, " + className + "TypeAdapterFactory factory, TypeToken typeToken)"
        ) { ["this.delegateTypeAdapter = gson.getDelegateAdapter(factory, typeToken);"] +
            Set(transitiveProperties.map { param, schemaObj in
                let type = unwrappedTypeFromSchema(param, schemaObj.schema)
                let variableName = typeAdapterVariableNameForType(type)
                if schemaObj.schema.isJavaCollection {
                    return "this.\(variableName) = gson.getAdapter(new TypeToken<" + type + ">(){}).nullSafe();"
                } else {
                    return "this.\(variableName) = gson.getAdapter(\(type).class).nullSafe();"
                }
            }).sorted()
        }

        let write = JavaIR.methodThatThrows(
            annotations: [JavaAnnotation.override],
            [.public],
            "void write(JsonWriter writer, " + className + " value)",
            ["IOException"]
        ) { [
            "this.delegateTypeAdapter.write(writer, value);",
        ] }

        let read = JavaIR.methodThatThrows(
            annotations: [JavaAnnotation.override],
            [.public],
            className + " read(JsonReader reader)",
            ["IOException"]
        ) { [
            JavaIR.ifBlock(condition: "reader.peek() == JsonToken.NULL") { [
                "reader.nextNull();",
                "return null;",
            ] },
            "Builder builder = \(className).builder();",
            "reader.beginObject();",
            JavaIR.whileBlock(condition: "reader.hasNext()") { [
                "String name = reader.nextName();",
                JavaIR.switchBlock(variableToCheck: "name", defaultBody: ["reader.skipValue();"]) {
                    transitiveProperties.map { param, schemaObj in
                        JavaIR.Case(
                            variableEquals: "\"\(param)\"",
                            body: [
                                "builder.set" + Languages.java.snakeCaseToCapitalizedPropertyName(param) + "(" + typeAdapterVariableNameForType(unwrappedTypeFromSchema(param, schemaObj.schema)) + ".read(reader));",
                            ]
                        )
                    }
                },
            ] },
            "reader.endObject();",
            "return builder.build();",
        ] }

        return [constructor, write, read]
    }

    // MARK: - Render from root

    func renderRoots() -> [JavaIR.Root] {
        let packages = params[.packageName].flatMap {
            [JavaIR.Root.packages(names: [$0])]
        } ?? []

        guard let nullabilityAnnotationType = JavaNullabilityAnnotationType(rawValue: params[.javaNullabilityAnnotationType] ?? "android-support") else {
            fatalError("java_nullability_annotation_type must be either android-support or androidx. Invalid type provided: " + params[.javaNullabilityAnnotationType]!)
        }

        let imports = [
            JavaIR.Root.imports(names: [
                "com.google.gson.Gson",
                "com.google.gson.annotations.SerializedName",
                "com.google.gson.JsonElement",
                "com.google.gson.TypeAdapter",
                "com.google.gson.TypeAdapterFactory",
                "com.google.gson.reflect.TypeToken",
                "com.google.gson.stream.JsonReader",
                "com.google.gson.stream.JsonToken",
                "com.google.gson.stream.JsonWriter",
                "java.io.IOException",
                "java.util.Date",
                "java.util.Map",
                "java.util.Set",
                "java.util.List",
                "java.util.Objects",
                "java.lang.annotation.Retention",
                "java.lang.annotation.RetentionPolicy",
                nullabilityAnnotationType.package + ".NonNull",
                nullabilityAnnotationType.package + ".Nullable",
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

        let adtClasses: [JavaIR.Class] = adtRoots.compactMap {
            switch $0 {
            case let .classDecl(aClass: classObj):
                return classObj
            default:
                return nil
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
                extends: params[.javaExtends],
                implements: params[.javaImplements]?.components(separatedBy: ","),
                name: className,
                methods: [
                    self.renderModelConstructor(),
                    self.renderModelBuilder(),
                    self.renderModelToBuilder(),
                    self.renderModelMergeFrom(),
                    self.renderModelEquals(),
                    self.renderModelHashCode(),
                ] +
                    renderModelPropertyGetters() +
                    renderModelIsSetCheckers(),
                enums: enumProps,
                innerClasses: [
                    builderClass,
                    typeAdapterFactoryClass,
                    typeAdapterClass,
                ] + adtClasses,
                properties: renderModelProperties()
            )
        )

        let roots: [JavaIR.Root] =
            packages +
            imports +
            adtRoots.compactMap {
                switch $0 {
                case .classDecl(aClass: _):
                    return nil
                default:
                    return $0
                }
            } + [modelClass]
        return roots
    }
}
