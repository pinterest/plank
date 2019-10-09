//
//  ObjectiveCBuilderExtension.swift
//  plank
//
//  Created by Rahul Malik on 2/14/17.
//
//

import Foundation

extension ObjCModelRenderer {
    // MARK: Builder methods

    func renderBuilderInitWithModel() -> ObjCIR.Method {
        return ObjCIR.method("- (instancetype)initWithModel:(\(className) *)modelObject") {
            [
                "NSParameterAssert(modelObject);",
                self.isBaseClass ? ObjCIR.ifStmt("!(self = [super init])") { ["return self;"] } :
                    "if (!(self = [super initWithModel:modelObject])) { return self; }",
                "struct \(self.dirtyPropertyOptionName) \(self.dirtyPropertiesIVarName) = modelObject.\(self.dirtyPropertiesIVarName);",

                self.properties.map { (param, _) -> String in
                    ObjCIR.ifStmt("\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className))") {
                        ["_\(Languages.objectiveC.snakeCaseToPropertyName(param)) = modelObject.\(Languages.objectiveC.snakeCaseToPropertyName(param));"]
                    }
                }.joined(separator: "\n"),
                "_\(self.dirtyPropertiesIVarName) = \(self.dirtyPropertiesIVarName);",
                "return self;",
            ]
        }
    }

    func renderBuilderPropertySetters() -> [ObjCIR.Method] {
        func renderBuilderPropertySetter(_ param: Parameter, _ schema: Schema) -> String {
            switch schema.memoryAssignmentType() {
            case .copy:
                return "[\(Languages.objectiveC.snakeCaseToPropertyName(param)) copy];"
            default:
                return "\(Languages.objectiveC.snakeCaseToPropertyName(param));"
            }
        }

        return properties.map { (param, prop) -> ObjCIR.Method in
            ObjCIR.method("- (void)set\(Languages.objectiveC.snakeCaseToCapitalizedPropertyName(param)):(\(typeFromSchema(param, prop)))\(Languages.objectiveC.snakeCaseToPropertyName(param))") {
                [
                    "_\(Languages.objectiveC.snakeCaseToPropertyName(param)) = \(renderBuilderPropertySetter(param, prop.schema))",
                    "_\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className)) = 1;",
                ]
            }
        }
    }

    func renderBuilderMergeWithModel() -> ObjCIR.Method {
        func formatParam(_ param: String, _ schema: Schema, _ nullability: Nullability?) -> String {
            return ObjCIR.ifStmt("modelObject.\(dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: className))") {
                func loop(_ schema: Schema, _ nullability: Nullability?) -> [String] {
                    switch schema {
                    case .object:
                        var stmt = ObjCIR.ifElseStmt("builder.\(Languages.objectiveC.snakeCaseToPropertyName(param))") { [
                            "builder.\(Languages.objectiveC.snakeCaseToPropertyName(param)) = [builder.\(Languages.objectiveC.snakeCaseToPropertyName(param)) mergeWithModel:value initType:PlankModelInitTypeFromSubmerge];",
                        ] } { [
                            "builder.\(Languages.objectiveC.snakeCaseToPropertyName(param)) = value;",
                        ] }
                        switch nullability {
                        case .some(.nullable): stmt = ObjCIR.ifElseStmt("value != nil") { [stmt] } { ["builder.\(Languages.objectiveC.snakeCaseToPropertyName(param)) = nil;"] }
                        case .some(.nonnull), .none: break
                        }
                        return [
                            "id value = modelObject.\(Languages.objectiveC.snakeCaseToPropertyName(param));",
                            stmt,
                        ]
                    case let .reference(with: ref):
                        switch ref.force() {
                        case let .some(.object(objSchema)):
                            return loop(.object(objSchema), nullability)
                        default:
                            fatalError("Error identifying reference for \(param) in \(schema)")
                        }
                    default:
                        return ["builder.\(Languages.objectiveC.snakeCaseToPropertyName(param)) = modelObject.\(Languages.objectiveC.snakeCaseToPropertyName(param));"]
                    }
                }
                return loop(schema, nullability)
            }
        }

        return ObjCIR.method("- (void)mergeWithModel:(\(className) *)modelObject") {
            [
                "NSParameterAssert(modelObject);",
                self.isBaseClass ? "" : "[super mergeWithModel:modelObject];",
                !self.properties.isEmpty ? "\(self.builderClassName) *builder = self;" : "",
                self.properties.map { ($0.0, $0.1.schema, $0.1.nullability) }.map(formatParam).joined(separator: "\n"),
            ].filter { $0 != "" }
        }
    }
}
