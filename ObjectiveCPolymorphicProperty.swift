//
//  ObjectiveCPolymorphicProperty.swift
//  pinmodel
//
//  Created by Rahul Malik on 1/7/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import Foundation


final class ObjectiveCPolymorphicProperty: ObjectiveCProperty {

    var propertyDescriptor: ObjectSchemaPolymorphicProperty
    var className: String
    let properties : [AnyProperty]
    var schemaLoader: SchemaLoader

    required init(descriptor: ObjectSchemaPolymorphicProperty, className: String, schemaLoader: SchemaLoader) {
        self.propertyDescriptor = descriptor
        self.className = className
        self.schemaLoader = schemaLoader
        self.properties = descriptor.oneOf.map { PropertyFactory.propertyForDescriptor($0, className: className, schemaLoader: schemaLoader) }

        assert(self.properties.count > 1, "Polymorphic properties should contain more than one property type.")
        for prop in self.properties {
            assert(prop.isScalarType() == false, "We cannot support decoding scalar types with non-scalar types.")
        }
    }

    func propertyRequiresAssignmentLogic() -> Bool {
        // Double-check this but i'm almost positive we need custom logic for polymorphic properties.
        return true
    }

    func objectiveCStringForJSONType() -> String {
      // Find the last common ancestor of all objects and fallback to NSObject if there isn't one.
      let commonParentElements = NSCountedSet()
      var queue = Array<AnyProperty>()
      queue.appendContentsOf(self.properties)
      while !queue.isEmpty {

        if let prop = queue.popLast() {

          switch prop.propertyDescriptor {

          case let pointerProp as ObjectSchemaPointerProperty:
            let classProp = ObjectiveCClassProperty(descriptor: pointerProp, className: self.className, schemaLoader: self.schemaLoader)

            let classType = prop.objectiveCStringForJSONType()

            commonParentElements.addObject(classType)

            if let parentPointerProp = classProp.resolvedSchema.extends {
              let parentProp = PropertyFactory.propertyForDescriptor(parentPointerProp, className: self.className, schemaLoader: self.schemaLoader)
              queue.append(parentProp)
            }

            if commonParentElements.countForObject(classType) == self.properties.count {
              return "__kindof \(classType)"
            }
          default:
            return "__kindof NSObject" // One of the properties is not a class so fallback to NSObject
          }
        }
      }
      return "__kindof NSObject"
    }

    func renderDecodeWithCoderStatement() -> String {
        var deserializationClasses = Set<String>()
        for prop in self.properties {
            deserializationClasses.insert(prop.objectiveCStringForJSONType())
        }
        let classes = self.classList().map { "[\($0) class]" }
        let classList = classes.joinWithSeparator(", ")
        return "[aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[\(classList)]] forKey:@\"\(self.propertyDescriptor.name)\"]"
    }

    func classList() -> [String] {
        return self.properties.map { $0.objectiveCStringForJSONType() }
    }

    func templatedPropertyAssignmentStatementFromDictionary(assigneeName : String, className : String, dictionaryElementName : String = "value") -> [String] {
        var assignments : [String] = []
        for (idx, element) in self.properties.enumerate() {
            var str = "if ([typeString isEqualToString:@\"\(element.polymorphicTypeIdentifier())\"]) { \(assigneeName) = [\(element.objectiveCStringForJSONType()) modelObjectWithDictionary:\(dictionaryElementName)]; }"
            if idx != 0 {
                str = "else \(str)"
            }
            assignments.append(str)
        }

        if assignments.count == 0 {
            return assignments
        }

        return ["NSString *typeString = \(dictionaryElementName)[@\"type\"];"] + assignments
    }

    func propertyAssignmentStatementFromDictionary(className: String) -> [String] {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()

        return self.templatedPropertyAssignmentStatementFromDictionary("_\(formattedPropName)", className: className)
    }

    func propertyMergeStatementFromDictionary(originVariableString: String, className: String) -> [String] {
        let formattedPropName = self.propertyDescriptor.name.snakeCaseToPropertyName()
        return self.templatedPropertyAssignmentStatementFromDictionary("\(originVariableString).\(formattedPropName)", className: className)
    }
}
