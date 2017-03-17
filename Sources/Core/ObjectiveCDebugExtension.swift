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
        let props = self.properties.map { (param, schema) -> String in
            ObjCIR.ifStmt("props.\(dirtyPropertyOption(propertyName: param, className: self.className))") {
                let ivarName = "_\(param.snakeCaseToPropertyName())"
                return ["[descriptionFields addObject:[\((ivarName + " = ").objcLiteral()) stringByAppendingFormat:\("%@".objcLiteral()), \(renderDebugStatement(param, schema))]];"]
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
        let props = self.properties.map { (param, schema) -> String in
            ObjCIR.ifStmt("self.internalType == \(self.renderInternalEnumTypeCase(name: ObjCADTRenderer.objectName(schema)))") {
                let ivarName = "_\(param.snakeCaseToPropertyName())"
                return ["[descriptionFields addObject:[\((ivarName + " = ").objcLiteral()) stringByAppendingFormat:\("%@".objcLiteral()), \(renderDebugStatement(param, schema))]];"]
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
        case .Enum(.String(_)):
            return enumToStringMethodName(propertyName: param, className: self.className) + "(\(propIVarName))"
        case .Boolean, .Float, .Integer:
            return "@(\(propIVarName))"
        case .Enum(.Integer(_)):
            return "@(\(propIVarName))"
        case .String(format: _):
            return propIVarName
        case .Array(itemType: _):
            return propIVarName
        case .Map(valueType: _):
            return propIVarName
        case .Object(_):
            return propIVarName
        case .OneOf(types: _):
            return propIVarName
        case .Reference(with: let fn):
            switch fn() {
            case .some(.Object(let schemaRoot)):
                return renderDebugStatement(param, .Object(schemaRoot))
            default:
                fatalError("Bad reference found in schema for class: \(self.className)")
            }
        }
    }

}
