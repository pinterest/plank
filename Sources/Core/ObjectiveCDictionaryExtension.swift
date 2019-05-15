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

        let props = properties.filter { (_, schema) -> Bool in
            switch schema.schema {
            case .boolean:
                return false
            default:
                return true
            }
        }.map { (param, schemaObj) -> String in
            ObjCIR.ifStmt("_" + "\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className))") { [
                schemaObj.schema.isObjCPrimitiveType ?
                    self.renderAddToDictionaryStatement(.ivar(param), schemaObj.schema, dictionary) :
                    ObjCIR.ifElseStmt("_\(Languages.objectiveC.snakeCaseToPropertyName(param)) != nil") { [
                        self.renderAddToDictionaryStatement(.ivar(param), schemaObj.schema, dictionary),
                    ] } { [
                        "[\(dictionary) setObject:[NSNull null] forKey:@\"\(param)\"];",
                    ] },
            ] }
        }.joined(separator: "\n")

        let boolProps = properties.filter { (_, schema) -> Bool in
            switch schema.schema {
            case .boolean:
                return true
            default:
                return false
            }
        }.map { (param, _) -> String in
            let ivarName = "_\(booleanPropertiesIVarName).\(booleanPropertyOption(propertyName: param, className: self.className))"
            return ObjCIR.ifStmt("_" + "\(self.dirtyPropertiesIVarName).\(dirtyPropertyOption(propertyName: param, className: self.className))") { [
                "[\(dictionary) setObject:@(\(ivarName)) forKey: @\"\(param)\"];",
            ] }
        }

        return ObjCIR.method("- (NSDictionary *)dictionaryObjectRepresentation") { [
            "NSMutableDictionary *\(dictionary) = " +
                (self.isBaseClass ? "[[NSMutableDictionary alloc] initWithCapacity:\(self.properties.count)];" :
                    "[[super dictionaryObjectRepresentation] mutableCopy];"),
            props,
        ] + boolProps + ["return \(dictionary);"] }
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

enum ParamType {
    case ivar(String)
    case localVariable(String)

    func paramVariable() -> String {
        switch self {
        case let .ivar(paramName):
            return "_\(Languages.objectiveC.snakeCaseToPropertyName(paramName))"
        case let .localVariable(paramName)
             :
            return Languages.objectiveC.snakeCaseToPropertyName(paramName)
        }
    }

    func paramName() -> String {
        switch self {
        case let .ivar(paramName):
            return paramName
        case let .localVariable(paramName)
             :
            return paramName
        }
    }
}

