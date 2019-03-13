//
//  JavaIR.swift
//  Core
//
//  Created by Rahul Malik on 1/4/18.
//

import Foundation

struct JavaModifier: OptionSet {
    let rawValue: Int
    static let `public` = JavaModifier(rawValue: 1 << 0)
    static let abstract = JavaModifier(rawValue: 1 << 1)
    static let final = JavaModifier(rawValue: 1 << 2)
    static let `static` = JavaModifier(rawValue: 1 << 3)
    static let `private` = JavaModifier(rawValue: 1 << 4)

    func render() -> String {
        return [
            self.contains(.public) ? "public" : "",
            self.contains(.abstract) ? "abstract" : "",
            self.contains(.static) ? "static" : "",
            self.contains(.final) ? "final" : "",
            self.contains(.private) ? "private" : "",
        ].filter { $0 != "" }.joined(separator: " ")
    }
}

enum JavaAnnotation: Hashable {
    case override
    case nullable
    case nonnull
    case serializedName(name: String)
    
    var rendered: String {
        switch self {
        case .override:
            return "Override"
        case .nullable:
            return "Nullable"
        case .nonnull:
            return "NonNull"
        case let .serializedName(name):
            return "SerializedName(\"\(name)\")"
        }
    }
}

public struct JavaIR {
    public struct Method {
        let annotations: Set<JavaAnnotation>
        let modifiers: JavaModifier
        let body: [String]
        let signature: String
        let throwableExceptions: [String]

        func render() -> [String] {
            // HACK: We should actually have an enum / optionset that we can check for abstract, static, ...
            let annotationLines = annotations.map { "@\($0.rendered)" }

            let throwsString = throwableExceptions.isEmpty ? "" : " throws " + throwableExceptions.joined(separator: ", ")
            
            if modifiers.contains(.abstract) {
                return annotationLines + ["\(modifiers.render()) \(signature)\(throwsString);"]
            }

            var toRender = annotationLines + ["\(modifiers.render()) \(signature)\(throwsString) {"]

            if !body.isEmpty {
                toRender.append(-->body)
            }

            toRender.append("}")
            return toRender
        }
    }

    public struct Property {
        let annotations: Set<JavaAnnotation>
        let modifiers: JavaModifier
        let type: String
        let name: String
        let initialValue: String

        func render() -> String {
            var prop = ""
            if !annotations.isEmpty {
                prop.append(annotations.map { "@\($0.rendered)" }.joined(separator: " ") + " ")
            }
            prop.append("\(modifiers.render()) \(type) \(name)")
            if !initialValue.isEmpty {
                prop.append(" = " + initialValue)
            }
            prop.append(";")
            return prop
        }
    }

    static func method(annotations: Set<JavaAnnotation> = [], _ modifiers: JavaModifier, _ signature: String, body: () -> [String]) -> JavaIR.Method {
        return JavaIR.Method(annotations: annotations, modifiers: modifiers, body: body(), signature: signature, throwableExceptions: [])
    }
    
    static func methodThatThrows(annotations: Set<JavaAnnotation> = [], _ modifiers: JavaModifier, _ signature: String, _ throwableExceptions: [String], body: () -> [String]) -> JavaIR.Method {
        return JavaIR.Method(annotations: annotations, modifiers: modifiers, body: body(), signature: signature, throwableExceptions: throwableExceptions)
    }

    static func ifBlock(condition: String, body: () -> [String]) -> String {
        return [
            "if (" + condition + ") {",
            -->body(),
            "}",
        ].joined(separator: "\n")
    }

    static func forBlock(condition: String, body: () -> [String]) -> String {
        return [
            "for (" + condition + ") {",
            -->body(),
            "}",
        ].joined(separator: "\n")
    }

    static func switchBlock(variableToCheck: String, defaultBody: [String], cases: () -> [Case]) -> String {
        return [
            "switch (" + variableToCheck + ") {",
            -->cases().flatMap { $0.render() },
            -->["default:", -->defaultBody],
            "}",
        ].joined(separator: "\n")
    }

