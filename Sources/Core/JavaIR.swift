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
    case custom(_ annotation: String)

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
        case let .custom(annotation):
            return annotation
        }
    }
}

enum JavaNullabilityAnnotationType: String {
    case androidSupport = "android-support"
    case androidx

    var package: String {
        switch self {
        case .androidSupport:
            return "android.support.annotation"
        case .androidx:
            return "androidx.annotation"
        }
    }
}

//
// The json file passed in via java_annotations=custom_annotations.json is deserialized into this.
//
struct JavaCustomAnnotations: Codable {
    var `class`: [String] { return internalClass ?? [] }
    var constructor: [String] { return internalConstructor ?? [] }
    var properties: [String: [String: [String]]] { return internalProperties ?? [:] }
    var methods: [String: [String]] { return internalMethods ?? [:] }
    var imports: [String] { return internalImports ?? [] }

    private var internalClass: [String]?
    private var internalConstructor: [String]?
    private var internalProperties: [String: [String: [String]]]?
    private var internalMethods: [String: [String]]?
    private var internalImports: [String]?

    enum CodingKeys: String, CodingKey {
        case internalClass = "class"
        case internalConstructor = "constructor"
        case internalProperties = "properties"
        case internalMethods = "methods"
        case internalImports = "imports"
    }

    func forClass() -> Set<JavaAnnotation> {
        return Set(`class`.map { annotationString in
            JavaAnnotation.custom(annotationString)
        })
    }

    func forConstructor() -> Set<JavaAnnotation> {
        return Set(constructor.map { annotationString in
            JavaAnnotation.custom(annotationString)
        })
    }

    func forPropertyVariable(_ property: String) -> Set<JavaAnnotation> {
        guard let propertyObj = properties[property] else {
            return []
        }
        guard let propertyVariableAnnotations = propertyObj["variable"] else {
            return []
        }
        return Set(propertyVariableAnnotations.map { annotationString in
            JavaAnnotation.custom(annotationString)
        })
    }

    func forPropertyGetter(_ property: String) -> Set<JavaAnnotation> {
        guard let propertyObj = properties[property] else {
            return []
        }
        guard let propertyGetterAnnotations = propertyObj["getter"] else {
            return []
        }
        return Set(propertyGetterAnnotations.map { annotationString in
            JavaAnnotation.custom(annotationString)
        })
    }

    func forMethod(_ method: String) -> Set<JavaAnnotation> {
        guard let methodAnnotations = methods[method] else {
            return []
        }
        return Set(methodAnnotations.map { annotationString in
            JavaAnnotation.custom(annotationString)
        })
    }
}

extension Schema {
    var isJavaCollection: Bool {
        switch self {
        case .array, .map, .set:
            return true
        default:
            return false
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
                return annotationLines + ["\(modifiers.render()) \(signature)\(throwsString);"].map { $0.trimmingCharacters(in: .whitespaces) }
            }

            var toRender = annotationLines + ["\(modifiers.render()) \(signature)\(throwsString) {"].map { $0.trimmingCharacters(in: .whitespaces) }
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

    static func whileBlock(condition: String, body: () -> [String]) -> String {
        return [
            "while (" + condition + ") {",
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
                    .map { ($0.description, $0.defaultValue) }
                    .map { "\($0.0.uppercased())(\($0.1))" }.joined(separator: ", \n")
                let enumInitializer = JavaIR.method([], "\(name)(int value)") { [
                    "this.value = value;",
                ] }

                let getterMethod = JavaIR.method([.public], "int getValue()") { [
                    "return this.value;",
                ] }
                return [
                    "public enum \(name) {",
                    -->["\(names);", "private final int value;"],
                    -->enumInitializer.render(),
                    -->getterMethod.render(),
                    "}",
                ]
            case let .string(values, defaultValue: _):
                let names = values
                    .map { ($0.description, $0.defaultValue) }
                    .map { "@\(JavaAnnotation.serializedName(name: "\($0.1)").rendered) \($0.0.uppercased())" }.joined(separator: ", ")

                return [
                    "public enum \(name) {",
                    -->["\(names);"],
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
