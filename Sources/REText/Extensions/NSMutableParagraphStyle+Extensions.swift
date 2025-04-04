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
import CoreText

public extension NSMutableParagraphStyle {
    
    static func with(ctStyle: CTParagraphStyle) -> NSMutableParagraphStyle {
        let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        
        var lineSpacingAdjustment: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .lineSpacingAdjustment, MemoryLayout<CGFloat>.size, &lineSpacingAdjustment) {
            var maximumLineSpacing: CGFloat = 0
            if CTParagraphStyleGetValueForSpecifier(ctStyle, .maximumLineSpacing, MemoryLayout<CGFloat>.size, &maximumLineSpacing) {
                lineSpacingAdjustment = min(lineSpacingAdjustment, maximumLineSpacing)
            }
            var minimumLineSpacing: CGFloat = 0
            if CTParagraphStyleGetValueForSpecifier(ctStyle, .minimumLineSpacing, MemoryLayout<CGFloat>.size, &minimumLineSpacing) {
                lineSpacingAdjustment = max(lineSpacingAdjustment, minimumLineSpacing)
            }
            style.lineSpacing = lineSpacingAdjustment
        }
        
        var paragraphSpacing: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .paragraphSpacing, MemoryLayout<CGFloat>.size, &paragraphSpacing) {
            style.paragraphSpacing = paragraphSpacing
        }
        
        var alignment: CTTextAlignment = .left
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .alignment, MemoryLayout<CTTextAlignment>.size, &alignment) {
            style.alignment = NSTextAlignment(alignment)
        }
        
        var firstLineHeadIndent: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .firstLineHeadIndent, MemoryLayout<CGFloat>.size, &firstLineHeadIndent) {
            style.firstLineHeadIndent = firstLineHeadIndent
        }
        
        var headIndent: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .headIndent, MemoryLayout<CGFloat>.size, &headIndent) {
            style.headIndent = headIndent
        }
        
        var tailIndent: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .tailIndent, MemoryLayout<CGFloat>.size, &tailIndent) {
            style.tailIndent = tailIndent
        }
        
        var lineBreakMode: CTLineBreakMode = .byWordWrapping
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .lineBreakMode, MemoryLayout<CTLineBreakMode>.size, &lineBreakMode) {
            style.lineBreakMode = NSLineBreakMode(rawValue: Int(lineBreakMode.rawValue)) ?? .byWordWrapping
        }
        
        var minimumLineHeight: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .minimumLineHeight, MemoryLayout<CGFloat>.size, &minimumLineHeight) {
            style.minimumLineHeight = minimumLineHeight
        }
        
        var maximumLineHeight: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .maximumLineHeight, MemoryLayout<CGFloat>.size, &maximumLineHeight) {
            style.maximumLineHeight = maximumLineHeight
        }
        
        var baseWritingDirection: CTWritingDirection = .natural
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .baseWritingDirection, MemoryLayout<CTWritingDirection>.size, &baseWritingDirection) {
            style.baseWritingDirection = NSWritingDirection(rawValue: Int(baseWritingDirection.rawValue)) ?? .natural
        }
        
        var lineHeightMultiple: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .lineHeightMultiple, MemoryLayout<CGFloat>.size, &lineHeightMultiple) {
            style.lineHeightMultiple = lineHeightMultiple
        }
        
        var paragraphSpacingBefore: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .paragraphSpacingBefore, MemoryLayout<CGFloat>.size, &paragraphSpacingBefore) {
            style.paragraphSpacingBefore = paragraphSpacingBefore
        }
        
        var tabStops: CFArray? = nil
        let hasTabs = withUnsafeMutablePointer(to: &tabStops) { cfArrayPtr -> Bool in
            return CTParagraphStyleGetValueForSpecifier(
                ctStyle,
                .tabStops,
                MemoryLayout<CFArray?>.size,
                cfArrayPtr
            )
        }
        if hasTabs, let tabArray = tabStops as? [CTTextTab] {
            style.tabStops = tabArray.map { ctTab in
                let alignment = NSTextAlignment(CTTextTabGetAlignment(ctTab))
                let location = CTTextTabGetLocation(ctTab)
                let options = CTTextTabGetOptions(ctTab) as? [NSTextTab.OptionKey : Any] ?? [:]
                return NSTextTab(textAlignment: alignment, location: location, options: options)
            }
        }
        
        var defaultTabInterval: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(ctStyle, .defaultTabInterval, MemoryLayout<CGFloat>.size, &defaultTabInterval) {
            style.defaultTabInterval = defaultTabInterval
        }
        
        return style
    }
}