    struct Case {
        let variableEquals: String
        let body: [String]
        let shouldBreak: Bool = true

        func render() -> [String] {
            var lines = [
                "case (" + variableEquals + "):",
                -->body,
            ]
            if shouldBreak {
                lines.append(-->["break;"])
            }
            return lines
        }
    }

    struct Enum {
        let name: String
        let values: EnumType

        func render() -> [String] {
            switch values {
            case let .integer(values):
                let names = values
                    .map { ($0.description.uppercased(), $0.defaultValue) }
                    .map { "int \($0.0) = \($0.1);" }
                let defAnnotationNames = values
                    .map { "\(name).\($0.description.uppercased())" }
                    .joined(separator: ", ")
                return [
                    "@Retention(RetentionPolicy.SOURCE)",
                    "@IntDef({\(defAnnotationNames)})",
                    "public @interface \(name) {",
                    -->names,
                    "}",
                ]
            case let .string(values, defaultValue: _):
                // TODO: Use default value in builder method to specify what our default value should be
                let names = values
                    .map { ($0.description.uppercased(), $0.defaultValue) }
                    .map { "String \($0.0) = \"\($0.1)\";" }
                let defAnnotationNames = values
                    .map { "\(name).\($0.description.uppercased())" }
                    .joined(separator: ", ")
                return [
                    "@Retention(RetentionPolicy.SOURCE)",
                    "@StringDef({\(defAnnotationNames)})",
                    "public @interface \(name) {",
                    -->names,
                    "}",
                ]
            }
        }
    }

    struct Class {
        let annotations: Set<JavaAnnotation>
        let modifiers: JavaModifier
        let extends: String?
        let implements: [String]? // Should this be JavaIR.Interface?
        let name: String
        let methods: [JavaIR.Method]
        let enums: [Enum]
        let innerClasses: [JavaIR.Class]
        let properties: [[JavaIR.Property]]

        func render() -> [String] {
            let implementsList = implements?.joined(separator: ", ") ?? ""
            let implementsStmt = implementsList.isEmpty ? "" : " implements \(implementsList)"

            let extendsStmt = extends.map { " extends \($0) " } ?? ""

            var lines = annotations.map { "@\($0.rendered)" } + [
                "\(modifiers.render()) class \(name)\(extendsStmt)\(implementsStmt) {",
            ]

            if !enums.isEmpty {
                lines.append(-->enums.flatMap { [""] + $0.render() })
            }

            if !properties.isEmpty {
                lines.append(-->properties.flatMap { [""] + $0.compactMap { $0.render() } })
            }

            if !methods.isEmpty {
                lines.append(-->methods.flatMap { [""] + $0.render() })
            }

            if !innerClasses.isEmpty {
                lines.append(-->innerClasses.flatMap { [""] + $0.render() })
            }

            lines.append("}")

            return lines
        }
    }

    struct Interface {
        let modifiers: JavaModifier
        let extends: String?
        let name: String
        let methods: [JavaIR.Method]

        func render() -> [String] {
            let extendsStmt = extends.map { "extends \($0) " } ?? ""
            return [
                "\(modifiers.render()) interface \(name) \(extendsStmt){",
                -->methods.compactMap { "\($0.signature);" },
                "}",
            ]
        }
    }

    enum Root: RootRenderer {
        case packages(names: Set<String>)
        case imports(names: Set<String>)
        case classDecl(aClass: JavaIR.Class)
        case interfaceDecl(aInterface: JavaIR.Interface)

        func renderImplementation() -> [String] {
            switch self {
            case let .packages(names):
                return names.sorted().map { "package \($0);" }
            case let .imports(names):
                return names.sorted().map { "import \($0);" }
            case let .classDecl(aClass: cls):
                return cls.render()
            case let .interfaceDecl(aInterface: interface):
                return interface.render()
            }
        }
    }
}
