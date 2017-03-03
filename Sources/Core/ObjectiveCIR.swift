//
//  ObjectiveCIR.swift
//  Plank
//
//  Created by Rahul Malik on 7/29/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

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
        return "    "  + self // Four space indentation for now. Might be configurable in the future.
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

typealias TypeName = String
typealias SimpleProperty = (Parameter, TypeName, Schema, ObjCMutabilityType)

func dirtyPropertyOption(propertyName aPropertyName: String, className: String) -> String {
    let propertyName = aPropertyName.snakeCaseToPropertyName()
    let capitalizedFirstLetter = String(propertyName[propertyName.startIndex]).uppercased()
    let capitalizedPropertyName = capitalizedFirstLetter + String(propertyName.characters.dropFirst())
    return className + "DirtyProperty" + capitalizedPropertyName
}

func enumFromStringMethodName(propertyName: String, className: String) -> String {
    return "\(enumTypeName(propertyName: propertyName, className: className))FromString"
}

func enumToStringMethodName(propertyName: String, className: String) -> String {
    return "\(enumTypeName(propertyName: propertyName, className: className))ToString"
}

func enumTypeName(propertyName: String, className: String) -> String {
    let typeName = "\(className)\(propertyName.snakeCaseToCamelCase())"
    if typeName.hasSuffix("Type") {
        return typeName
    } else {
        return typeName + "Type"
    }
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
        switch self {
        case .Boolean, .Integer, .Enum(_), .Float:
            return true
        default:
            return false
        }
    }

    func memoryAssignmentType() -> ObjCMemoryAssignmentType {
        switch self {
        case .String(format: .none):
            return .Copy
        case .Boolean, .Float, .Integer, .Enum(_):
            return .Assign
        default:
            return .Strong
        }
    }
}

extension EnumValue {
  func objcOptionName(param: String, className: String) -> String {
    return enumTypeName(propertyName: param, className: className) + self.description
  }
}

enum MethodVisibility: Equatable {
    case Public
    case Private
}

func == (lhs: MethodVisibility, rhs: MethodVisibility) -> Bool {
    switch (lhs, rhs) {
    case (.Public, .Public): return true
    case (.Private, .Private): return true
    case (_, _): return false
    }
}

prefix operator -->

prefix func --> (strs: [String]) -> String {
  return strs.flatMap { $0.components(separatedBy: "\n").map {$0.indent() } }
    .joined(separator: "\n")
}

prefix func --> (body: () -> [String]) -> String {
  return -->body()
}

public struct ObjCIR {

    static let ret = "return"

    static func method(_ signature: String, body: () -> [String]) -> ObjCIR.Method {
        return ObjCIR.Method(body: body(), signature: signature)
    }

    static func stmt(_ body: String) -> String {
        return "\(body);"
    }

    static func msg(_ variable: String, _ messages: (Parameter, Argument)...) -> String {
        return
            "[\(variable) " +
                messages.map { (param, arg) in "\(param):\(arg)" }.joined(separator: " ") +
            "]"
    }

    static func block(_ params: [Parameter], body: () -> [String]) -> String {
        return [
            "^" + (params.count == 0 ? "" : "(\(params.joined(separator: ", ")))") + "{",
              -->body,
            "}"
        ].joined(separator: "\n")
    }

    enum SwitchCase {
        case Case(condition: String, body: () -> [String])
        case Default(body: () -> [String])

        func render() -> String {
            switch self {
            case .Case(let condition, let body):
                return [ "case \(condition):",
                    -->body,
                    -->[ObjCIR.stmt("break")]
                ].joined(separator: "\n")
            case .Default(let body):
                return [ "default:",
                    -->body,
                    -->[ObjCIR.stmt("break")]
                ].joined(separator: "\n")
            }
        }
    }

    static func caseStmt(_ condition: String, body: @escaping () -> [String]) -> SwitchCase {
        return .Case(condition: condition, body: body)
    }

    static func defaultCaseStmt(body: @escaping () -> [String]) -> SwitchCase {
        return .Default(body: body)
    }

    static func switchStmt(_ switchVariable: String, body: () -> [SwitchCase]) -> String {
        return [
            "switch (\(switchVariable)) {",
            body().map { $0.render() }.joined(separator: "\n"),
            "}"
        ].joined(separator: "\n")
    }
    static func ifStmt(_ condition: String, body: () -> [String]) -> String {
        return [
            "if (\(condition)) {",
                -->body,
            "}"
        ].joined(separator: "\n")
    }

    static func elseStmt(_ body: () -> [String]) -> String {
        return [
            " else {",
                -->body,
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
              -->body,
            "}"
            ].joined(separator: "\n")
    }

