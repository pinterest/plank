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

    enum Root {
        case importDecl(name: String)
        case structDecl(
            access: AccessControl,
            name: String,
            properties: [Property]
        )
        case extensionDecl(
            access: AccessControl,
            type: String,
            protocols: [String]
        )

        func render() -> [String] {
            switch self {
            case let .importDecl(name: name):
                return [ "import \(name)" ]
            case let .structDecl(access: access, name: name, properties: properties):
                return [
                    "\(access) struct \(name) {",
                        -->properties.map { property in
                            let (access, type, name, annotation) = property
                            return "\(access) \(type) \(name.snakeCaseToPropertyName()): \(annotation)"
                        },
                    "}"
                ]
            case let .extensionDecl(access: access, type: type, protocols: protocols):
                let pro = protocols.joined(separator: ", ")
                return [
                    "\(access) extension \(type)\(pro) {",
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
