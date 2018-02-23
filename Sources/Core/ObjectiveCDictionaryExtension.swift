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
        return ObjCIR.method("- (NSDictionary *)dictionaryObjectRepresentation") {[
            "NSMutableDictionary *\(dictionary) = " +
                (self.isBaseClass ? "[[NSMutableDictionary alloc] initWithCapacity:\(self.properties.count)];" :
                    "[[super dictionaryObjectRepresentation] mutableCopy];"),
            props,
            "return \(dictionary);"
        ]}
    }
}

private enum CollectionClass {
    case array
    case set

    func name() -> String {
        switch self {
        case .array:
            return "NSArray"
        case .set:
            return "NSSet"
        }
    }

    func mutableName() -> String {
        switch self {
        case .array:
            return "NSMutableArray"
        case .set:
            return "NSMutableSet"
        }
    }

    func initializer() -> String {
        switch self {
        case .array:
            return "arrayWithCapacity:"
        case .set:
            return "setWithCapacity:"
        }
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
                    "[\(dictionary) setObject:[\(propIVarName) dictionaryObjectRepresentation] forKey:@\"\(param)\"];"
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
            return [
                "NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:\(dateValueTransformerKey)];",
                ObjCIR.ifElseStmt("\(propIVarName) != nil && [[valueTransformer class] allowsReverseTransformation]") {[
                    "[\(dictionary) setObject:[valueTransformer reverseTransformedValue:\(propIVarName)] forKey:@\"\(param)\"];"
                ]} {[
                    "[\(dictionary) setObject:[NSNull null] forKey:@\"\(param)\"];"
                ]}
            ].joined(separator: "\n")
        case .enumT(.integer):
            return "[\(dictionary) setObject:@(\(propIVarName)) forKey:@\"\(param)\"];"
        case .enumT(.string):
            return "[\(dictionary) setObject:"+enumToStringMethodName(propertyName: param, className: self.className) + "(\(propIVarName))" + " forKey:@\"\(param)\"];"
        case .array(itemType: let itemType?), .set(itemType: let itemType?):
            func collectionClass(schema: Schema) -> CollectionClass {
                if case .array = schema {
                    return .array
                } else {
                    return .set
                }
            }
            func createCollection(destCollection: String, processObject: String, collectionSchema: Schema, collectionCounter: Int = 0) -> String {
                switch collectionSchema {
                case .reference, .object, .oneOf(types: _):
                    return "[\(destCollection) addObject:[\(processObject) dictionaryObjectRepresentation]];"
                case .array(itemType: let type), .set(itemType: let type):
                    let currentResult = "result\(collectionCounter)"
                    let parentResult = "result\(collectionCounter-1)"
                    let currentObj = "obj\(collectionCounter)"
                    let collection = collectionClass(schema: collectionSchema)
                    return [
                        "\(collection.name()) *items\(collectionCounter) = \(processObject);",
                        "\(collection.mutableName()) *\(currentResult) = [\(collection.mutableName()) \(collection.initializer())items\(collectionCounter).count];",
                        ObjCIR.forStmt("id \(currentObj) in items\(collectionCounter)") { [
                            ObjCIR.ifStmt("\(currentObj) != (id)kCFNull") { [
                                createCollection(destCollection: currentResult, processObject: currentObj, collectionSchema: type!, collectionCounter: collectionCounter+1)
                                ]}
                            ]},
                        "[\(parentResult) addObject:\(currentResult)];"
                    ].joined(separator: "\n")
                case .map(valueType: .none):
                    return "[\(destCollection) addObject:\(processObject)];"
                case .map(valueType: .some(let valueType)):
                    return self.renderAddObjectStatement(processObject, valueType, processObject)
                case .integer, .float, .boolean:
                    return "[\(destCollection) addObject:\(processObject)];"
                case .string(format: .none),
                     .string(format: .some(.email)),
                     .string(format: .some(.hostname)),
                     .string(format: .some(.ipv4)),
                     .string(format: .some(.ipv6)):
                    return "[\(destCollection) addObject:\(processObject) ];"
                case .string(format: .some(.uri)):
                    return "[\(destCollection) addObject:[\(processObject) absoluteString] ];"
                case .string(format: .some(.dateTime)):
                    return [
                        ObjCIR.ifElseStmt("\(propIVarName) != nil && [[valueTransformer class] allowsReverseTransformation]") {[
                            "NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:\(dateValueTransformerKey)];",
                            "[\(destCollection) addObject:[valueTransformer reverseTransformedValue:\(propIVarName)]];"
                        ]} {[
                            "[\(destCollection) addObject:[NSNull null]];"
                        ]}
                    ].joined(separator: "\n")
                case .enumT(.integer):
                    return "[\(destCollection) addObject:@(\(processObject))];"
                case .enumT(.string):
                    return "[\(destCollection) addObject:"+enumToStringMethodName(propertyName: param, className: self.className) + "(\(propIVarName))];"
                }
            }
            let currentResult = "result\(counter)"
            let currentObj = "obj\(counter)"
            let collection = collectionClass(schema: schema)
            return ObjCIR.ifElseStmt("\(propIVarName) != nil") {[
                    "\(collection.name()) *items\(counter) = \(propIVarName);",
                    "\(collection.mutableName()) *\(currentResult) = [\(collection.mutableName()) \(collection.initializer())items\(counter).count];",
                    ObjCIR.forStmt("id \(currentObj) in items\(counter)") { [
                        ObjCIR.ifStmt("\(currentObj) != (id)kCFNull") { [
                            createCollection(destCollection: currentResult, processObject: currentObj, collectionSchema: itemType, collectionCounter: counter+1)
                        ]}
                    ]},
                    "[\(dictionary) setObject:\(currentResult) forKey:@\"\(param)\"];"
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
                            "[items\(counter) setObject:[[\(propIVarName) objectForKey:key] dictionaryObjectRepresentation] forKey:key];"
                        ]}
                    ]},
                    "[\(dictionary) setObject:items\(counter) forKey: @\"\(param)\" ];"
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
                                    "[\(dictionary) setObject:[\(propIVarName) dictionaryObjectRepresentation] forKey:@\"\(param)\"];"
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
        case .map(valueType: .none), .array(.none), .set(.none):
            return
                ObjCIR.ifElseStmt("\(propIVarName) != nil") {[
                    "[\(dictionary) setObject:\(propIVarName) forKey:@\"\(param)\"];"
                ]} {[
                    "[\(dictionary) setObject:[NSNull null] forKey:@\"\(param)\"];"
                ]}
        }
    }
}
