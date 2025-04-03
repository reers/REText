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
