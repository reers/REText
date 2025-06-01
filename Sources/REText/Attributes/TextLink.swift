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

extension NSAttributedString.Key {
    public static let textLink = NSAttributedString.Key(rawValue: "RETextLinkAttributeName")
}

/// A class designed to wrap a value intended to be used as the value for an `NSAttributedString` attribute
/// (e.g., a custom `.textLink` key). This class inherits from `NSObject` for Objective-C compatibility
/// and is marked `open` to allow subclassing across modules.
///
/// ⚠️ **Critical Performance Warning:**
/// The value stored within this `TextLink` instance (specifically, the underlying value wrapped by `AnyHashable`)
/// *must* originate from a type that correctly and efficiently implements the `Hashable` protocol
/// (requiring both `hash(into:)` and the `Equatable` protocol's `==`).
///
/// `NSAttributedString` and its mutable counterpart (`NSMutableAttributedString`) rely heavily on a global
/// hash table for managing attributes. If the attribute values (like this `TextLink` instance, which relies on
/// its wrapped `value`) have poor hash distribution or slow equality checks (`==`), it can lead to
/// severe application performance degradation ("grind to a halt").
///
/// Therefore, **avoid using collection types** (like Swift's `Array`, `Dictionary`, `Set`, or
/// Foundation's legacy `NSArray`, `NSDictionary`, `NSSet`) as the underlying value whenever possible.
/// While Swift's standard collections *do* conform to `Hashable` with valid hash functions (unlike their
/// older Foundation counterparts mentioned in the original warning), the *computational cost* of hashing
/// and comparing collections can still be significant, especially for collections with many elements.
/// Frequent hashing and comparison operations performed by `NSAttributedString` on these potentially
/// costly attribute values can still lead to performance bottlenecks.
///
/// **Recommendation:** Prefer using simple types (like `String`, `Int`, `UUID`, `URL`) or small,
/// custom `Hashable` structs/classes with efficient `Hashable` implementations as the underlying value
/// wrapped by `AnyHashable`.
///
/// **Subclassing:** Subclasses that add new stored properties influencing equality *must* override
/// `hash` and `isEqual(_:)` to incorporate the state of these new properties, calling `super` where appropriate,
/// to maintain correctness.
open class TextLink: NSObject {
    
    public var value: AnyHashable?

    /// Initializes a `TextLink` instance
    /// - Parameter value: The `AnyHashable` value to wrap. Ensure the original, underlying
    ///   value comes from a type with an efficient `Hashable` conformance.
    public init(value: AnyHashable? = nil) {
        self.value = value
        super.init()
    }
}

extension TextLink {

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(value)
        return hasher.finalize()
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        if self === object as AnyObject? { return true }
        guard let other = object as? TextLink else { return false }

        return value == other.value
    }
}
