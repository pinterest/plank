//
//  OptionalExtensions.swift
//  pinmodel
//
//  Created by rmalik on 9/13/16.
//  Copyright © 2016 Rahul Malik. All rights reserved.
//

import Foundation

extension Optional {
    func assertNotNil(defaultValue: Wrapped) -> Wrapped {
        if case let .some(value) = self {
            return value
        } else {
            assertionFailure("Expected optional \(Wrapped.self) to be non-nil. Used default value \(defaultValue).")
            return defaultValue
        }
    }
}
