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

public extension NSAttributedString {
    
    var rangeOfAll: NSRange {
        return NSRange(location: 0, length: length)
    }
    
    func plainText(for range: NSRange) -> String? {
        guard range.location != NSNotFound, range.length > 0 else {
            return nil
        }
        
        var result = ""
        
        enumerateAttribute(
            .backedString,
            in: range,
            options: [.longestEffectiveRangeNotRequired]
        ) { value, attributeRange, _ in
            if let backed = value as? TextBackedString {
                result.append(backed.string)
            } else {
                let nsString = string as NSString
                let startRange = nsString.rangeOfComposedCharacterSequence(at: attributeRange.location)
                let endRange = nsString.rangeOfComposedCharacterSequence(at: NSMaxRange(attributeRange) - 1)
                
                let charRange = NSRange(location: startRange.location, length: NSMaxRange(endRange) - startRange.location)
                result.append(nsString.substring(with: charRange))
            }
        }
        
        return result
    }
}
