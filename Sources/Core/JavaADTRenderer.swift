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
        let adtName = "\(rootSchema.name)_\(property)"
        let formattedADTName = Languages.java.snakeCaseToCamelCase(adtName)

        func interfaceMethods() -> [JavaIR.Method] {
            return schemas.enumerated()
                .map { (unwrappedTypeFromSchema("", $0.element.schema), $0.offset) }
                .map { JavaIR.method([], "R match(@NonNull \($0.0) value\($0.1))") { [] } }
        }

        let matcherInterface = JavaIR.Interface(modifiers: [.public],
                                                extends: nil,
                                                name: "\(formattedADTName)Matcher<R>",
                                                methods: interfaceMethods())

        let matcherMethod = JavaIR.method(annotations: [.nullable], [.public], "<R> R match\(formattedADTName)(\(formattedADTName)Matcher<R> matcher)") {
            schemas.enumerated().map { index, _ in
                JavaIR.ifBlock(condition: "value\(index) != null") {
                    ["return matcher.match(value\(index));"]
                }
            } +
                ["return null;"]
        }

        let emptyConstructor = JavaIR.method([.private], "\(formattedADTName)()") { [] }
        let typeConstructors = schemas.enumerated().map { index, schemaObj in
            JavaIR.method([.public], "\(formattedADTName)(@NonNull \(unwrappedTypeFromSchema("", schemaObj.schema)) value)") { [
                "this.value\(index) = value;",
            ] }
        }

        let internalProperties = schemas.enumerated()
            .map { (typeFromSchema("", $0.element), $0.offset) }
            .map { JavaIR.Property(annotations: [], modifiers: [.private], type: $0.0, name: "value\($0.1)", initialValue: "") }

        let cls = JavaIR.Class(annotations: [],
                               modifiers: [.public, .static, .final],
                               extends: nil,
                               implements: nil,
                               name: "\(formattedADTName)",
                               methods: [emptyConstructor] + typeConstructors + [matcherMethod],
                               enums: [],
                               innerClasses: [
                                   adtTypeAdapterFactory(property: property, schemas: schemas),
                                   adtTypeAdapter(property: property, schemas: schemas),
                               ],
                               interfaces: [matcherInterface],
                               properties: [internalProperties])

        return [JavaIR.Root.classDecl(aClass: cls)]
    }

    func adtTypeAdapterFactory(property: String, schemas _: [SchemaObjectProperty]) -> JavaIR.Class {
        let adtName = "\(rootSchema.name)_\(property)"
        let formattedADTName = Languages.java.snakeCaseToCamelCase(adtName)

        let createMethod = JavaIR.method(annotations: [.nullable, JavaAnnotation.override], [.public], "<T> TypeAdapter<T> create(@NonNull Gson gson, @NonNull TypeToken<T> typeToken)") { [
            JavaIR.ifBlock(condition: "!" + formattedADTName + ".class.isAssignableFrom(typeToken.getRawType())") { [
                "return null;",
            ] },
            "return (TypeAdapter<T>) new " + formattedADTName + "TypeAdapter(gson);",
        ] }

        return JavaIR.Class(
            annotations: [],
            modifiers: [.public, .static],
            extends: nil,
            implements: ["TypeAdapterFactory"],
            name: formattedADTName + "TypeAdapterFactory",
            methods: [createMethod],
            enums: [],
            innerClasses: [],
            interfaces: [],
            properties: []
        )
    }

    func adtTypeAdapter(property: String, schemas: [SchemaObjectProperty]) -> JavaIR.Class {
        let adtName = "\(rootSchema.name)_\(property)"
        let formattedADTName = Languages.java.snakeCaseToCamelCase(adtName)

        return JavaIR.Class(
            annotations: [],
            modifiers: [.private, .static],
            extends: "TypeAdapter<\(formattedADTName)>",
            implements: [],
            name: formattedADTName + "TypeAdapter",
            methods: adtTypeAdapterMethods(property: property, schemas: schemas),
            enums: [],
            innerClasses: [],
            interfaces: [],
            properties: adtTypeAdapterProperties(schemas: schemas)
        )
    }

    func adtTypeAdapterVariableNameForType(_ type: String) -> String {
        return type.replacingNonAlphaNumericsWith("_").lowercaseFirst + "TypeAdapter"
    }

    func adtTypeAdapterProperties(schemas: [SchemaObjectProperty]) -> [[JavaIR.Property]] {
        let typeAdapters = schemas.map { schemaObj in
            JavaIR.Property(
                annotations: [],
                modifiers: [.private],
                type: "TypeAdapter<\(unwrappedTypeFromSchema("", schemaObj.schema))>",
                name: typeAdapterVariableNameForType(unwrappedTypeFromSchema("", schemaObj.schema)),
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

    func adtTypeAdapterMethods(property: String, schemas: [SchemaObjectProperty]) -> [JavaIR.Method] {
        let adtName = "\(rootSchema.name)_\(property)"
        let formattedADTName = Languages.java.snakeCaseToCamelCase(adtName)

        let constructor = JavaIR.method(
            annotations: [],
            [.public],
            formattedADTName + "TypeAdapter(Gson gson)"
        ) { [
            "this.gson = gson;",
        ]
        }

        let write = JavaIR.methodThatThrows(
            annotations: [JavaAnnotation.override],
            [.public],
            "void write(@NonNull JsonWriter writer, " + formattedADTName + " value)",
            ["IOException"]
        ) {
            [
                JavaIR.ifBlock(condition: "value == null") { [
                    "writer.nullValue();",
                    "return;",
                ] },
            ] +
                schemas.enumerated().map { index, schemaObj in
                    let typeAdapterVariableName = typeAdapterVariableNameForType(unwrappedTypeFromSchema("", schemaObj.schema))
                    return JavaIR.ifBlock(condition: "value.value\(index) != null") {
                        [
                            // Creates TypeAdapter if necessary
                            JavaIR.ifBlock(condition: "\(typeAdapterVariableName) == null") { [
                                "\(typeAdapterVariableName) = gson.getAdapter(\(unwrappedTypeFromSchema("", schemaObj.schema)).class).nullSafe();",
                            ] },
                            // Write to JsonWriter
                            "\(typeAdapterVariableName).write(writer, value.value\(index));",
                        ]
                    }
                }
        }

        let read = JavaIR.methodThatThrows(
            annotations: [.nullable, JavaAnnotation.override],
            [.public],
            formattedADTName + " read(@NonNull JsonReader reader)",
            ["IOException"]
        ) { [
            JavaIR.ifBlock(condition: "reader.peek() == JsonToken.NULL") { [
                "reader.nextNull();",
                "return null;",
            ] },

            JavaIR.ifBlock(condition: "reader.peek() == JsonToken.BEGIN_OBJECT") { [
                "JsonObject jsonObject = this.gson.fromJson(reader, JsonObject.class);",
                "String type;",
                JavaIR.tryCatch(try: ["type = jsonObject.get(\"type\").getAsString();"], catch: JavaIR.Catch(argument: "Exception e", body: ["return new \(formattedADTName)();"])),
                JavaIR.ifBlock(condition: "type == null") { [
                    "return new \(formattedADTName)();",
                ] },
                JavaIR.switchBlock(variableToCheck: "type", defaultBody: ["return new \(formattedADTName)();"]) {
                    schemas.enumerated().compactMap { _, schemaObj in
                        switch schemaObj.schema {
                        case let .reference(with: ref):
                            switch ref.force() {
                            case let .some(.object(schemaRoot)):
                                let typeAdapterVariableName = typeAdapterVariableNameForType(unwrappedTypeFromSchema("", schemaObj.schema))
                                return JavaIR.Case(
                                    variableEquals: "\"" + schemaRoot.typeIdentifier + "\"",
                                    body: [
                                        // Creates TypeAdapter if necessary
                                        JavaIR.ifBlock(condition: "this.\(typeAdapterVariableName) == null") { [
                                            "this.\(typeAdapterVariableName) = this.gson.getAdapter(\(unwrappedTypeFromSchema("", schemaObj.schema)).class).nullSafe();",
                                        ] },
                                        "return new \(formattedADTName)(\(typeAdapterVariableName).fromJsonTree(jsonObject));",
                                    ],
                                    shouldBreak: false
                                )
                            default:
                                return nil
                            }
                        default:
                            return nil
                        }
                    }
                },
            ] },

            "reader.skipValue();",
            "return new \(formattedADTName)();",
        ] }

        return [constructor, write, read]
    }
}