extension ObjCFileRenderer {
    func renderAddToDictionaryStatement(_ paramWrapped: ParamType, _ schema: Schema, _ dictionary: String, counter: Int = 0) -> String {
        let param = paramWrapped.paramName()
        let propIVarName = paramWrapped.paramVariable()
        switch schema {
        // TODO: After nullability PR landed we should revisit this and don't check for nil if
        //       the ivar is nonnull in all of this cases
        case .boolean, .float, .integer:
            return "[\(dictionary) setObject:@(\(propIVarName)) forKey: @\"\(param)\"];"
        case .object:
            return "[\(dictionary) setObject:[\(propIVarName) dictionaryObjectRepresentation] forKey:@\"\(param)\"];"
        case .string(format: .none),
             .string(format: .some(.email)),
             .string(format: .some(.hostname)),
             .string(format: .some(.ipv4)),
             .string(format: .some(.ipv6)):
            return "[\(dictionary) setObject:\(propIVarName) forKey:@\"\(param)\"];"
        case .string(format: .some(.uri)):
            return "[\(dictionary) setObject:[\(propIVarName) absoluteString] forKey:@\"\(param)\"];"
        case .string(format: .some(.dateTime)):
            return [
                "NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:\(dateValueTransformerKey)];",
                ObjCIR.ifElseStmt("[[valueTransformer class] allowsReverseTransformation]") { [
                    "[\(dictionary) setObject:[valueTransformer reverseTransformedValue:\(propIVarName)] forKey:@\"\(param)\"];",
                ] } { [
                    "[\(dictionary) setObject:[NSNull null] forKey:@\"\(param)\"];",
                ] },
            ].joined(separator: "\n")
        case .enumT(.integer):
            return "[\(dictionary) setObject:@(\(propIVarName)) forKey:@\"\(param)\"];"
        case .enumT(.string):
            return "[\(dictionary) setObject:" + enumToStringMethodName(propertyName: param, className: className) + "(\(propIVarName))" + " forKey:@\"\(param)\"];"
        case let .array(itemType: itemType?), let .set(itemType: itemType?):
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
                case let .array(itemType: type), let .set(itemType: type):
                    let currentResult = "result\(collectionCounter)"
                    let parentResult = "result\(collectionCounter - 1)"
                    let currentObj = "obj\(collectionCounter)"
                    let collectionItemClass = type.map { typeFromSchema("", $0.nonnullProperty()) } ?? "id"
                    return [
                        "\(collectionClass(schema: collectionSchema).name()) *items\(collectionCounter) = \(processObject);",
                        "\(CollectionClass.array.mutableName()) *\(currentResult) = [\(CollectionClass.array.mutableName()) \(CollectionClass.array.initializer())items\(collectionCounter).count];",
                        ObjCIR.forStmt("\(collectionItemClass) \(currentObj) in items\(collectionCounter)") { [
                            createCollection(destCollection: currentResult, processObject: currentObj, collectionSchema: type!, collectionCounter: collectionCounter + 1),
                        ] },
                        "[\(parentResult) addObject:\(currentResult)];",
                    ].joined(separator: "\n")
                case .map(valueType: .none):
                    return "[\(destCollection) addObject:\(processObject)];"
                case let .map(valueType: .some(type)):
                    let currentResult = "result\(collectionCounter)"
                    let parentResult = "result\(collectionCounter - 1)"
                    let key = "key\(collectionCounter)"
                    return [
                        "\(typeFromSchema("", collectionSchema.nonnullProperty())) items\(collectionCounter) = \(processObject);",
                        "__auto_type \(currentResult) = [NSMutableDictionary new];",
                        ObjCIR.forStmt("NSString *\(key) in items\(collectionCounter)") { [
                            "\(typeFromSchema("", type.nonnullProperty())) tmp\(collectionCounter) = [items\(collectionCounter) objectForKey:\(key)];",
                            "NSMutableDictionary *tmpDict\(collectionCounter) = [NSMutableDictionary new];",
                            self.renderAddToDictionaryStatement(.localVariable("tmp\(collectionCounter)"), type, "tmpDict\(collectionCounter)", counter: collectionCounter + 1),
                            "\(currentResult)[\(key)] = tmpDict\(collectionCounter)[@\"tmp\(collectionCounter)\"];",
                        ] },
                        "[\(parentResult) addObject:\(currentResult)];",
                    ].joined(separator: "\n")
                case .integer, .float, .boolean:
                    return "[\(destCollection) addObject:\(processObject)];"
                case .string(format: .none),
                     .string(format: .some(.email)),
                     .string(format: .some(.hostname)),
                     .string(format: .some(.ipv4)),
                     .string(format: .some(.ipv6)):
                    return "[\(destCollection) addObject:\(processObject)];"
                case .string(format: .some(.uri)):
                    return "[\(destCollection) addObject:[\(processObject) absoluteString]];"
                case .string(format: .some(.dateTime)):
                    return [
                        "NSValueTransformer *valueTransformer = [NSValueTransformer valueTransformerForName:\(dateValueTransformerKey)];",
                        ObjCIR.ifElseStmt("[[valueTransformer class] allowsReverseTransformation]") { [
                            "[\(destCollection) addObject:[valueTransformer reverseTransformedValue:\(propIVarName)]];",
                        ] } { [
                            "[\(destCollection) addObject:[NSNull null]];",
                        ] },
                    ].joined(separator: "\n")
                case .enumT(.integer):
                    return "[\(destCollection) addObject:@(\(processObject))];"
                case .enumT(.string):
                    return "[\(destCollection) addObject:" + enumToStringMethodName(propertyName: param, className: className) + "(\(propIVarName))];"
                }
            }
            let currentResult = "result\(counter)"
            let currentObj = "obj\(counter)"
            let itemClass = itemType.isObjCPrimitiveType ? "id" : typeFromSchema(param, itemType.nonnullProperty())
            return [
                "__auto_type items\(counter) = \(propIVarName);",
                "\(CollectionClass.array.mutableName()) *\(currentResult) = [\(CollectionClass.array.mutableName()) \(CollectionClass.array.initializer())items\(counter).count];",
                ObjCIR.forStmt("\(itemClass) \(currentObj) in items\(counter)") { [
                    createCollection(destCollection: currentResult, processObject: currentObj, collectionSchema: itemType, collectionCounter: counter + 1),
                ] },
                "[\(dictionary) setObject:\(currentResult) forKey:@\"\(param)\"];",
            ].joined(separator: "\n")
        case let .map(valueType: .some(valueType)):

            switch valueType {
            case .map, .array, .reference(with: _), .oneOf(types: _), .object:
                return [
                    "NSMutableDictionary *items\(counter) = [NSMutableDictionary new];",
                    ObjCIR.forStmt("NSString *key\(counter) in \(propIVarName)") { [
                        "__auto_type dictValue\(counter) = \(propIVarName)[key\(counter)];",
                        "NSMutableDictionary *tmp\(counter) = [NSMutableDictionary new];",
                        self.renderAddToDictionaryStatement(.localVariable("dictValue\(counter)"), valueType, "tmp\(counter)", counter: counter + 1),
                        "[items\(counter) setObject:tmp\(counter)[@\"dictValue\(counter)\"] forKey:key\(counter)];",
                    ] },
                    "[\(dictionary) setObject:items\(counter) forKey:@\"\(param)\"];",
                ].joined(separator: "\n")
            default:
                return "[\(dictionary) setObject:\(propIVarName) forKey:@\"\(param)\"];"
            }
        case .oneOf(types: _):
            // oneOf (ADT) types have a dictionaryObjectRepresentation method we will use here
            return "[\(dictionary) setObject:[\(propIVarName) dictionaryObjectRepresentation] forKey:@\"\(param)\"];"
        case let .reference(with: ref):
            return ref.force().map {
                renderAddToDictionaryStatement(paramWrapped, $0, dictionary)
            } ?? {
                assert(false, "TODO: Forward optional across methods")
                return ""
            }()
        case .map(valueType: .none), .array(.none), .set(.none):
            return "[\(dictionary) setObject:\(propIVarName) forKey:@\"\(param)\"];"
        }
    }
}
