//
//  ObjCProperty.swift
//  PINModel
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
}

typealias Argument = String
typealias Parameter = String

func dirtyPropertyOption(propertyName: String, className: String) -> String {
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

extension SchemaObjectRoot {
    func className(with params: GenerationParameters) -> String {
        if let classPrefix = params[GenerationParameterType.classPrefix] as String? {
            return "\(classPrefix)\(self.name.snakeCaseToCamelCase())"
        } else {
            return self.name.snakeCaseToCamelCase()
        }
    }
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
            "]"
    }

    static func block(_ params: [Parameter], body: () -> [String]) -> String {
        return [
            "^" + (params.count == 0 ? "" : "(\(params.joined(separator: ", ")))") + "{",
            body().map{ Indentation + $0 }.joined(separator: "\n"),
            "}"
        ].joined(separator: "\n")
    }

    static func ifStmt(_ condition: String, body: () -> [String]) -> String {
        return [
            "if (\(condition)) {",
            body().map{ Indentation + $0 }.joined(separator: "\n"), // helper function?
            "}"
        ].joined(separator: "\n")
    }

    static func forStmt(_ condition: String, body: () -> [String]) -> String {
        return [
            "for (\(condition)) {",
                body().map{ Indentation + $0 }.joined(separator: "\n"), // helper function?
            "}"
            ].joined(separator: "\n")
    }
    struct Method {
        let body : [String]
        let signature : String
    }

    enum Root {
        case Class(name: String, methods: [ObjCIR.Method], properties: [Property])
    }
}
