//
//  ObjectiveCIR.swift
//  Plank
//
//  Created by Rahul Malik on 7/29/15.
//  Copyright © 2015 Rahul Malik. All rights reserved.
//

import Foundation

public enum ObjCMemoryAssignmentType: String {
    case copy
    case strong
    case weak
    case assign
}

public enum ObjCAtomicityType: String {
    case atomic
    case nonatomic
}

public enum ObjCMutabilityType: String {
    case readonly
    case readwrite
}

public enum ObjCPrimitiveType: String {
    case float
    case double
    case integer = "NSInteger"
    case boolean = "BOOL"
}

extension String {
    // Objective-C String Literal
    func objcLiteral() -> String {
        return "@\"\(self)\""
    }
}

extension Sequence {
    func objcLiteral() -> String {
        let inner = map { "\($0)" }.joined(separator: ", ")
        return "@[\(inner)]"
    }
}

typealias Argument = String
typealias Parameter = String

typealias TypeName = String
typealias SimpleProperty = (Parameter, TypeName, SchemaObjectProperty, ObjCMutabilityType)

func propertyOption(propertyName aPropertyName: String, className: String, variant: String) -> String {
    guard !className.isEmpty, !aPropertyName.isEmpty else {
        fatalError("Invalid class name or property name passed propertyOption(propertyName:className:variant)")
    }
    let propertyName = Languages.objectiveC.snakeCaseToPropertyName(aPropertyName)
    let capitalizedFirstLetter = String(propertyName[propertyName.startIndex]).uppercased()
    let capitalizedPropertyName = capitalizedFirstLetter + String(propertyName.dropFirst())
    return className + variant + capitalizedPropertyName
}

func dirtyPropertyOption(propertyName aPropertyName: String, className: String) -> String {
    return propertyOption(propertyName: aPropertyName, className: className, variant: "DirtyProperty")
}

func booleanPropertyOption(propertyName aPropertyName: String, className: String) -> String {
    return propertyOption(propertyName: aPropertyName, className: className, variant: "Boolean")
}

func enumFromStringMethodName(propertyName: String, className: String) -> String {
    return "\(enumTypeName(propertyName: propertyName, className: className))FromString"
}

func enumToStringMethodName(propertyName: String, className: String) -> String {
    return "\(enumTypeName(propertyName: propertyName, className: className))ToString"
}

func enumTypeName(propertyName: String, className: String) -> String {
    return "\(className)\(Languages.objectiveC.snakeCaseToCamelCase(propertyName))"
}

// ObjC integreal types for NS_ENUM declarations in generated code.
enum EnumerationIntegralType: String {
    case char
    case unsignedChar = "unsigned char"
    case short
    case unsignedShort = "unsigned short"
    case int
    case unsignedInt = "unsigned int"
    case NSInteger
    case NSUInteger

    // Return the best fitting and smallest EnumerationIntegralType for the given EnumType.
    // In ObjC not all NS_ENUM declarations need to be NSInteger in size. Using smaller integral types
    // can allow the code that plank generates to use less memory in the resulting application.
    // As an example with an object with 2 enumerations values, each of NSInteger size,
    // those 2 enumerations will take 16 bytes of the objects instance size in the heap. However,
    // if the enumeration storage is smaller, in this case 1 byte long for an unsigned char, the
    // 2 enumerations will only take 8 bytes in the heap. This is because the compiler will best fit
    // the two unsigned char enumerations to fit into the 8 bytes natural alignment of the platform.
    // As more enumerations are found in a class, the better this best fitting code will save memory.
    static func forValue(_ values: EnumType) -> EnumerationIntegralType {
        let minimum: Int
        let maximum: Int
        switch values {
        case let .integer(options):
            let values = options.map { $0.defaultValue }
            minimum = values.min() ?? 0
            maximum = values.max() ?? Int.max
        case let .string(options, _):
            minimum = 0
            maximum = options.count
        }
        let underlyingIntegralType: EnumerationIntegralType
        let (_, overflow) = maximum.subtractingReportingOverflow(minimum)
        if overflow {
            underlyingIntegralType = minimum < 0 ? EnumerationIntegralType.NSInteger : EnumerationIntegralType.NSUInteger
        } else {
            switch max(maximum, abs(maximum - minimum)) {
            case 0 ... Int(UInt8.max):
                underlyingIntegralType = minimum < 0 ? EnumerationIntegralType.char : EnumerationIntegralType.unsignedChar
            case Int(UInt8.max) ... Int(UInt16.max):
                underlyingIntegralType = minimum < 0 ? EnumerationIntegralType.short : EnumerationIntegralType.unsignedShort
            case Int(UInt16.max) ... Int(UInt32.max):
                underlyingIntegralType = minimum < 0 ? EnumerationIntegralType.int : EnumerationIntegralType.unsignedInt
            default:
                underlyingIntegralType = minimum < 0 ? EnumerationIntegralType.NSInteger : EnumerationIntegralType.NSUInteger
            }
        }
        return underlyingIntegralType
    }
}

