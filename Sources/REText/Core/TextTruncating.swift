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

protocol TextTruncating {
    
    /// A truncater object is initialized with the full state of the text. It is a Single Responsibility Object that is
    /// mutative. It configures the state of the TextKit components (layout manager, text container, text storage) to achieve
    /// the intended truncation, then it stores the resulting state for later fetching.
    ///
    /// The truncater may mutate the state of the text storage such that only the drawn string is actually present in the
    /// text storage itself.
    ///
    /// The truncater should not store a strong reference to the context to prevent retain cycles.
    /// - Parameters:
    ///   - truncationAttributedString: The attributed string to be displayed at the truncation position
    ///   - avoidTailTruncationSet: Character set to avoid truncating at the tail
    init(truncationAttributedString: NSAttributedString?, avoidTailTruncationSet: NSCharacterSet?)
    
    /// Actually do the truncation.
    /// - Parameters:
    ///   - layoutManager: The layout manager
    ///   - textStorage: The text storage
    ///   - textContainer: The text container
    /// - Returns: Truncation info object, or nil if no truncation is needed
    func truncate(
        with layoutManager: TextLayoutManager,
        textStorage: NSTextStorage,
        textContainer: NSTextContainer
    ) -> TextTruncationInfo?
}
