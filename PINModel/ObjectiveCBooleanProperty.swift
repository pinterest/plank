//
//  ObjectiveCBooleanProperty.swift
//  pinmodel
//
//  Created by Rahul Malik on 12/28/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

final class ObjectiveCBooleanProperty: ObjectiveCProperty {

    var propertyDescriptor: ObjectSchemaBooleanProperty
    var className: String

    required init(descriptor: ObjectSchemaBooleanProperty, className: String) {
        self.propertyDescriptor = descriptor
        self.className = className
    }

    func renderEncodeWithCoderStatement() -> String {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        return "[aCoder encodeBool:self.\(formattedPropName) forKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func renderDecodeWithCoderStatement() -> String {
        return "[aDecoder decodeBoolForKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func propertyStatementFromDictionary(propertyVariableString: String, className: String) -> String {
        return "[\(propertyVariableString) boolValue]"
    }

    func propertyAssignmentStatementFromDictionary(className: String) -> [String] {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.propertyDescriptor.name)\")", className: className)
        return ["_\(formattedPropName) = \(shortPropFromDictionary);"]
    }

    func objectiveCStringForJSONType() -> String {
        return ObjCPrimitiveType.Boolean.rawValue
    }

    func propertyMergeStatementFromDictionary(originVariableString: String, className: String) -> [String] {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        let shortPropFromDictionary = self.propertyStatementFromDictionary("valueOrNil(modelDictionary, @\"\(self.propertyDescriptor.name)\")", className: className)
        return ["\(originVariableString).\(formattedPropName) = \(shortPropFromDictionary);"]
    }
}
