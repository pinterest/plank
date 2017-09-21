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
        let props = self.properties.map { (param, schemaObj) -> String in
            ObjCIR.ifStmt("_"+"\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className))") {
                [renderAddObjectStatement(param, schemaObj.schema, dictionary)]
            }
        }.joined(separator: "\n")
        return ObjCIR.method("- (NSDictionary *)dictionaryRepresentation") {[
            "NSMutableDictionary *\(dictionary) = " +
                (self.isBaseClass ? "[[NSMutableDictionary alloc] initWithCapacity:\(self.properties.count)];" :
                    "[[super dictionaryRepresentation] mutableCopy];"),
            props,
            "return \(dictionary);"
        ]}
    }
}

extension ObjCFileRenderer {
    fileprivate func renderAddObjectStatement(_ param: String, _ schema: Schema, _ dictionary: String, counter: Int = 0) -> String {
        var propIVarName = "_\(param.snakeCaseToPropertyName())"
        switch schema {
        // TODO: After nullability PR landed we should revisit this and don't check for nil if
        //       the ivar is nonnull in all of this cases
        case .boolean, .float, .integer:
            return "[\(dictionary) setObject:@(\(propIVarName)) forKey: @\"\(param)\" ];"
        case .object:
            return
                ObjCIR.ifElseStmt("\(propIVarName) != nil") {[
                    "[\(dictionary) setObject:[\(propIVarName) dictionaryRepresentation] forKey:@\"\(param)\"];"
                ]} {[
                    "[\(dictionary) setObject:[NSNull null] forKey:@\"\(param)\"];"
                ]}
        case .string(format: .none),
             .string(format: .some(.email)),
             .string(format: .some(.hostname)),
             .string(format: .some(.ipv4)),
             .string(format: .some(.ipv6)):
            return
                ObjCIR.ifElseStmt("\(propIVarName) != nil") {[
                    "[\(dictionary) setObject:\(propIVarName) forKey:@\"\(param)\"];"
                ]} {[
                    "[\(dictionary) setObject:[NSNull null] forKey:@\"\(param)\"];"
                ]}
        case .string(format: .some(.uri)):
            return
                ObjCIR.ifElseStmt("\(propIVarName) != nil") {[
                    "[\(dictionary) setObject:[\(propIVarName) absoluteString] forKey:@\"\(param)\"];"
                ]} {[
                    "[\(dictionary) setObject:[NSNull null] forKey:@\"\(param)\"];"
                ]}
        case .string(format: .some(.dateTime)):
            return
                ObjCIR.ifElseStmt("\(propIVarName) != nil && [NSValueTransformer allowsReverseTransformation]") {[
                    "[\(dictionary) setObject:[[NSValueTransformer valueTransformerForName:\(dateValueTransformerKey)] reverseTransformedValue:\(propIVarName)] forKey:@\"\(param)\"];"
                ]} {[
                    "[\(dictionary) setObject:[NSNull null] forKey:@\"\(param)\"];"
                ]}
        case .enumT(.integer):
            return "[\(dictionary) setObject:@(\(propIVarName)) forKey:@\"\(param)\"];"
        case .enumT(.string):
            return "[\(dictionary) setObject:"+enumToStringMethodName(propertyName: param, className: self.className) + "(\(propIVarName))" + " forKey:@\"\(param)\"];"
        case .array(itemType: let itemType?):
            func createArray(destArray: String, processObject: String, arraySchema: Schema, arrayCounter: Int = 0) -> String {
                switch arraySchema {
                case .reference, .object:
                    return "[\(destArray) addObject:[\(processObject) dictionaryRepresentation]];"
                case .array(itemType: let type):
                    let currentResult = "result\(arrayCounter)"
                    let parentResult = "result\(arrayCounter-1)"
                    let currentObj = "obj\(arrayCounter)"
                    return [
                        "NSArray *items\(arrayCounter) = \(processObject);",
                        "NSMutableArray *\(currentResult) = [NSMutableArray arrayWithCapacity:items\(arrayCounter).count];",
                        ObjCIR.forStmt("id \(currentObj) in items\(arrayCounter)") { [
                            ObjCIR.ifStmt("\(currentObj) != (id)kCFNull") { [
                                createArray(destArray: currentResult, processObject: currentObj, arraySchema: type!, arrayCounter: arrayCounter+1)
                                ]}
                            ]},
                        "[\(parentResult) addObject:\(currentResult)];"
                    ].joined(separator: "\n")
                case .map(valueType: .none):
                    return "[\(destArray) addObject:\(processObject)];"
                case .map(valueType: .some(let valueType)):
                    return self.renderAddObjectStatement(processObject, valueType, processObject)
                case .integer, .float, .boolean:
                    return "[\(destArray) addObject:@(\(processObject))] ];"
                case .string(format: .none),
                     .string(format: .some(.email)),
                     .string(format: .some(.hostname)),
                     .string(format: .some(.ipv4)),
                     .string(format: .some(.ipv6)):
                    return "[\(destArray) addObject:\(processObject) ];"
                case .string(format: .some(.uri)):
                    return "[\(destArray) addObject:[\(processObject) absoluteString] ];"
                case .string(format: .some(.dateTime)):
                    return
                        ObjCIR.ifElseStmt("\(propIVarName) != nil && [NSValueTransformer allowsReverseTransformation]") {[
                            "[\(destArray) addObject: [[NSValueTransformer valueTransformerForName:\(dateValueTransformerKey)] reverseTransformedValue:\(propIVarName)]];"
                        ]} {[
                            "[\(destArray) addObject:[NSNull null]];"
                        ]}
                case .enumT(.integer):
                    return "[\(destArray) addObject:@(\(processObject))];"
                case .enumT(.string):
                    return "[\(destArray) addObject:"+enumToStringMethodName(propertyName: param, className: self.className) + "(\(propIVarName))];"
                default:
                    assert(false, "Array of oneOf is not possible")
                    return ""
                }
            }
            let currentResult = "result\(counter)"
            let currentObj = "obj\(counter)"
                return [
                    "NSArray *items\(counter) = \(propIVarName);",
                    "NSMutableArray *\(currentResult) = [NSMutableArray arrayWithCapacity:items\(counter).count];",
                    ObjCIR.forStmt("id \(currentObj) in items\(counter)") { [
                        ObjCIR.ifStmt("\(currentObj) != (id)kCFNull") { [
                            createArray(destArray: currentResult, processObject: currentObj, arraySchema: itemType, arrayCounter: counter+1)
                        ]}
                    ]},
                    "[\(dictionary) setObject:\(currentResult) forKey:@\"\(param)\"];"
                ].joined(separator: "\n")
        case .map(valueType: .none):
            return
                ObjCIR.ifElseStmt("\(propIVarName) != nil") {[
                    "[\(dictionary) setObject:\(propIVarName) forKey:@\"\(param)\"];"
                ]} {[
                    "[\(dictionary) setObject:[NSNull null] forKey:@\"\(param)\"];"
                ]}
        case .map(valueType: .some(let valueType)):
            switch valueType {
            case .map, .object, .array:
                return
                    ObjCIR.ifElseStmt("\(propIVarName) != nil") {[
                        self.renderAddObjectStatement(param, valueType, dictionary)
                    ]} {[
                        "[\(dictionary) setObject:[NSNull null] forKey:@\"\(param)\"];"
                    ]}
            case .reference(with: _):
                return [
                    "NSMutableDictionary *items\(counter) = [NSMutableDictionary new];",
                    ObjCIR.forStmt("id key in \(propIVarName)") { [
                        ObjCIR.ifStmt("[\(propIVarName) objectForKey:key] != (id)kCFNull") { [
                            "[items\(counter) setObject:[[\(propIVarName) objectForKey:key] dictionaryRepresentation] forKey:key];"
                        ]}
                    ]},
                    "[\(dictionary) setObject:items\(counter) forKey: @\"\(propIVarName)\" ];"
                ].joined(separator: "\n")
            default:
                return
                    ObjCIR.ifElseStmt("\(propIVarName) != nil") {[
                        "[\(dictionary) setObject:\(propIVarName) forKey:@\"\(param)\"];"
                    ]} {[
                        "[\(dictionary) setObject:[NSNull null] forKey:@\"\(param)\"];"
                    ]}
            }
        case .oneOf(types: let avTypes):
            return
                ObjCIR.ifElseStmt("\(propIVarName) != nil") {[
                    ObjCIR.switchStmt("\(propIVarName).internalType") {
                        avTypes.enumerated().map { (_, schema) -> ObjCIR.SwitchCase in
                            return ObjCIR.caseStmt(self.className+propIVarName.snakeCaseToCamelCase()+"InternalType"+ObjCADTRenderer.objectName(schema)) {[
                                    "[\(dictionary) setObject:[\(propIVarName) dictionaryRepresentation] forKey:@\"\(param)\"];"
                                ]}
                        }
                    }
                ]} {[
                    "[\(dictionary) setObject:[NSNull null] forKey:@\"\(param)\"];"
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
