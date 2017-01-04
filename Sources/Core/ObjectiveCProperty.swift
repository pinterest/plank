//
//  ObjCProperty.swift
//  PINModel
//
//  Created by Rahul Malik on 7/29/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

let Indentation = "    " // Four space indentation for now. Might be configurable in the future.

public enum ObjCMemoryAssignmentType: String {
    case Copy = "copy"
    case Strong = "strong"
    case Weak = "weak"
    case Assign = "assign"
}

public enum ObjCAtomicityType: String {
    case Atomic = "atomic"
    case NonAtomic = "nonatomic"
}

public enum ObjCMutabilityType: String {
    case ReadOnly = "readonly"
    case ReadWrite = "readwrite"
}


public enum ObjCPrimitiveType: String {
    case Float = "float"
    case Double = "double"
    case Integer = "NSInteger"
    case Boolean = "BOOL"
}

extension String {
    // Objective-C String Literal
    func objcLiteral() -> String {
        return "@\"\(self)\""
    }

    func indent() -> String {
        return Indentation + self
    }
}

extension Sequence {
    func objcLiteral() -> String {
        let inner = self.map { "\($0)" }.joined(separator: ", ")
        return "@[\(inner)]"
    }
}



typealias Argument = String
typealias Parameter = String

func dirtyPropertyOption(propertyName aPropertyName: String, className: String) -> String {
    let propertyName = aPropertyName.snakeCaseToPropertyName()
    let capitalizedFirstLetter = String(propertyName[propertyName.startIndex]).uppercased()
    let capitalizedPropertyName = capitalizedFirstLetter + String(propertyName.characters.dropFirst())
    return className + "DirtyProperty" + capitalizedPropertyName
}

func enumFromStringMethodName(propertyName: String, className: String) -> String {
    return "\(className)\(propertyName.snakeCaseToCamelCase())TypeFromString"
}

func enumToStringMethodName(propertyName: String, className: String) -> String {
    return "\(className)\(propertyName.snakeCaseToCamelCase())TypeToString"
}

func enumTypeName(propertyName: String, className: String) -> String {
    return "\(className)\(propertyName.snakeCaseToCamelCase())Type"
}

extension SchemaObjectRoot {
    func className(with params: GenerationParameters) -> String {
        if let classPrefix = params[GenerationParameterType.classPrefix] as String? {
            return "\(classPrefix)\(self.name.snakeCaseToCamelCase())"
        } else {
            return self.name.snakeCaseToCamelCase()
        }
    }
}

extension Schema {
    var isObjCPrimitiveType: Bool {
        get {
            switch self {
            case .Boolean, .Integer, .Enum(_), .Float:
                return true
            default:
                return false
            }
        }
    }
}

extension EnumValue {
  func objcOptionName(param: String, className: String) -> String {
    return enumTypeName(propertyName: param, className: className) + self.description.snakeCaseToCamelCase()
  }
}

fileprivate func explodeThenIndent(strs: [String]) -> String {
    return strs.flatMap { $0.components(separatedBy: "\n").map{$0.indent()} }.joined(separator: "\n")
}

struct ObjCIR {

    static let ret = "return"

    static func method(_ signature: String, body: () -> [String]) -> ObjCIR.Method {
        return ObjCIR.Method(body: body(), signature: signature)
    }

    static func msg(_ variable: String, _ messages: (Parameter, Argument)...) -> String {
        return
            "[\(variable) " +
                messages.map{ (param, arg) in "\(param):\(arg)" }.joined(separator: " ") +
            "];"
    }

    static func block(_ params: [Parameter], body: () -> [String]) -> String {
        return [
            "^" + (params.count == 0 ? "" : "(\(params.joined(separator: ", ")))") + "{",
                explodeThenIndent(strs: body()),
            "}"
        ].joined(separator: "\n")
    }

    static func ifStmt(_ condition: String, body: () -> [String]) -> String {
        return [
            "if (\(condition)) {",
                explodeThenIndent(strs: body()),
            "}"
        ].joined(separator: "\n")
    }

    static func elseStmt(_ body: () -> [String]) -> String {
        return [
            " else {",
                explodeThenIndent(strs: body()),
            "}"
        ].joined(separator: "\n")
    }

    static func ifElseStmt(_ condition: String, body: @escaping () -> [String]) -> (() -> [String]) -> String {
        return { elseBody in [
            ObjCIR.ifStmt(condition, body: body),
            ObjCIR.elseStmt(elseBody)
        ].joined(separator: "\n") }
    }
    static func forStmt(_ condition: String, body: () -> [String]) -> String {
        return [
            "for (\(condition)) {",
                explodeThenIndent(strs: body()),
            "}"
            ].joined(separator: "\n")
    }
    struct Method {
        let body : [String]
        let signature : String

        func render() -> [String] {
            return [
                signature,
                "{",
                explodeThenIndent(strs: body),
                "}"
            ]
        }
    }

    typealias TypeName = String
    typealias SimpleProperty = (Parameter, TypeName, Schema)

    enum Root {
        case Struct(name: String, fields: [String])
        case Imports(filenames: [String])
        case Category(className: String, categoryName: String?, methods: [ObjCIR.Method],
            properties: [SimpleProperty])
        case Function(method: ObjCIR.Method)
        case Class(
            name: String,
            methods: [ObjCIR.Method],
            properties: [SimpleProperty],
            protocols: [String:[ObjCIR.Method]]
        )

        func renderImplementation() -> [String] {
            switch self {
            case .Struct(name: let name, fields: let fields):
                return [
                    "struct \(name) {",
                    fields.map { Indentation + $0 }.joined(separator: "\n"),
                    "};"
                ]
            case .Imports(filenames: let filenames):
                return [filenames.joined(separator: "\n")]
            case .Class(name: let className, methods: let methods, properties: _, protocols: let protocols):
                return [
                    "@implementation \(className)",
                    methods.flatMap{$0.render()}.joined(separator: "\n"),
                    protocols.flatMap({ (protocolName, methods) -> [String] in
                        return ["#pragma mark - \(protocolName)"] + methods.flatMap{$0.render()}
                    }).joined(separator: "\n"),
                    "@end"
                ]
            case .Category(className: let className, categoryName: let categoryName, methods: let methods, properties: let properties):
                // Only render anonymous categories in the implementation
                guard categoryName == nil else { return [] }
                return [
                    "@interface \(className) ()",
                    properties.map { (param, typeName, schema) in
                        "@property (nonatomic, \(schema.isObjCPrimitiveType ? "assign" : "strong")) \(typeName) \(param.snakeCaseToPropertyName());"
                    }.joined(separator: "\n"),
                    methods.map { $0.signature + ";" }.joined(separator: "\n"),
                    "@end"
                    ].filter{ $0 != "" }
            case .Function(method: let method):
              return method.render()
            }
        }
    }
}


