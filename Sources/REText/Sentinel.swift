//
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

import os.lock
#if canImport(Synchronization)
import Synchronization
#endif

#if canImport(Synchronization)
@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private final class AtomicCounterImpl {
    private let atomicCounter = Atomic<Int64>(0)
    
    func increase() -> Int64 {
        return atomicCounter.add(1, ordering: .relaxed).newValue
    }

    var value: Int64 {
        atomicCounter.load(ordering: .relaxed)
    }
}
#endif

private final class LockCounterImpl {
    private var counter: Int64 = 0
    private var lock = os_unfair_lock()

    func increase() -> Int64 {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        counter += 1
        return counter
    }

    var value: Int64 {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return counter
    }
}

final class Sentinel: @unchecked Sendable {

    #if canImport(Synchronization)
    private let implementation: AnyObject
    #else
    private let implementation: LockCounterImpl
    #endif

    init() {
        #if canImport(Synchronization)
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            self.implementation = AtomicCounterImpl()
        } else {
            self.implementation = LockCounterImpl()
        }
        #else
        self.implementation = LockCounterImpl()
        #endif
    }
    
    @discardableResult
    func increase() -> Int64 {
        #if canImport(Synchronization)
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            return (implementation as! AtomicCounterImpl).increase()
        } else {
            return (implementation as! LockCounterImpl).increase()
        }
        #else
        return implementation.increase()
        #endif
    }

    var value: Int64 {
        #if canImport(Synchronization)
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            return (implementation as! AtomicCounterImpl).value
        } else {
            return (implementation as! LockCounterImpl).value
        }
        #else
        return implementation.value
        #endif
    }
}

