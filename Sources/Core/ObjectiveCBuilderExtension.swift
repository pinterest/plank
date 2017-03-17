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
        return ObjCIR.method("- (instancetype)initWithModel:(\(self.className) *)modelObject") {
            [
                "NSParameterAssert(modelObject);",
                self.isBaseClass ? ObjCIR.ifStmt("!(self = [super init])") { ["return self;"] } :
                "if (!(self = [super initWithModel:modelObject])) { return self; }",
                "struct \(self.dirtyPropertyOptionName) \(self.dirtyPropertiesIVarName) = modelObject.\(self.dirtyPropertiesIVarName);",
                self.properties.map({ (param, _) -> String in
                    ObjCIR.ifStmt("\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className))") {
                        ["_\(param.snakeCaseToPropertyName()) = modelObject.\(param.snakeCaseToPropertyName());"]
                    }
                }).joined(separator: "\n"),
                "_\(self.dirtyPropertiesIVarName) = \(self.dirtyPropertiesIVarName);",
                "return self;"
            ]
        }
    }

    func renderBuilderPropertySetters() -> [ObjCIR.Method] {
        return self.properties.map({ (param, schema) -> ObjCIR.Method in
            ObjCIR.method("- (void)set\(param.snakeCaseToCapitalizedPropertyName()):(\(objcClassFromSchema(param, schema)))\(param.snakeCaseToPropertyName())") {
                [
                    "_\(param.snakeCaseToPropertyName()) = \(param.snakeCaseToPropertyName());",
                    "_\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className)) = 1;"
                ]
            }
        })
    }

    func renderBuilderMergeWithModel() -> ObjCIR.Method {
        func formatParam(_ param: String, _ schema: Schema) -> String {
            return ObjCIR.ifStmt("modelObject.\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className))") {
                func loop(_ schema: Schema) -> [String] {
                    switch schema {
                    case .Object(_):
                        return [
                            "id value = modelObject.\(param.snakeCaseToPropertyName());",
                            ObjCIR.ifElseStmt("value != nil") {[
                                ObjCIR.ifElseStmt("builder.\(param.snakeCaseToPropertyName())") {[
                                    "builder.\(param.snakeCaseToPropertyName()) = [builder.\(param.snakeCaseToPropertyName()) mergeWithModel:value initType:PlankModelInitTypeFromSubmerge];"
                                    ]} {[
                                        "builder.\(param.snakeCaseToPropertyName()) = value;"
                                        ]}
                                ]} {[
                                    "builder.\(param.snakeCaseToPropertyName()) = nil;"
                                    ]}
                        ]
                    case .Reference(with: let fn):
                        switch fn() {
                        case .some(.Object(let objSchema)):
                            return loop(.Object(objSchema))
                        default:
                            fatalError("Error identifying reference for \(param) in \(schema)")
                        }
                    default:
                        return ["builder.\(param.snakeCaseToPropertyName()) = modelObject.\(param.snakeCaseToPropertyName());"]
                    }
                }
                return loop(schema)
            }
        }

        return ObjCIR.method("- (void)mergeWithModel:(\(self.className) *)modelObject") {
            [
                "NSParameterAssert(modelObject);",
                self.isBaseClass ? "" : "[super mergeWithModel:modelObject];",
                self.properties.count > 0 ? "\(self.builderClassName) *builder = self;" : "",
                self.properties.map(formatParam).joined(separator: "\n")
                ].filter { $0 != "" }
        }
    }
}
