//
//  ObjectiveCDebugExtension.swift
//  plank
//
//  Created by Rahul Malik on 2/28/17.
//
//

import Foundation

extension ObjCModelRenderer {
    func renderDebugDescription() -> ObjCIR.Method {
        let props = properties.filter { (_, schema) -> Bool in
            !schema.schema.isBoolean()
        }.map { (param, prop) -> String in
            ObjCIR.ifStmt("props.\(dirtyPropertyOption(propertyName: param, className: self.className))") {
                let ivarName = "_\(Languages.objectiveC.snakeCaseToPropertyName(param))"
                return ["[descriptionFields addObject:[NSString stringWithFormat:\("\(ivarName) = %@".objcLiteral()), \(renderDebugStatement(param, prop.schema))]];"]
            }
        }.joined(separator: "\n")

        let boolProps = properties.filter { (_, schema) -> Bool in
            schema.schema.isBoolean()
        }.map { (param, _) -> String in
            ObjCIR.ifStmt("props.\(dirtyPropertyOption(propertyName: param, className: self.className))") {
                let ivarName = "_\(booleanPropertiesIVarName).\(booleanPropertyOption(propertyName: param, className: self.className))"
                return ["[descriptionFields addObject:[NSString stringWithFormat:\("\(ivarName) = %@".objcLiteral()), @(\(ivarName))]];"]
            }
        }

        let printFormat = "\(className) = {\\n%@\\n}".objcLiteral()
        return ObjCIR.method("- (NSString *)debugDescription") { [
            "NSArray<NSString *> *parentDebugDescription = [[super debugDescription] componentsSeparatedByString:\("\\n".objcLiteral())];",
            "NSMutableArray *descriptionFields = [NSMutableArray arrayWithCapacity:\(self.properties.count)];",
            "[descriptionFields addObject:parentDebugDescription];",
            !self.properties.isEmpty ? "struct \(self.dirtyPropertyOptionName) props = _\(self.dirtyPropertiesIVarName);" : "",
            props,
        ] + boolProps + ["return [NSString stringWithFormat:\(printFormat), debugDescriptionForFields(descriptionFields)];"] }
    }
}

extension ObjCADTRenderer {
    func renderDebugDescription() -> ObjCIR.Method {
        let props = properties.map { (param, prop) -> String in
            ObjCIR.ifStmt("self.internalType == \(self.renderInternalEnumTypeCase(name: ObjCADTRenderer.objectName(prop.schema)))") {
                let ivarName = "_\(Languages.objectiveC.snakeCaseToPropertyName(param))"
                return ["[descriptionFields addObject:[NSString stringWithFormat:\("\(ivarName) = %@".objcLiteral()), \(renderDebugStatement(param, prop.schema))]];"]
            }
        }.joined(separator: "\n")

        let printFormat = "\(className) = {\\n%@\\n}".objcLiteral()
        return ObjCIR.method("- (NSString *)debugDescription") { [
            "NSArray<NSString *> *parentDebugDescription = [[super debugDescription] componentsSeparatedByString:\("\\n".objcLiteral())];",
            "NSMutableArray *descriptionFields = [NSMutableArray arrayWithCapacity:\(self.properties.count)];",
            "[descriptionFields addObject:parentDebugDescription];",
            props,
            "return [NSString stringWithFormat:\(printFormat), debugDescriptionForFields(descriptionFields)];",
        ] }
    }
}

extension ObjCFileRenderer {
    fileprivate func renderDebugStatement(_ param: String, _ schema: Schema) -> String {
        let propIVarName = "_\(Languages.objectiveC.snakeCaseToPropertyName(param))"
        switch schema {
        case .enumT(.string):
            return enumToStringMethodName(propertyName: param, className: className) + "(\(propIVarName))"
        case .boolean:
            return "@(_.\(booleanPropertyOption(propertyName: param, className: className)))"
        case .float, .integer:
            return "@(\(propIVarName))"
        case .enumT(.integer):
            return "@(\(propIVarName))"
        case .string(format: _):
            return propIVarName
        case .array(itemType: _):
            return propIVarName
        case .set(itemType: _):
            return propIVarName
        case .map(valueType: _):
            return propIVarName
        case .object:
            return propIVarName
        case .oneOf(types: _):
            return propIVarName
        case let .reference(with: ref):
            switch ref.force() {
            case let .some(.object(schemaRoot)):
                return renderDebugStatement(param, .object(schemaRoot))
            default:
                fatalError("Bad reference found in schema for class: \(className)")
            }
        }
    }
}
