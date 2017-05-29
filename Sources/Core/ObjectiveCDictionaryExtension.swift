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
        case .array(_):
            /*
            let currentResult = "result\(counter)"
            let currentTmp = "tmp\(counter)"
            let currentObj = "obj\(counter)"
            return [
                "NSArray *items = \(rawObjectName);",
                "NSMutableArray *\(currentResult) = [NSMutableArray arrayWithCapacity:items.count];",
                ObjCIR.forStmt("id \(currentObj) in items") { [
                    ObjCIR.ifStmt("\(currentObj) != (id)kCFNull") { [
                        "id \(currentTmp) = nil;",
                        renderPropertyInit(currentTmp, currentObj, schema: itemType, firstName: firstName, counter: counter + 1).joined(separator: "\n"),
                        ObjCIR.ifStmt("\(currentTmp) != nil") {[
                            "[\(currentResult) addObject:\(currentTmp)];"
                            
                            ]}
                        ]}
                        ObjCIR.elseStmt({[
                        "[dict setObject: [NSNull null] forKey: @\"" + param + "\" ];"
                        ]
                    })
                    ]},
                "\(propertyToAssign) = \(currentResult);"
            ]*/
        
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
        case .oneOf(types: _):
            return ObjCIR.scope {[
                ObjCIR.ifStmt("\(propIVarName) != nil") {[
                    "[dict setObject: "+propIVarName + " forKey: @\"" + param + "\" ];"
                    ]},
                ObjCIR.elseStmt({[
                    "[dict setObject: [NSNull null] forKey: @\"" + param + "\" ];"
                    ]
                })
                ]}
        case .reference(with: _):
            return ObjCIR.scope {[
                ObjCIR.ifStmt("\(propIVarName) != nil") {[
                    "[dict setObject: "+propIVarName + " forKey: @\"" + param + "\" ];"
                    ]},
                ObjCIR.elseStmt({[
                    "[dict setObject: [NSNull null] forKey: @\"" + param + "\" ];"
                    ]
                })
                ]}
        }
    }
}
