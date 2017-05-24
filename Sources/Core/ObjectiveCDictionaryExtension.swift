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
                return [renderAddObjectStatement(param, schema)]
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
            return "[dict setObject: [NSNumber numberWithFloat:"+propIVarName + "] forKey: @\"" + param + "\" ];"
        case .integer:
            return "[dict setObject: [NSNumber numberWithInteger:"+propIVarName + "] forKey: @\"" + param + "\" ];"
        case .object(_):
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
        case .enumT(.integer(_)):
            return "[dict setObject: [NSNumber numberWithInteger:"+propIVarName + "] forKey: @\"" + param + "\" ];"
        case .enumT(.string(_)):
            return "[dict setObject: "+enumToStringMethodName(propertyName: param, className: self.className) + "(\(propIVarName))" + " forKey: @\"" + param + "\" ];"
        case .array(itemType: _):            
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
            return propIVarName
        case .oneOf(types: _):
            return propIVarName
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

