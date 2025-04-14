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

public protocol TextParser: AnyObject {
    
    /// Parse text.
    /// - Parameters:
    ///   - text: The original attributed string. This method may parse the text and
    ///   change the text attributes or content.
    ///   - selectedRange: Current selected range in `text`.
    ///   This method should correct the range if the text content is changed. If there's
    ///   no selected range, this value is nil.
    /// - Returns: If the 'text' is modified in this method, returns `true`, otherwise returns `false`.
    func parseText(_ text: NSMutableAttributedString?, selectedRange: UnsafeMutablePointer<NSRange>?) -> Bool
}