extension SchemaObjectRoot {
    func className(with params: GenerationParameters) -> String {
        if let classPrefix = params[GenerationParameterType.classPrefix] as String? {
            return "\(classPrefix)\(Languages.objectiveC.snakeCaseToCamelCase(name))"
        } else {
            return Languages.objectiveC.snakeCaseToCamelCase(name)
        }
    }

    func typeName(with params: GenerationParameters) -> String {
        return "\(className(with: params))Type"
    }
}

extension Schema {
    func memoryAssignmentType() -> ObjCMemoryAssignmentType {
        switch self {
        // Use copy for any string, date, url etc.
        case .string:
            return .copy
        case .boolean, .float, .integer, .enumT:
            return .assign
        default:
            return .strong
        }
    }
}

extension EnumValue {
    var camelCaseDescription: String {
        return Languages.objectiveC.snakeCaseToCamelCase(description)
    }

    func objcOptionName(param: String, className: String) -> String {
        return enumTypeName(propertyName: param, className: className) + camelCaseDescription
    }
}

enum MethodVisibility: Equatable {
    case publicM
    case privateM
}

func == (lhs: MethodVisibility, rhs: MethodVisibility) -> Bool {
    switch (lhs, rhs) {
    case (.publicM, .publicM): return true
    case (.privateM, .privateM): return true
    case (_, _): return false
    }
}

public struct ObjCIR {
    static func method(_ signature: String, debug: Bool = false, body: () -> [String]) -> ObjCIR.Method {
        return ObjCIR.Method(body: body(), signature: signature, debug: debug)
    }

    static func stmt(_ body: String) -> String {
        return "\(body);"
    }

    static func msg(_ variable: String, _ messages: (Parameter, Argument)...) -> String {
        return
            "[\(variable) " +
            messages.map { param, arg in "\(param):\(arg)" }.joined(separator: " ") +
            "]"
    }

    static func block(_ params: [Parameter], body: () -> [String]) -> String {
        return [
            "^" + (params.isEmpty ? "" : "(\(params.joined(separator: ", ")))") + "{",
            -->body,
            "}",
        ].joined(separator: "\n")
    }

    static func scope(body: () -> [String]) -> String {
        return [
            "{",
            -->body,
            "}",
        ].joined(separator: "\n")
    }

    enum SwitchCase {
        case caseStmt(condition: String, body: () -> [String])
        case defaultStmt(body: () -> [String])

        func render() -> String {
            switch self {
            case let .caseStmt(condition, body):
                return ["case \(condition):",
                        -->body,
                        -->[ObjCIR.stmt("break")]].joined(separator: "\n")
            case let .defaultStmt(body):
                return ["default:",
                        -->body,
                        -->[ObjCIR.stmt("break")]].joined(separator: "\n")
            }
        }
    }

    static func caseStmt(_ condition: String, body: @escaping () -> [String]) -> SwitchCase {
        return .caseStmt(condition: condition, body: body)
    }

    static func defaultCaseStmt(body: @escaping () -> [String]) -> SwitchCase {
        return .defaultStmt(body: body)
    }

