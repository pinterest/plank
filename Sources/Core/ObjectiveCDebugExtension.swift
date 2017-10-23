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
        let props = self.properties.map { (param, prop) -> String in
            ObjCIR.ifStmt("props.\(dirtyPropertyOption(propertyName: param, className: self.className))") {
                let ivarName = "_\(param.snakeCaseToPropertyName())"
                return ["[descriptionFields addObject:[\((ivarName + " = ").objcLiteral()) stringByAppendingFormat:\("%@".objcLiteral()), \(renderDebugStatement(param, prop.schema))]];"]
            }
            }.joined(separator: "\n")

        let printFormat = "\(self.className) = {\\n%@\\n}".objcLiteral()
        return ObjCIR.method("- (NSString *)debugDescription") {[
            "NSArray<NSString *> *parentDebugDescription = [[super debugDescription] componentsSeparatedByString:\("\\n".objcLiteral())];",
            "NSMutableArray *descriptionFields = [NSMutableArray arrayWithCapacity:\(self.properties.count)];",
            "[descriptionFields addObject:parentDebugDescription];",
            self.properties.count > 0 ? "struct \(self.dirtyPropertyOptionName) props = _\(self.dirtyPropertiesIVarName);" : "",
            props,
            "return [NSString stringWithFormat:\(printFormat), debugDescriptionForFields(descriptionFields)];"
            ]}
    }
}

extension ObjCADTRenderer {
    func renderDebugDescription() -> ObjCIR.Method {
        let props = self.properties.map { (param, prop) -> String in
            ObjCIR.ifStmt("self.internalType == \(self.renderInternalEnumTypeCase(name: ObjCADTRenderer.objectName(prop.schema)))") {
                let ivarName = "_\(param.snakeCaseToPropertyName())"
                return ["[descriptionFields addObject:[\((ivarName + " = ").objcLiteral()) stringByAppendingFormat:\("%@".objcLiteral()), \(renderDebugStatement(param, prop.schema))]];"]
            }
        }.joined(separator: "\n")

        let printFormat = "\(self.className) = {\\n%@\\n}".objcLiteral()
        return ObjCIR.method("- (NSString *)debugDescription") {[
            "NSArray<NSString *> *parentDebugDescription = [[super debugDescription] componentsSeparatedByString:\("\\n".objcLiteral())];",
            "NSMutableArray *descriptionFields = [NSMutableArray arrayWithCapacity:\(self.properties.count)];",
            "[descriptionFields addObject:parentDebugDescription];",
            props,
            "return [NSString stringWithFormat:\(printFormat), debugDescriptionForFields(descriptionFields)];"
            ]}
    }
}

extension ObjCFileRenderer {
    fileprivate func renderDebugStatement(_ param: String, _ schema: Schema) -> String {
        let propIVarName = "_\(param.snakeCaseToPropertyName())"
        switch schema {
        case .enumT(.string):
            return enumToStringMethodName(propertyName: param, className: self.className) + "(\(propIVarName))"
        case .boolean, .float, .integer:
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
        case .reference(with: let ref):
            switch ref.force() {
            case .some(.object(let schemaRoot)):
                return renderDebugStatement(param, .object(schemaRoot))
            default:
                fatalError("Bad reference found in schema for class: \(self.className)")
            }
        }
    }

}
