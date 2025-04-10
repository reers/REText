//
//  Copyright © 2019 meitu.
//  Copyright © 2025 reers.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit
import Foundation
import os.lock

/// The TextDebugTarget protocol defines the method a debug target should implement.
/// A debug target can be added to the global container to receive the shared debug
/// option changed notification.
public protocol TextDebugTarget: AnyObject {

    /// When the shared debug option changes, this method will be called on the main thread.
    /// It should return as quickly as possible. The option's properties should not be changed
    /// in this method.
    ///
    /// - Parameter option: The shared debug option, possibly nil.
    func setDebugOption(_ option: TextDebugOption?)
}

/// The debug option for text rendering.
public class TextDebugOption {

    public var baselineColor: UIColor?
    public var lineFragmentBorderColor: UIColor?
    public var lineFragmentFillColor: UIColor?
    public var lineFragmentUsedBorderColor: UIColor?
    public var lineFragmentUsedFillColor: UIColor?
    public var glyphBorderColor: UIColor?
    public var glyphFillColor: UIColor?
    
    private nonisolated(unsafe) static let applier: @convention(c) (
        UnsafeRawPointer?, UnsafeMutableRawPointer?
    ) -> Void = { value, _ in
        guard let value = value else { return }
        let target = unsafeBitCast(value, to: TextDebugTarget.self)
        target.setDebugOption(_shared)
    }

    /// Lock for protecting shared state access.
    private nonisolated(unsafe) static var sharedDebugLock = os_unfair_lock()

    /// Stores weak references to the debug targets using NSHashTable.weakObjects().
    /// This replaces the original C implementation's CFMutableSetRef + custom callbacks,
    /// providing safer memory management.
    private nonisolated(unsafe) static let sharedDebugTargets: CFMutableSet = {
        var callbacks: CFSetCallBacks = kCFTypeSetCallBacks
        callbacks.retain = { (_, value: UnsafeRawPointer?) -> UnsafeRawPointer? in
            return value
        }
        callbacks.release = { _, _ in }
        let defaults = CFAllocatorGetDefault()
        return CFSetCreateMutable(CFAllocatorGetDefault().takeUnretainedValue(), 0, &callbacks)
    }()

    /// Internal storage for the shared debug option instance.
    private nonisolated(unsafe) static var _shared: TextDebugOption?

    /// Checks if any debug drawing is needed.
    /// - Returns: `true` if at least one debug color is visible (non-nil). `false` otherwise.
    public func needsDrawDebug() -> Bool {
        return baselineColor != nil
            || lineFragmentBorderColor != nil
            || lineFragmentFillColor != nil
            || lineFragmentUsedBorderColor != nil
            || lineFragmentUsedFillColor != nil
            || glyphBorderColor != nil
            || glyphFillColor != nil
    }

    /// Sets all debug colors to nil.
    public func clear() {
        baselineColor = nil
        lineFragmentBorderColor = nil
        lineFragmentFillColor = nil
        lineFragmentUsedBorderColor = nil
        lineFragmentUsedFillColor = nil
        glyphBorderColor = nil
        glyphFillColor = nil
    }

    /// Adds a debug target.
    ///
    /// When `TextDebugOption.shared = newValue` is called, all added debug targets
    /// will receive the `setDebugOption:` call on the main thread.
    /// It maintains an unowned reference to this target. The target must to removed before deinit.
    ///
    /// - Parameter target: A debug target object conforming to the TextDebugTarget protocol.
    public static func addDebugTarget(_ target: TextDebugTarget) {
        os_unfair_lock_lock(&sharedDebugLock)
        defer { os_unfair_lock_unlock(&sharedDebugLock) }
        let value = Unmanaged.passUnretained(target as AnyObject).toOpaque()
        CFSetAddValue(sharedDebugTargets, value)
    }

    /// Removes a debug target previously added via `addDebugTarget(_:)`.
    ///
    /// - Parameter target: The debug target object to remove.
    public static func removeDebugTarget(_ target: TextDebugTarget) {
        os_unfair_lock_lock(&sharedDebugLock)
        defer { os_unfair_lock_unlock(&sharedDebugLock) }
        let value = Unmanaged.passUnretained(target as AnyObject).toOpaque()
        CFSetRemoveValue(sharedDebugTargets, value)
    }

    /// Gets or sets the shared debug option.
    ///
    /// The get operation is thread-safe.
    /// The set operation must be called on the main thread. When a new option is set
    /// (even `nil`), it updates the internal storage and notifies all added debug targets.
    public static var shared: TextDebugOption? {
        get {
            os_unfair_lock_lock(&sharedDebugLock)
            defer { os_unfair_lock_unlock(&sharedDebugLock) }
            return _shared
        }
        set {
            assert(Thread.isMainThread, "TextDebugOption.shared must be set on the main thread.")

            os_unfair_lock_lock(&sharedDebugLock)
            defer { os_unfair_lock_unlock(&sharedDebugLock) }
            _shared = newValue?.copy()
            CFSetApplyFunction(sharedDebugTargets, applier, nil)
        }
    }
    
    public func copy() -> TextDebugOption {
        let instance = TextDebugOption()
        instance.baselineColor = self.baselineColor
        instance.lineFragmentBorderColor = self.lineFragmentBorderColor
        instance.lineFragmentFillColor = self.lineFragmentFillColor
        instance.lineFragmentUsedBorderColor = self.lineFragmentUsedBorderColor
        instance.lineFragmentUsedFillColor = self.lineFragmentUsedFillColor
        instance.glyphBorderColor = self.glyphBorderColor
        instance.glyphFillColor = self.glyphFillColor
        return instance
    }
}