    static func switchStmt(_ switchVariable: String, body: () -> [SwitchCase]) -> String {
        return [
            "switch (\(switchVariable)) {",
            body().map { $0.render() }.joined(separator: "\n"),
            "}",
        ].joined(separator: "\n")
    }

    static func ifStmt(_ condition: String, body: () -> [String]) -> String {
        return [
            "if (\(condition)) {",
            -->body,
            "}",
        ].joined(separator: "\n")
    }

    static func elseIfStmt(_ condition: String, _ body: () -> [String]) -> String {
        return [
            " else if (\(condition)) {",
            -->body,
            "}",
        ].joined(separator: "\n")
    }

    static func elseStmt(_ body: () -> [String]) -> String {
        return [
            " else {",
            -->body,
            "}",
        ].joined(separator: "\n")
    }

    static func ifElseStmt(_ condition: String, body: @escaping () -> [String]) -> (() -> [String]) -> String {
        return { elseBody in [
            ObjCIR.ifStmt(condition, body: body) +
                ObjCIR.elseStmt(elseBody),
        ].joined(separator: "\n") }
    }

    static func forStmt(_ condition: String, body: () -> [String]) -> String {
        return [
            "for (\(condition)) {",
            -->body,
            "}",
        ].joined(separator: "\n")
    }

    static func fileImportStmt(_ filename: String) -> String {
        return "#import \"\(filename).h\""
    }

    static func enumStmt(_ enumName: String, underlyingIntegralType: EnumerationIntegralType, body: () -> [String]) -> String {
        return [
            "typedef NS_ENUM(\(underlyingIntegralType.rawValue), \(enumName)) {",
            -->[body().joined(separator: ",\n")],
            "};",
        ].joined(separator: "\n")
    }

    static func optionEnumStmt(_ enumName: String, body: () -> [String]) -> String {
        return [
            "typedef NS_OPTIONS(NSUInteger, \(enumName)) {",
            -->[body().joined(separator: ",\n")],
            "};",
        ].joined(separator: "\n")
    }

    public struct Method {
        let body: [String]
        let signature: String
        let debug: Bool

        func render() -> [String] {
            let lines = [
                signature,
                "{",
                -->body,
                "}",
            ]
            if debug {
                return ["#if DEBUG"] + lines + ["#endif"]
            }
            return lines
        }
    }

    enum Root: RootRenderer {
        case structDecl(name: String, fields: [String])
        case imports(classNames: Set<String>, myName: String, parentName: String?)
        case category(className: String, categoryName: String?, methods: [ObjCIR.Method],
                      properties: [SimpleProperty],
                      variables: [(Parameter, TypeName)])
        case macro(String)
        case function(ObjCIR.Method)
        case classDecl(
            name: String,
            extends: String?,
            methods: [(MethodVisibility, ObjCIR.Method)],
            properties: [SimpleProperty],
            protocols: [String: [ObjCIR.Method]]
        )
        case enumDecl(name: String, values: EnumType)
        case optionSetEnum(name: String, values: [EnumValue<Int>])

