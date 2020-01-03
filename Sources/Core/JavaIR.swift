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
    static let transient = JavaModifier(rawValue: 1 << 5)

    // https://checkstyle.sourceforge.io/config_modifier.html#ModifierOrder
    func render() -> String {
        return [
            self.contains(.public) ? "public" : "",
            self.contains(.private) ? "private" : "",
            self.contains(.abstract) ? "abstract" : "",
            self.contains(.static) ? "static" : "",
            self.contains(.final) ? "final" : "",
            self.contains(.transient) ? "transient" : "",
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

enum JavaLoggingType {
    case androidLog(level: String)

    init?(param: String) {
        switch param {
        case "android-log-d": self = .androidLog(level: "d")
        default: fatalError("Unsupported logging type: " + param)
        }
    }

    var imports: [String] {
        switch self {
        case .androidLog: return ["android.util.Log"]
        }
    }
}

enum JavaURIType: String, CaseIterable {
    case androidNetUri = "android.net.Uri"
    case javaNetURI = "java.net.URI"
    case okHttp3HttpUrl = "okhttp3.HttpUrl"
    case string = "String"

    static var options: String {
        return allCases.map { "\"\($0.rawValue)\"" }.joined(separator: ", ")
    }

    var type: String {
        switch self {
        case .androidNetUri: return "Uri"
        case .javaNetURI: return "URI"
        case .okHttp3HttpUrl: return "HttpUrl"
        case .string: return "String"
        }
    }

    var imports: [String] {
        switch self {
        case .string: return []
        default: return [self.rawValue]
        }
    }
}

//
// The json file passed in via java_decorations_beta=model_decorations.json is deserialized into this.
//
struct JavaDecorations: Codable {
    var `class`: ClassDecorations?
    var constructor: MethodDecorations?
    var properties: [String: PropertyDecorations]?
    var methods: [String: MethodDecorations]?
    var variables: [String: VariableDecorations]?
    var imports: [String]?

    func annotationsForClass() -> Set<JavaAnnotation> {
        guard let classDecorations = `class` else {
            return []
        }
        guard let annotations = classDecorations.annotations else {
            return []
        }
        return Set(annotations.map { annotationString in
            JavaAnnotation.custom(annotationString)
        })
    }

    func annotationsForConstructor() -> Set<JavaAnnotation> {
        guard let constructorDecorations = constructor else {
            return []
        }
        guard let annotations = constructorDecorations.annotations else {
            return []
        }
        return Set(annotations.map { annotationString in
            JavaAnnotation.custom(annotationString)
        })
    }

    func annotationsForPropertyVariable(_ property: String) -> Set<JavaAnnotation> {
        guard let propertiesDict = properties else {
            return []
        }
        guard let property = propertiesDict[property] else {
            return []
        }
        guard let variable = property.variable else {
            return []
        }
        guard let annotations = variable.annotations else {
            return []
        }
        return Set(annotations.map { annotationString in
            JavaAnnotation.custom(annotationString)
        })
    }

    func annotationsForPropertyGetter(_ property: String) -> Set<JavaAnnotation> {
        guard let propertiesDict = properties else {
            return []
        }
        guard let property = propertiesDict[property] else {
            return []
        }
        guard let getter = property.getter else {
            return []
        }
        guard let annotations = getter.annotations else {
            return []
        }
        return Set(annotations.map { annotationString in
            JavaAnnotation.custom(annotationString)
        })
    }

    func annotationsForMethod(_ method: String) -> Set<JavaAnnotation> {
        guard let methodsDict = methods else {
            return []
        }
        guard let methodDecorations = methodsDict[method] else {
            return []
        }
        guard let annotations = methodDecorations.annotations else {
            return []
        }
        return Set(annotations.map { annotationString in
            JavaAnnotation.custom(annotationString)
        })
    }

    func annotationsForVariable(_ variable: String) -> Set<JavaAnnotation> {
        guard let variablesDict = variables else {
            return []
        }
        guard let variable = variablesDict[variable] else {
            return []
        }
        guard let annotations = variable.annotations else {
            return []
        }
        return Set(annotations.map { annotationString in
            JavaAnnotation.custom(annotationString)
        })
    }

    struct ClassDecorations: Codable {
        var annotations: [String]?
        var implements: [String]?
        var extends: String?
    }

    struct VariableDecorations: Codable {
        var annotations: [String]?
    }

    struct MethodDecorations: Codable {
        var annotations: [String]?
    }

    struct PropertyDecorations: Codable {
        var variable: VariableDecorations?
        var getter: MethodDecorations?
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
            let annotationLines = annotations.map { "@\($0.rendered)" }.sorted()

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
                prop.append(annotations.map { "@\($0.rendered)" }.sorted().joined(separator: " ") + " ")
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

    static func tryCatch(try: [String], catch: Catch) -> String {
        return [
            "try {",
            -->`try`,
            "} catch (\(`catch`.argument)) {", // TODO: allow for multiple catches
            -->`catch`.body,
            "}",
        ].joined(separator: "\n")
    }

    struct Catch {
        let argument: String
        let body: [String]
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
        let shouldBreak: Bool

        init(variableEquals: String, body: [String], shouldBreak: Bool = true) {
            self.variableEquals = variableEquals
            self.body = body
            self.shouldBreak = shouldBreak
        }

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
                    .map { "@\(JavaAnnotation.serializedName(name: "\($0.1)").rendered) \($0.0.uppercased())(\($0.1))" }.joined(separator: ",\n")
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
        let interfaces: [JavaIR.Interface]
        let properties: [[JavaIR.Property]]

        func render() -> [String] {
            let implementsList = implements?.joined(separator: ", ") ?? ""
            let implementsStmt = implementsList.isEmpty ? "" : " implements \(implementsList)"

            let extendsStmt = extends.map { " extends \($0) " } ?? ""

            var lines = annotations.map { "@\($0.rendered)" }.sorted() + [
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

            if !interfaces.isEmpty {
                lines.append(-->interfaces.flatMap { [""] + $0.render() })
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
