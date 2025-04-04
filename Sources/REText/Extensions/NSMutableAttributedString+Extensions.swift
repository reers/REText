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
import UIKit

public extension NSMutableAttributedString {
    func setAttribute(_ name: NSAttributedString.Key, value: Any?, range: NSRange) {
        guard name != NSAttributedString.Key(rawValue: "") else { return }
        
        if let value = value, !(value is NSNull) {
            addAttribute(name, value: value, range: range)
        } else {
            removeAttribute(name, range: range)
        }
    }
    
    func setParagraphStyle(_ style: NSParagraphStyle?, range: NSRange) {
        setAttribute(.paragraphStyle, value: style, range: range)
    }
    
    func setAlignment(_ alignment: NSTextAlignment, range: NSRange) {
        applyParagraphStyle(range: range, keyPath: \.alignment, newValue: alignment)
    }
    
    func setBaseWritingDirection(_ baseWritingDirection: NSWritingDirection, range: NSRange) {
        applyParagraphStyle(range: range, keyPath: \.baseWritingDirection, newValue: baseWritingDirection)
    }
    
    func setLineSpacing(_ lineSpacing: CGFloat, range: NSRange) {
        applyParagraphStyle(range: range, keyPath: \.lineSpacing, newValue: lineSpacing)
    }
    
    func setParagraphSpacing(_ paragraphSpacing: CGFloat, range: NSRange) {
        applyParagraphStyle(range: range, keyPath: \.paragraphSpacing, newValue: paragraphSpacing)
    }
    
    func setParagraphSpacingBefore(_ paragraphSpacingBefore: CGFloat, range: NSRange) {
        applyParagraphStyle(range: range, keyPath: \.paragraphSpacingBefore, newValue: paragraphSpacingBefore)
    }
    
    func setFirstLineHeadIndent(_ firstLineHeadIndent: CGFloat, range: NSRange) {
        applyParagraphStyle(range: range, keyPath: \.firstLineHeadIndent, newValue: firstLineHeadIndent)
    }
    
    func setHeadIndent(_ headIndent: CGFloat, range: NSRange) {
        applyParagraphStyle(range: range, keyPath: \.headIndent, newValue: headIndent)
    }
    
    func setTailIndent(_ tailIndent: CGFloat, range: NSRange) {
        applyParagraphStyle(range: range, keyPath: \.tailIndent, newValue: tailIndent)
    }
    
    func setLineBreakMode(_ lineBreakMode: NSLineBreakMode, range: NSRange) {
        applyParagraphStyle(range: range, keyPath: \.lineBreakMode, newValue: lineBreakMode)
    }
    
    func setMinimumLineHeight(_ minimumLineHeight: CGFloat, range: NSRange) {
        applyParagraphStyle(range: range, keyPath: \.minimumLineHeight, newValue: minimumLineHeight)
    }
    
    func setMaximumLineHeight(_ maximumLineHeight: CGFloat, range: NSRange) {
        applyParagraphStyle(range: range, keyPath: \.maximumLineHeight, newValue: maximumLineHeight)
    }
    
    func setLineHeightMultiple(_ lineHeightMultiple: CGFloat, range: NSRange) {
        applyParagraphStyle(range: range, keyPath: \.lineHeightMultiple, newValue: lineHeightMultiple)
    }
    
    func setHyphenationFactor(_ hyphenationFactor: Float, range: NSRange) {
        applyParagraphStyle(range: range, keyPath: \.hyphenationFactor, newValue: hyphenationFactor)
    }
    
    func setDefaultTabInterval(_ defaultTabInterval: CGFloat, range: NSRange) {
        applyParagraphStyle(range: range, keyPath: \.defaultTabInterval, newValue: defaultTabInterval)
    }
    
    func setTabStops(_ tabStops: [NSTextTab]?, range: NSRange) {
        applyParagraphStyle(range: range, keyPath: \.tabStops, newValue: tabStops)
    }
}

extension NSMutableAttributedString {
    private func applyParagraphStyle<Value: Equatable>(
        range: NSRange,
        keyPath: WritableKeyPath<NSMutableParagraphStyle, Value>,
        newValue: Value
    ) {
        enumerateAttribute(.paragraphStyle, in: range, options: []) { value, subRange, stop in
            var currentStyle = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle
            var style: NSMutableParagraphStyle? = nil
            
            
            if let current = currentStyle,
               CFGetTypeID(current) == CTParagraphStyleGetTypeID(),
               let ctStyle = castToCTParagraphStyle(current) {
                currentStyle = NSMutableParagraphStyle.with(ctStyle: ctStyle)
            }
            
            if let existingStyle = currentStyle {
                if existingStyle[keyPath: keyPath] == newValue {
                    return
                }
                style = existingStyle
            } else {
                let defaultStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                if defaultStyle[keyPath: keyPath] == newValue {
                    return
                }
                style = defaultStyle
            }
            
            guard var mutableStyle = style else {
                print("Error: Failed to obtain a mutable paragraph style instance for range \(subRange).")
                return
            }
            
            mutableStyle[keyPath: keyPath] = newValue
            
            setParagraphStyle(mutableStyle, range: subRange)
        }
    }
}
