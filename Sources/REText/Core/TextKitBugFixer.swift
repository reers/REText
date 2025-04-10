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

extension NSAttributedString.Key {
    static let originalFont = NSAttributedString.Key("NSOriginalFont")
}

/// Here solve the wrong line height problem of TextKit when have a mix
/// layout of multi-languages like Chinese, English and emoji. This will
/// have the same appearance with UILabel.
///
/// The cause of wrong line height is from the differeces between fonts.
/// For a mix text of Chinese and English with system defalut font, the
/// Chinese will use `Pingfang SC` actucly and English with `SF UI`.
final class TextKitBugFixer: NSObject, NSLayoutManagerDelegate, @unchecked Sendable {

    static let shared = TextKitBugFixer()

    private override init() {
        super.init()
    }


    func layoutManager(
        _ layoutManager: NSLayoutManager,
        shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>,
        lineFragmentUsedRect: UnsafeMutablePointer<CGRect>,
        baselineOffset: UnsafeMutablePointer<CGFloat>,
        in textContainer: NSTextContainer,
        forGlyphRange glyphRange: NSRange
    ) -> Bool {
        /**
         From apple's doc:
         https://developer.apple.com/library/content/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/CustomTextProcessing/CustomTextProcessing.html
         In addition to returning the line fragment rectangle itself, the layout manager returns a rectangle called the used rectangle. This is the portion of the line fragment rectangle that actually contains glyphs or other marks to be drawn. By convention, both rectangles include the line fragment padding and the interline space (which is calculated from the font’s line height metrics and the paragraph’s line spacing parameters). However, the paragraph spacing (before and after) and any space added around the text, such as that caused by center-spaced text, are included only in the line fragment rectangle, and are not included in the used rectangle.

         Althought the doc said usedRect should container lineSpacing,
         we don't add the lineSpacing to usedRect to avoid the case that
         last sentance have a extra lineSpacing pading.
         */
        
        guard let textStorage = layoutManager.textStorage else {
            return false
        }

        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        var maximumLineHeightFont: UIFont? = nil
        var maximumLineHeight: CGFloat = 0
        var maximumLineSpacing: CGFloat = 0
        var paragraphStyle: NSParagraphStyle? = nil

        textStorage.enumerateAttributes(in: characterRange, options: []) { attrs, range, _ in
            let font = attrs[.originalFont] as? UIFont ?? attrs[.font] as? UIFont

            if paragraphStyle == nil {
                paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle
            }

            guard let font else { return }

            let lineHeight = self.lineHeight(for: font, style: paragraphStyle)
            if lineHeight > maximumLineHeight {
                maximumLineHeightFont = font
                maximumLineHeight = lineHeight
            }

            let lineSpacing = paragraphStyle?.lineSpacing ?? 0
            if lineSpacing > maximumLineSpacing {
                maximumLineSpacing = lineSpacing
            }
        }

        let currentParagraphStyle = paragraphStyle ?? NSParagraphStyle.default

        var paragraphSpacingBefore: CGFloat = 0
        if glyphRange.location > 0, !currentParagraphStyle.paragraphSpacingBefore.isZero {
            let lastLineEndRange = NSRange(location: glyphRange.location - 1, length: 1)
            let charaterRange = layoutManager.characterRange(forGlyphRange: lastLineEndRange, actualGlyphRange: nil)
            if NSMaxRange(charaterRange) <= textStorage.length {
                 let attributedString = textStorage.attributedSubstring(from: charaterRange)
                 if attributedString.string == "\n" {
                     paragraphSpacingBefore = currentParagraphStyle.paragraphSpacingBefore
                 }
            }
        }

        var paragraphSpacing: CGFloat = 0
        if !currentParagraphStyle.paragraphSpacing.isZero {
            let lastGlyphRange = NSRange(location: NSMaxRange(glyphRange) - 1, length: 1)
             if lastGlyphRange.location < NSMaxRange(glyphRange) {
                let lastCharRange = layoutManager.characterRange(forGlyphRange: lastGlyphRange, actualGlyphRange: nil)
                 if NSMaxRange(lastCharRange) <= textStorage.length {
                    let lastCharSubstring = textStorage.attributedSubstring(from: lastCharRange)
                    if lastCharSubstring.string == "\n" {
                        paragraphSpacing = currentParagraphStyle.paragraphSpacing
                    }
                }
            }
        }

        var rect = lineFragmentRect.pointee
        var usedRect = lineFragmentUsedRect.pointee

        let usedHeight = max(maximumLineHeight, usedRect.size.height)

        if paragraphSpacingBefore < -.ulpOfOne {
            rect.origin.y += paragraphSpacingBefore
            rect.size.height = usedHeight + maximumLineSpacing + paragraphSpacing
        } else {
            rect.size.height = paragraphSpacingBefore + usedHeight + maximumLineSpacing + paragraphSpacing
        }

        usedRect.size.height = usedHeight

        lineFragmentRect.pointee = rect
        lineFragmentUsedRect.pointee = usedRect
        // When an attachment is included, it is wrong.
//      baselineOffset.pointee = maximumParagraphSpacingBefore + maximumLineHeight + maximumLineHeightFont.descender

        /// From apple's doc:
        /// YES if you modified the layout information and want your modifications to be used or NO if the original layout information should be used.
        /// But actually returning NO is also used. : )
        /// We should do this to solve the problem of exclusionPaths not working.
        return false
    }

    /// Implementing this method with a return value 0 will solve the problem of last line disappearing
    /// when both maxNumberOfLines and lineSpacing are set, since we didn't include the lineSpacing in
    /// the lineFragmentUsedRect.
    func layoutManager(
        _ layoutManager: NSLayoutManager,
        lineSpacingAfterGlyphAt glyphIndex: Int,
        withProposedLineFragmentRect rect: CGRect
    ) -> CGFloat {
        return 0.0
    }

    private func lineHeight(for font: UIFont, style: NSParagraphStyle?) -> CGFloat {
        var lineHeight = font.lineHeight
        guard let style else { return lineHeight }

        if style.lineHeightMultiple > .ulpOfOne {
            lineHeight *= style.lineHeightMultiple
        }
        if style.minimumLineHeight > .ulpOfOne {
            lineHeight = max(style.minimumLineHeight, lineHeight)
        }
        if style.maximumLineHeight > .ulpOfOne {
            lineHeight = min(style.maximumLineHeight, lineHeight)
        }
        return lineHeight
    }
}
