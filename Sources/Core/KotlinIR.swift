//
//  KotlinIR.swift
//  Core
//
//  Created by Levi McCallum on 9/3/17.
//

import Foundation

public struct KotlinIR {
    
    enum Root {
        case importDecl(name: String)
        case classDecl(name: String)
        
        func render() -> [String] {
            switch self {
            case let .importDecl(name: name):
                return [ "import \(name)" ]
            case let .classDecl(name: name):
                return [
                    "class \(name)"
                ]
            }
        }
    }
}