    static func fileImportStmt(_ filename: String) -> String {
        return "#import \"\(filename).h\""
    }

    static func enumStmt(_ enumName: String, body: () -> [String]) -> String {
        return [
            "typedef NS_ENUM(NSInteger, \(enumName)) {",
              -->[body().joined(separator: ",\n")],
            "};"
        ].joined(separator: "\n")
    }

    public struct Method {
        let body: [String]
        let signature: String

        func render() -> [String] {
            return [
                signature,
                "{",
                  -->body,
                "}"
            ]
        }
    }

    enum Root {
        case Struct(name: String, fields: [String])
        case Imports(classNames: Set<String>, myName: String, parentName: String?)
        case Category(className: String, categoryName: String?, methods: [ObjCIR.Method],
            properties: [SimpleProperty])
        case Macro(String)
        case Function(ObjCIR.Method)
        case Class(
            name: String,
            extends: String?,
            methods: [(MethodVisibility, ObjCIR.Method)],
            properties: [SimpleProperty],
            protocols: [String:[ObjCIR.Method]]
        )
        case Enum(name: String, values: EnumType)

        func renderHeader() -> [String] {
            switch self {
            case .Struct(_, _):
                // skip structs in header
                return []
            case .Macro(let macro):
                return [macro]
            case .Imports(let classNames, let myName, let parentName):
                return [
                    "#import <Foundation/Foundation.h>",
                    parentName.map(ObjCIR.fileImportStmt) ?? "",
                    "#import \"PINModelRuntime.h\""
                    ].filter { $0 != "" }  + (["\(myName)Builder"] + classNames).sorted().map { "@class \($0);" }
            case .Class(let className, let extends, let methods, let properties, let protocols):
                let protocolList = protocols.keys.sorted().joined(separator: ", ")
                let protocolDeclarations = protocols.count > 0 ? "<\(protocolList)>" : ""
                let superClass = extends ?? "NSObject\(protocolDeclarations)"
                return [
                    "@interface \(className) : \(superClass)",
                    properties.map { (param, typeName, schema, access) in
                        "@property (\(schema.isObjCPrimitiveType ? "" : "nullable, ")nonatomic, \(schema.memoryAssignmentType().rawValue), \(access.rawValue)) \(typeName) \(param.snakeCaseToPropertyName());"
                    }.joined(separator: "\n"),
                    methods.filter { visibility, _ in visibility == .Public }
                            .map { $1 }.map { $0.signature + ";" }.joined(separator: "\n"),
                    "@end"
                ]
            case .Category(className: _, categoryName: _, methods: _, properties: _):
                // skip categories in header
                return []
            case .Function(let method):
                return ["\(method.signature);"]
            case .Enum(let name, let values):
                return [ObjCIR.enumStmt(name) {
                    switch values {
                    case .Integer(let options):
                        return options.map { "\(name + $0.description) = \($0.defaultValue)" }
                    case .String(let options, _):
                        return options.map { "\(name + $0.description) /* \($0.defaultValue) */" }
                    }
                }]
            }
        }

        func renderImplementation() -> [String] {
            switch self {
            case .Struct(name: let name, fields: let fields):
                return [
                    "struct \(name) {",
                        fields.sorted().map { $0.indent() }.joined(separator: "\n"),
                    "};"
                ]
            case .Macro(_):
                // skip macro in impl
                return []
            case .Imports(let classNames, let myName, _):
                return [classNames.union(Set([myName])).sorted().map(ObjCIR.fileImportStmt).joined(separator: "\n")]
            case .Class(name: let className, extends: _, methods: let methods, properties: _, protocols: let protocols):
                return [
                    "@implementation \(className)",
                    methods.flatMap {$1.render()}.joined(separator: "\n"),
                    protocols.flatMap({ (protocolName, methods) -> [String] in
                        return ["#pragma mark - \(protocolName)"] + methods.flatMap {$0.render()}
                    }).joined(separator: "\n"),
                    "@end"
                ].map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }.filter { $0 != "" }
            case .Category(className: let className, categoryName: let categoryName, methods: let methods, properties: let properties):
                // Only render anonymous categories in the implementation
                guard categoryName == nil else { return [] }
                return [
                    "@interface \(className) ()",
                    properties.map { (param, typeName, schema, access) in
                        "@property (nonatomic, \(schema.memoryAssignmentType().rawValue), \(access.rawValue)) \(typeName) \(param.snakeCaseToPropertyName());"
                    }.joined(separator: "\n"),
                    methods.map { $0.signature + ";" }.joined(separator: "\n"),
                    "@end"
                ].map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }.filter { $0 != "" }
            case .Function(let method):
                return method.render()
            case .Enum(_, _):
                return []
            }

        }
    }
}