        func renderHeader() -> [String] {
            switch self {
            case .structDecl:
                // skip structs in header
                return []
            case let .macro(macro):
                return [macro]
            case let .imports(classNames, myName, parentName):
                return [
                    "#import <Foundation/Foundation.h>",
                    parentName.map(ObjCIR.fileImportStmt) ?? "",
                    "#import \"\(ObjCRuntimeHeaderFile().fileName)\"",
                ].filter { $0 != "" } + (["\(myName)Builder"] + classNames)
                    .sorted().map { "@class \($0.trimmingCharacters(in: .whitespaces));" }
            case let .classDecl(className, extends, methods, properties, protocols):
                let protocolList = protocols.keys.sorted().joined(separator: ", ")
                let protocolDeclarations = !protocols.isEmpty ? "<\(protocolList)>" : ""
                let superClass = extends ?? "NSObject\(protocolDeclarations)"

                let nullability = { (prop: SchemaObjectProperty) in
                    prop.nullability.map { "\($0), " } ?? ""
                }

                return [
                    "@interface \(className) : \(superClass)",
                    properties.sorted { $0.0 < $1.0 }.map { param, typeName, propSchema, access in
                        "@property (\(nullability(propSchema))nonatomic, \(propSchema.schema.memoryAssignmentType().rawValue), \(access.rawValue)) \(typeName) \(Languages.objectiveC.snakeCaseToPropertyName(param));"
                    }.joined(separator: "\n"),
                    properties.sorted { $0.0 < $1.0 }.filter { param, _, _, _ in
                        param.lowercased().hasPrefix("new_") ||
                            param.lowercased().hasPrefix("alloc_") ||
                            param.lowercased().hasPrefix("copy_") ||
                            param.lowercased().hasPrefix("mutable_copy_")
                    }.map { param, typeName, _, _ in
                        "- (\(typeName))\(Languages.objectiveC.snakeCaseToPropertyName(param)) __attribute__((objc_method_family(none)));"
                    }.joined(separator: "\n"),
                    methods.filter { visibility, _ in visibility == .publicM }
                        .map { $1 }.map { $0.signature + ";" }.joined(separator: "\n"),
                    "@end",
                ]
            case .category(className: _, categoryName: _, methods: _, properties: _, variables: _):
                // skip categories in header
                return []
            case let .function(method):
                return ["\(method.signature);"]
            case let .enumDecl(name, values):
                return [ObjCIR.enumStmt(name, underlyingIntegralType: EnumerationIntegralType.forValue(values)) {
                    switch values {
                    case let .integer(options):
                        return options.map { "\(name + $0.camelCaseDescription) = \($0.defaultValue)" }
                    case .string(let options, _):
                        return options.map { "\(name + $0.camelCaseDescription) /* \($0.defaultValue) */" }
                    }
                }]
            case let .optionSetEnum(name, values):
                return [ObjCIR.optionEnumStmt(name) {
                    values.map { "\(name + $0.camelCaseDescription) = 1 << \($0.defaultValue)" }
                }]
            }
        }

        func renderImplementation() -> [String] {
            switch self {
            case let .structDecl(name: name, fields: fields):
                return [
                    "struct \(name) {",
                    fields.sorted().map { $0.indent() }.joined(separator: "\n"),
                    "};",
                ]
            case .macro:
                // skip macro in impl
                return []
            case .imports(let classNames, let myName, _):
                return [classNames.union(Set([myName]))
                    .sorted()
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .map(ObjCIR.fileImportStmt)
                    .joined(separator: "\n")]
            case .classDecl(name: let className, extends: _, methods: let methods, properties: _, protocols: let protocols):
                return [
                    "@implementation \(className)",
                    methods.flatMap { $1.render() }.joined(separator: "\n"),
                    protocols.sorted { $0.0 < $1.0 }.flatMap { (protocolName, methods) -> [String] in
                        ["#pragma mark - \(protocolName)"] + methods.flatMap { $0.render() }
                    }.joined(separator: "\n"),
                    "@end",
                ].map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }.filter { $0 != "" }
            case let .category(className: className, categoryName: categoryName, methods: methods, properties: properties, variables: variables):
                // Only render anonymous categories in the implementation
                guard categoryName == nil else { return [] }
                let variableDeclarations: String
                if !variables.isEmpty {
                    let vars: [String] = variables.map { (param, typeName) -> String in
                        "\(typeName) _\(Languages.objectiveC.snakeCaseToPropertyName(param));"
                    }
                    variableDeclarations = ["{", -->vars, "}"].joined(separator: "\n")
                } else {
                    variableDeclarations = ""
                }
                return [
                    "@interface \(className) ()",
                    variableDeclarations,
                    properties.map { param, typeName, prop, access in
                        "@property (nonatomic, \(prop.schema.memoryAssignmentType().rawValue), \(access.rawValue)) \(typeName) \(Languages.objectiveC.snakeCaseToPropertyName(param));"
                    }.joined(separator: "\n"),
                    methods.map { $0.signature + ";" }.joined(separator: "\n"),
                    "@end",
                ].map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }.filter { $0 != "" }
            case let .function(method):
                return method.render()
            case .enumDecl:
                return []
            case .optionSetEnum:
                return []
            }
        }
    }
}
