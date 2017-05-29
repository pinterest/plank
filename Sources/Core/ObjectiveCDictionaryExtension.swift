//
//  ObjectiveCDictionaryExtension.swift
//  plank
//
//  Created by Martin Matejovic on 18/05/2017.
//
//

import Foundation

extension ObjCModelRenderer {
    func renderGenerateDictionary() -> ObjCIR.Method {
        let props = self.properties.map { (param, schema) -> String in
            ObjCIR.ifStmt("_"+"\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className))") {
                [renderAddObjectStatement(param, schema)]
            }
            }.joined(separator: "\n")
        return ObjCIR.method("- (NSDictionary *)dictionaryRepresentation") {[
            "NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithCapacity:\(self.properties.count)];",
            props,
            "return dict;"
            ]}
    }
}

extension ObjCFileRenderer {

    fileprivate func renderAddObjectStatement(_ param: String, _ schema: Schema) -> String {
        let propIVarName = "_\(param.snakeCaseToPropertyName())"
        switch schema {
        case .boolean:
            return "[dict setObject: [NSNumber numberWithBool:"+propIVarName + "] forKey: @\"" + param + "\" ];"

        case .float:
            return "[dict setObject: [NSNumber numberWithDouble:"+propIVarName + "] forKey: @\"" + param + "\" ];"
        case .integer:
            return "[dict setObject: [NSNumber numberWithInteger:"+propIVarName + "] forKey: @\"" + param + "\" ];"
        case .object:
            return ObjCIR.scope {[
                ObjCIR.ifStmt("\(propIVarName) != nil") {[
                    "[dict setObject: "+propIVarName + " forKey: @\"" + param + "\" ];"
                ]},
                ObjCIR.elseStmt({[
                    "[dict setObject: [NSNull null] forKey: @\"" + param + "\" ];"
                ]
                })
                ]}
        case .string(format: .none),
             .string(format: .some(.email)),
             .string(format: .some(.hostname)),
             .string(format: .some(.ipv4)),
             .string(format: .some(.ipv6)):
            return ObjCIR.scope {[
                ObjCIR.ifStmt("\(propIVarName) != nil") {[
                    "[dict setObject: "+propIVarName + " forKey: @\"" + param + "\" ];"
                    ]},
                ObjCIR.elseStmt({[
                    "[dict setObject: [NSNull null] forKey: @\"" + param + "\" ];"
                    ]
                })
                ]}
        case .string(format: .some(.uri)):
            return ObjCIR.scope {[
                ObjCIR.ifStmt("\(propIVarName) != nil") {[
                    "[dict setObject: ["+propIVarName + " absoluteString] forKey: @\"" + param + "\" ];"
                    ]},
                ObjCIR.elseStmt({[
                    "[dict setObject: [NSNull null] forKey: @\"" + param + "\" ];"
                    ]
                })
                ]}
        case .string(format: .some(.dateTime)):
            return ObjCIR.scope {[
                ObjCIR.ifStmt("\(propIVarName) != nil") {[
                    "[dict setObject: [[NSValueTransformer valueTransformerForName:\(dateValueTransformerKey)] transformedValue:\(propIVarName)]  forKey: @\"" + param + "\" ];"
                    ]},
                ObjCIR.elseStmt({[
                    "[dict setObject: [NSNull null] forKey: @\"" + param + "\" ];"
                    ]
                })
                ]}
        case .enumT(.integer):
            return "[dict setObject: [NSNumber numberWithInteger:"+propIVarName + "] forKey: @\"" + param + "\" ];"
        case .enumT(.string):
            return "[dict setObject: "+enumToStringMethodName(propertyName: param, className: self.className) + "(\(propIVarName))" + " forKey: @\"" + param + "\" ];"
        case .array:
            return ObjCIR.scope {[
                ObjCIR.ifStmt("\(propIVarName) != nil") {[
                    "[dict setObject: "+propIVarName + " forKey: @\"" + param + "\" ];"
                    ]},
                ObjCIR.elseStmt({[
                    "[dict setObject: [NSNull null] forKey: @\"" + param + "\" ];"
                    ]
                })
                ]}
        case .map(valueType: _):
            return ObjCIR.scope {[
                ObjCIR.ifStmt("\(propIVarName) != nil") {[
                    "[dict setObject: "+propIVarName + " forKey: @\"" + param + "\" ];"
                    ]},
                ObjCIR.elseStmt({[
                    "[dict setObject: [NSNull null] forKey: @\"" + param + "\" ];"
                    ]
                })
                ]}
        case .oneOf(types: let avTypes):
            return ObjCIR.scope {[
                ObjCIR.ifStmt("\(propIVarName) != nil") {[

            ObjCIR.switchStmt("\(propIVarName).internalType") {
                avTypes.enumerated().map { (index, schema) -> ObjCIR.SwitchCase in
                    return ObjCIR.caseStmt(self.className+propIVarName.snakeCaseToCamelCase()+"InternalType"+ObjCADTRenderer.objectName(schema)) {[
                        ObjCIR.stmt("return [[NSDictionary alloc]initWithDictionary:[\(propIVarName).value\(index) dictionaryRepresentation]]")
                        ]}
                }
            }
                    ]},
                ObjCIR.elseStmt({[
                    "[dict setObject: [NSNull null] forKey: @\"" + param + "\" ];"
                    ]
                })
                ]}
        case .reference(with: let ref):
            return ref.force().map {
                renderAddObjectStatement(param, $0)
                } ?? {
                    assert(false, "TODO: Forward optional across methods")
                    return ""
                }()
            /*
            return ObjCIR.scope {[
                ObjCIR.ifStmt("\(propIVarName) != nil") {[
                    "[dict setObject: "+propIVarName + " forKey: @\"" + param + "\" ];"
                    ]},
                ObjCIR.elseStmt({[
                    "[dict setObject: [NSNull null] forKey: @\"" + param + "\" ];"
                    ]
                })
                ]}
 */
        }
    }
}
