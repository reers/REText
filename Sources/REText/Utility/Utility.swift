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
