//
//  SwiftIR.swift
//  Core
//
//  Created by Levi McCallum on 9/2/17.
//

import Foundation

public struct SwiftIR {

    enum PropertyType: String {
        case variable = "var"
        case constant = "let"
    }

    enum AccessControl: String {
        case publicDecl = "public"
        case privateDecl = "private"
        case fileprivateDecl = "fileprivate"
    }

    typealias TypeAnnotation = String
    typealias PropertyName = String
    typealias Property = (AccessControl, PropertyType, String, TypeAnnotation)

    typealias EnumCase = (name: String, value: String?)

    enum Root {
        case importDecl(name: String)
        case structDecl(
            access: AccessControl,
            name: String,
            protocols: [String],
            properties: [Property],
            body: [Root]
        )
        case enumDecl(
            access: AccessControl,
            name: String,
            type: String?,
            protocols: [String],
            cases: [EnumCase]
        )
        case extensionDecl(
            type: String,
            protocols: [String],
            body: () -> [String]
        )

        func render() -> [String] {
            switch self {
            case let .importDecl(name: name):
                return [ "import \(name)" ]
            case let .structDecl(access: access, name: name, protocols: protocols, properties: properties, body: body):
                var protos = ""
                if !protocols.isEmpty {
                    protos = ": \(protocols.joined(separator: ", "))"
                }
                return [
                    "\(access) struct \(name)\(protos) {",
                        -->properties.map { property in
                            let (access, type, name, annotation) = property
                            return "\(access) \(type) \(name.snakeCaseToPropertyName()): \(annotation)"
                        },
                        "",
                        -->body.flatMap { $0.render().joined(separator: "\n") },
                    "}"
                ]
            case let .enumDecl(access: access, name: name, type: type, protocols: protocols, cases: cases):
                var protos = ""
                if let type = type {
                    protos += ": \(type)"
                }
                if !protocols.isEmpty {
                    protos += protos.isEmpty ? ": " : ", "
                    protos += protocols.joined(separator: ", ")
                }
                return [
                    "\(access) enum \(name)\(protos) {",
                    -->cases.map {
                        var ret = "case \($0.name.snakeCaseToPropertyName())"
                        if let value = $0.value {
                           ret += " = \(value)"
                        }
                        return ret
                    },
                    "}"
                ]
            case let .extensionDecl(type: type, protocols: protocols, body: body):
                let pro = protocols.joined(separator: ", ")
                return [
                    "extension \(type)\(pro) {",
                    -->body(),
                    "}"
                ]
            }
        }
    }
}

extension SwiftIR.PropertyType: CustomStringConvertible {
    var description: String {
        return rawValue
    }
}

extension SwiftIR.AccessControl: CustomStringConvertible {
    var description: String {
        return rawValue
    }
}
