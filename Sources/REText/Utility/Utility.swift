//
//  Internal.swift
//  REText
//
//  Created by phoenix on 2025/4/4.
//

import Foundation

@inline(__always)
func syncOnMain<T: Sendable>(_ action: @MainActor () throws -> T) rethrows -> T {
    if pthread_main_np() != 0 {
        return try MainActor.assumeIsolated { try action() }
    } else {
        return try DispatchQueue.main.sync { try action() }
    }
}

@inline(__always)
func objectIsEqual(_ obj: NSObject?, _ otherObj: NSObject?) -> Bool {
    return obj === otherObj || obj?.isEqual(otherObj) == true
}

func arrayIsEqual(_ lhs: [NSObject]?, _ rhs: [NSObject]?) -> Bool {
    if let lhs, let rhs {
        return lhs == rhs
    } else if lhs == nil, rhs == nil {
        return true
    } else {
        return false
    }
}
