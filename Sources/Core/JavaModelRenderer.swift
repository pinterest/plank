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
    let decorations: JavaDecorations
    let unknownPropertyLogging: JavaLoggingType?
    let uriType: JavaURIType

    init(rootSchema: SchemaObjectRoot, params: GenerationParameters) {
        self.rootSchema = rootSchema
        self.params = params

        if let decorationsFile = self.params[.javaDecorations] {
            do {
                decorations = try JSONDecoder().decode(JavaDecorations.self, from: Data(contentsOf: URL(fileURLWithPath: decorationsFile)))
            } catch {
                fatalError("Unable to parse custom Java annotations file with error: \(error)")
            }
        } else {
            decorations = JavaDecorations()
        }

        if let unknownPropertyLoggingParam = self.params[.javaUnknownPropertyLogging] {
            unknownPropertyLogging = JavaLoggingType(param: unknownPropertyLoggingParam)
        } else {
            unknownPropertyLogging = nil
        }

        if let uriType = JavaURIType(rawValue: params[.javaURIType] ?? JavaURIType.string.rawValue) {
            self.uriType = uriType
        } else {
            fatalError("java_uri_type must be one of " + JavaURIType.options + ". Invalid type provided: " + params[.javaURIType]!)
        }
    }

    // MARK: - JavaFileRenderer

    func renderURIType() -> String {
        return uriType.type
    }

    // MARK: - Top-level Model

    func renderModelConstructors() -> [JavaIR.Method] {
        let args = -->(transitiveProperties.map { param, schemaObj in
            self.typeFromSchema(param, schemaObj) + " " + Languages.java.snakeCaseToPropertyName(param) + ","
        } + ["boolean[] _bits"])

        let publicConstructor = JavaIR.method(annotations: decorations.annotationsForConstructor(), [.public], className + "()") {
            ["this._bits = new boolean[" + String(self.transitiveProperties.count) + "];"]
        }

        let privateConstructor = JavaIR.method(annotations: decorations.annotationsForConstructor(), [.private], className + "(\n" + args + "\n)") {
            self.transitiveProperties.map { param, _ in
                "this." + Languages.java.snakeCaseToPropertyName(param) + " = " + Languages.java.snakeCaseToPropertyName(param) + ";"
            } + ["this._bits = _bits;"]
        }

        if params[.javaGeneratePackagePrivateSetters] == nil {
            return [privateConstructor]
        } else {
            return [publicConstructor, privateConstructor]
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
        let bodyEquals = transitiveProperties.sorted { arg1, _ in
            arg1.1.schema.isPrimitiveType
        }.map { param, _ in
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
            JavaIR.Property(annotations: Set([.serializedName(name: param)] + self.decorations.annotationsForPropertyVariable(param)), modifiers: [.private], type: self.typeFromSchema(param, schemaObj), name: Languages.java.snakeCaseToPropertyName(param), initialValue: "")
        }

        let bits = JavaIR.Property(annotations: decorations.annotationsForVariable("_bits"), modifiers: [.private], type: "boolean[]", name: "_bits", initialValue: "")

        var bitmasks: [JavaIR.Property] = []
        var index = 0
        transitiveProperties.forEach { param, _ in
            bitmasks.append(JavaIR.Property(annotations: [], modifiers: [.private, .static, .final], type: "int", name: param.uppercased() + "_INDEX", initialValue: String(index)))
            index += 1
        }

        return [[renderStaticTypeString()], props, bitmasks, [bits]]
    }

    func propertyGetterForParam(param: String, schemaObj: SchemaObjectProperty) -> JavaIR.Method {
        let propertyName = Languages.java.snakeCaseToPropertyName(param)
        let capitalizedPropertyName = Languages.java.snakeCaseToCapitalizedPropertyName(param)
        let methodName = "get" + capitalizedPropertyName
        let annotations = decorations.annotationsForPropertyGetter(param)

        // For Booleans, Integers and Doubles, make the getter method @NonNull and squash to a default value if necessary.
        // This makes callers less susceptible to null pointer exceptions.
        switch schemaObj.schema {
        case .boolean:
            return JavaIR.method(annotations: Set(annotations + [.nonnull]), [.public], "Boolean " + methodName + "()") { [
                "return this." + propertyName + " == null ? Boolean.FALSE : this." + propertyName + ";",
            ]
            }
        case .integer:
            return JavaIR.method(annotations: Set(annotations + [.nonnull]), [.public], "Integer " + methodName + "()") { [
                "return this." + propertyName + " == null ? 0 : this." + propertyName + ";",
            ]
            }
        case .float:
            return JavaIR.method(annotations: Set(annotations + [.nonnull]), [.public], "Double " + methodName + "()") { [
                "return this." + propertyName + " == null ? 0 : this." + propertyName + ";",
            ]
            }
        default:
            return JavaIR.method(annotations: annotations, [.public], typeFromSchema(param, schemaObj) + " " + methodName + "()") { [
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

    // Package-private setters are generated with if the flag --java_generate_package_private_setters is set
    func renderModelPropertySetters() -> [JavaIR.Method] {
        if params[.javaGeneratePackagePrivateSetters] == nil {
            return []
        }

        let setters = transitiveProperties.map { param, schemaObj in
            JavaIR.method([], "void set\(Languages.java.snakeCaseToCapitalizedPropertyName(param))(\(self.typeFromSchema(param, schemaObj)) value)") { [
                "this." + Languages.java.snakeCaseToPropertyName(param) + " = value;",
            ] }
        }
        return setters + [JavaIR.method([], "void set_bits(boolean[] bits)") { [
            "this._bits = bits;",
        ] }]
    }

    func renderModelIsSetCheckers(modifiers: JavaModifier = [.public]) -> [JavaIR.Method] {
        let getters = transitiveProperties.map { param, _ in
            JavaIR.method(modifiers, "boolean get" + Languages.java.snakeCaseToCapitalizedPropertyName(param) + "IsSet()") { [
                "return this._bits.length > " + param.uppercased() + "_INDEX && this._bits[" + param.uppercased() + "_INDEX];",
            ] }
        }
        return getters
    }

    func renderModelMergeFrom() -> JavaIR.Method {
        let methodName = "mergeFrom"
        return JavaIR.method(annotations: decorations.annotationsForMethod(methodName).union([.nonnull]), [.public], className + " " + methodName + "(@NonNull " + className + " model)") { [
            self.className + ".Builder builder = this.toBuilder();",
            "builder.mergeFrom(model);",
            "return builder.build();",
        ] }
    }

    func renderModelToBuilder() -> JavaIR.Method {
        let methodName = "toBuilder"
        return JavaIR.method(annotations: decorations.annotationsForMethod(methodName).union([.nonnull]), [.public], className + ".Builder " + methodName + "()") { ["return new " + self.className + ".Builder(this);"] }
    }

    func renderModelBuilder() -> JavaIR.Method {
        return JavaIR.method(annotations: [.nonnull], [.public, .static], className + ".Builder builder()") { [
            "return new \(className).Builder();",
        ] }
    }

    // MARK: - Model.Builder

    func renderBuilderConstructors() -> [JavaIR.Method] {
        let emptyConstructor = JavaIR.method([.private], "Builder()") { ["this._bits = new boolean[" + String(self.transitiveProperties.count) + "];"] }

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
        return JavaIR.method(annotations: [.nonnull], [.public], "\(className) build()") { ["return new " + self.className + "(", params, ");"] }
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
            JavaIR.method(annotations: [.nonnull], modifiers, "Builder set\(Languages.java.snakeCaseToCapitalizedPropertyName(param))(\(self.typeFromSchema(param, schemaObj)) value)") { [
                "this." + Languages.java.snakeCaseToPropertyName(param) + " = value;",
                JavaIR.ifBlock(condition: "this._bits.length > " + param.uppercased() + "_INDEX") { [
                    "this._bits[" + param.uppercased() + "_INDEX] = true;",
                ] },
                "return this;",
            ] }
        }
        return setters
    }

    func renderBuilderMerge() -> JavaIR.Method {
        let body = (transitiveProperties.map { param, _ in
            JavaIR.ifBlock(condition: "model._bits.length > " + param.uppercased() + "_INDEX && model._bits[" + param.uppercased() + "_INDEX]") { [
                "this." + Languages.java.snakeCaseToPropertyName(param) + " = model." + Languages.java.snakeCaseToPropertyName(param) + ";",
                "this._bits[" + param.uppercased() + "_INDEX] = true;",
            ] }
        })
        return JavaIR.method([.public], "void mergeFrom(@NonNull " + className + " model)") { body }
    }

    func renderBuilderProperties(modifiers _: JavaModifier = [.private]) -> [[JavaIR.Property]] {
        let props = transitiveProperties.map { param, schemaObj in
            JavaIR.Property(annotations: [], modifiers: [.private], type: self.typeFromSchema(param, schemaObj), name: Languages.java.snakeCaseToPropertyName(param), initialValue: "")
        }

        let bits = JavaIR.Property(annotations: [], modifiers: [.private], type: "boolean[]", name: "_bits", initialValue: "")

        return [props, [bits]]
    }

    // MARK: - TypeAdapterFactory

    func renderTypeAdapterFactoryMethods() -> [JavaIR.Method] {
        return [JavaIR.method(annotations: [.nullable, JavaAnnotation.override], [.public], "<T> TypeAdapter<T> create(@NonNull Gson gson, @NonNull TypeToken<T> typeToken)") { [
            JavaIR.ifBlock(condition: "!" + className + ".class.isAssignableFrom(typeToken.getRawType())") { [
                "return null;",
            ] },
            "return (TypeAdapter<T>) new " + className + "TypeAdapter(gson);",
        ] }]
    }

    // MARK: - TypeAdapter

    func typeAdapterVariableNameForType(_ type: String) -> String {
        return type.replacingNonAlphaNumericsWith("_").lowercaseFirst + "TypeAdapter"
    }

    func renderTypeAdapterProperties() -> [[JavaIR.Property]] {
        let types = Set(transitiveProperties.map { param, schemaObj in
            unwrappedTypeFromSchema(param, schemaObj.schema)
        }).sorted()

        let typeAdapters = types.map { type in
            JavaIR.Property(
                annotations: [],
                modifiers: [.private],
                type: "TypeAdapter<\(type)>",
                name: typeAdapterVariableNameForType(type),
                initialValue: ""
            )
        }

        let gson = JavaIR.Property(
            annotations: [],
            modifiers: [.final, .private],
            type: "Gson",
            name: "gson",
            initialValue: ""
        )

        return [[gson] + typeAdapters]
    }

    func renderTypeAdapterMethods() -> [JavaIR.Method] {
        let constructor = JavaIR.method(
            annotations: [],
            [],
            className + "TypeAdapter(Gson gson)"
        ) { [
            "this.gson = gson;",
        ]
        }

        let write = JavaIR.methodThatThrows(
            annotations: [JavaAnnotation.override],
            [.public],
            "void write(@NonNull JsonWriter writer, " + className + " value)",
            ["IOException"]
        ) { [
            JavaIR.ifBlock(condition: "value == null") { [
                "writer.nullValue();",
                "return;",
            ] },
            "writer.beginObject();",
        ] +
            transitiveProperties.map { param, schemaObj in
                let type = unwrappedTypeFromSchema(param, schemaObj.schema)
                let typeAdapterVariableName = typeAdapterVariableNameForType(type)
                return JavaIR.ifBlock(condition: "value._bits.length > " + param.uppercased() + "_INDEX && value._bits[" + param.uppercased() + "_INDEX]") { [
                    // Creates TypeAdapter if necessary
                    JavaIR.ifBlock(condition: "this." + typeAdapterVariableName + " == null") { [
                        schemaObj.schema.isJavaCollection ? "this.\(typeAdapterVariableName) = this.gson.getAdapter(new TypeToken<\(type)>(){}).nullSafe();" : "this.\(typeAdapterVariableName) = this.gson.getAdapter(\(type).class).nullSafe();",
                    ] },
                    // Write to JsonWriter
                    "this." + typeAdapterVariableNameForType(unwrappedTypeFromSchema(param, schemaObj.schema)) + ".write(writer.name(\"" + param + "\"), value." + Languages.java.snakeCaseToPropertyName(param) + ");",
                ] }
            } + [
                "writer.endObject();",
            ]
        }

        let defaultLogging: [String] = {
            switch self.unknownPropertyLogging {
            case let .androidLog(level)?: return ["Log.\(level)(\"Plank\", \"Unmapped property for \(className): \" + name);"]
            default: return []
            }
        }()

        let read = JavaIR.methodThatThrows(
            annotations: [.nullable, JavaAnnotation.override],
            [.public],
            className + " read(@NonNull JsonReader reader)",
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
                JavaIR.switchBlock(variableToCheck: "name", defaultBody: defaultLogging + ["reader.skipValue();", "break;"]) {
                    transitiveProperties.map { param, schemaObj in
                        let type = unwrappedTypeFromSchema(param, schemaObj.schema)
                        let typeAdapterVariableName = typeAdapterVariableNameForType(type)
                        return JavaIR.Case(
                            variableEquals: "\"\(param)\"",
                            body: [
                                // Creates TypeAdapter if necessary
                                JavaIR.ifBlock(condition: "this." + typeAdapterVariableNameForType(unwrappedTypeFromSchema(param, schemaObj.schema)) + " == null") { [
                                    schemaObj.schema.isJavaCollection ? "this.\(typeAdapterVariableName) = this.gson.getAdapter(new TypeToken<\(type)>(){}).nullSafe();" : "this.\(typeAdapterVariableName) = this.gson.getAdapter(\(type).class).nullSafe();",
                                ] },
                                // Read from JsonReader
                                "builder.set" + Languages.java.snakeCaseToCapitalizedPropertyName(param) + "(this." + typeAdapterVariableNameForType(unwrappedTypeFromSchema(param, schemaObj.schema)) + ".read(reader));",
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

        let propertyTypeImports: [String] = transitiveProperties.compactMap { (_, prop) -> [String] in
            switch prop.schema {
            case .array(.none):
                return ["java.util.List"]
            case let .array(itemType: .some(itemType)):
                switch itemType {
                case .oneOf:
                    return ["java.util.List", "com.google.gson.JsonObject"]
                default:
                    return ["java.util.List"]
                }
            case .map(.none):
                return ["java.util.Map"]
            case let .map(valueType: .some(valueType)):
                switch valueType {
                case .oneOf:
                    return ["java.util.Map", "com.google.gson.JsonObject"]
                default:
                    return ["java.util.Map"]
                }
            case .set: return ["java.util.Set"]
            case .string(format: .some(.dateTime)): return ["java.util.Date"]
            default: return []
            }
        }.reduce(into: []) {
            $0.append(contentsOf: $1)
        }

        var additionalImports = propertyTypeImports
        additionalImports += uriType.imports
        additionalImports += (unknownPropertyLogging?.imports ?? [])
        additionalImports += (decorations.imports ?? [])

        let imports = [
            JavaIR.Root.imports(names: Set([
                "com.google.gson.Gson",
                "com.google.gson.annotations.SerializedName",
                "com.google.gson.TypeAdapter",
                "com.google.gson.TypeAdapterFactory",
                "com.google.gson.reflect.TypeToken",
                "com.google.gson.stream.JsonReader",
                "com.google.gson.stream.JsonToken",
                "com.google.gson.stream.JsonWriter",
                "java.io.IOException",
                "java.util.Objects",
                nullabilityAnnotationType.package + ".NonNull",
                nullabilityAnnotationType.package + ".Nullable",
            ] + additionalImports)),
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
            interfaces: [],
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
            interfaces: [],
            properties: []
        )

        let typeAdapterClass = JavaIR.Class(
            annotations: [],
            modifiers: [.private, .static],
            extends: "TypeAdapter<" + className + ">",
            implements: nil,
            name: className + "TypeAdapter",
            methods: renderTypeAdapterMethods(),
            enums: [],
            innerClasses: [],
            interfaces: [],
            properties: renderTypeAdapterProperties()
        )

        let modelClass = JavaIR.Root.classDecl(
            aClass: JavaIR.Class(
                annotations: decorations.annotationsForClass(),
                modifiers: [.public],
                extends: decorations.class?.extends,
                implements: decorations.class?.implements,
                name: className,
                methods: renderModelConstructors() + [
                    self.renderModelBuilder(),
                    self.renderModelToBuilder(),
                    self.renderModelMergeFrom(),
                    self.renderModelEquals(),
                    self.renderModelHashCode(),
                ] +
                    renderModelPropertyGetters() +
                    renderModelPropertySetters() +
                    renderModelIsSetCheckers(),
                enums: enumProps,
                innerClasses: [
                    builderClass,
                    typeAdapterFactoryClass,
                    typeAdapterClass,
                ] + adtClasses,
                interfaces: [],
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
