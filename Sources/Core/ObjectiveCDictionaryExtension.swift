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
        let dictionary = "dict"
        let props = self.properties.map { (param, schema) -> String in
            ObjCIR.ifStmt("_"+"\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className))") {
                [renderAddObjectStatement(param, schema, dictionary)]
            }
            }.joined(separator: "\n")
        return ObjCIR.method("- (NSDictionary *)dictionaryRepresentation") {[
            "NSMutableDictionary *\(dictionary) = [[NSMutableDictionary alloc]initWithCapacity:\(self.properties.count)];",
            props,
            "return dict;"
            ]}
    }
}

extension ObjCFileRenderer {
    fileprivate func renderAddObjectStatement(_ param: String, _ schema: Schema, _ dictionary: String, counter: Int = 0) -> String {
        let propIVarName = "_\(param.snakeCaseToPropertyName())"
        switch schema {
        case .boolean:
            return "[\(dictionary) setObject: [NSNumber numberWithBool:"+propIVarName + "] forKey: @\"" + param + "\" ];"

        case .float:
            return "[\(dictionary) setObject: [NSNumber numberWithDouble:"+propIVarName + "] forKey: @\"" + param + "\" ];"
        case .integer:
            return "[\(dictionary) setObject: [NSNumber numberWithInteger:"+propIVarName + "] forKey: @\"" + param + "\" ];"
        case .object:
            return ObjCIR.scope {[
                ObjCIR.ifStmt("\(propIVarName) != nil") {[
                    "[\(dictionary) setObject: [\(propIVarName) dictionaryRepresentation]  forKey: @\"\(param)\" ];"
                ]},
                ObjCIR.elseStmt({[
                    "[\(dictionary) setObject: [NSNull null] forKey: @\"" + param + "\" ];"
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
                    "[\(dictionary) setObject: "+propIVarName + " forKey: @\"" + param + "\" ];"
                    ]},
                ObjCIR.elseStmt({[
                    "[\(dictionary) setObject: [NSNull null] forKey: @\"" + param + "\" ];"
                    ]
                })
                ]}
        case .string(format: .some(.uri)):
            return ObjCIR.scope {[
                ObjCIR.ifStmt("\(propIVarName) != nil") {[
                    "[\(dictionary) setObject: ["+propIVarName + " absoluteString] forKey: @\"" + param + "\" ];"
                    ]},
                ObjCIR.elseStmt({[
                    "[\(dictionary) setObject: [NSNull null] forKey: @\"" + param + "\" ];"
                    ]
                })
                ]}
        case .string(format: .some(.dateTime)):
            return ObjCIR.scope {[
                ObjCIR.ifStmt("\(propIVarName) != nil") {[
                    "[\(dictionary) setObject: [[NSValueTransformer valueTransformerForName:\(dateValueTransformerKey)] transformedValue:\(propIVarName)]  forKey: @\"" + param + "\" ];"
                    ]},
                ObjCIR.elseStmt({[
                    "[\(dictionary) setObject: [NSNull null] forKey: @\"" + param + "\" ];"
                    ]
                })
                ]}
        case .enumT(.integer):
            return "[\(dictionary) setObject: [NSNumber numberWithInteger:"+propIVarName + "] forKey: @\"" + param + "\" ];"
        case .enumT(.string):
            return "[\(dictionary) setObject: "+enumToStringMethodName(propertyName: param, className: self.className) + "(\(propIVarName))" + " forKey: @\"" + param + "\" ];"
        case .array(itemType: let itemType?):
            let currentResult = "result\(counter)"
            let currentObj = "obj\(counter)"
            switch itemType {
            case .reference,
                .object:
                return ObjCIR.scope {[
                    "NSArray *items = \(propIVarName);",
                    "NSMutableArray *\(currentResult) = [NSMutableArray arrayWithCapacity:items.count];",
                    ObjCIR.forStmt("id \(currentObj) in items") { [
                        ObjCIR.ifStmt("\(currentObj) != (id)kCFNull") { [
                             "[\(currentResult) addObject:[ \(currentObj) dictionaryRepresentation] ];"
                            ]}
                        ]},
                        "[\(dictionary) setObject:\(currentResult) forKey: @\"" + param + "\" ];"
                    ]}
            default:
            return ObjCIR.scope {[
                "NSArray *items = \(propIVarName);",
                "NSMutableArray *\(currentResult) = [NSMutableArray arrayWithCapacity:items.count];",
                ObjCIR.forStmt("id \(currentObj) in items") { [
                    ObjCIR.ifStmt("\(currentObj) != (id)kCFNull") { [
                        "[\(currentResult) addObject: \(currentObj)];"
                        ]}
                    ]},
                "[\(dictionary) setObject: "+currentResult + " forKey: @\"" + param + "\" ];"
                ]}
            }
        case .map(valueType: let type):
            return ObjCIR.scope {[
                ObjCIR.ifStmt("\(propIVarName) != nil") {[
                            renderAddObjectStatement(param, type!, dictionary)
                            ]},
                ObjCIR.elseStmt({[
                    "[\(dictionary) setObject: [NSNull null] forKey: @\"" + param + "\" ];"
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
                    "[\(dictionary) setObject: [NSNull null] forKey: @\"" + param + "\" ];"
                    ]
                })
                ]}
        case .reference(with: let ref):
            return ref.force().map {
                renderAddObjectStatement(param, $0, dictionary)
                } ?? {
                    assert(false, "TODO: Forward optional across methods")
                    return ""
                }()
        default:
            return ""
        }
    }
}
