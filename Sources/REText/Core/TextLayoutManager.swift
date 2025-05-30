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

enum TextBackgroundType: Int {
    case normal
    case block
}

class TextLayoutManager: NSLayoutManager {

    /// Returns a single bounding rectangle (in container coordinates) enclosing glyph and other marks drawn in the given text container for the given glyph index, not including glyph that draw outside their line fragment rectangles and text attributes such as underlining.
    ///
    /// - Parameter glyphIndex: The index of the glyph for which to return the associated bounding rect.
    /// - Parameter textContainer: The text container in which the glyphs are laid out.
    /// - Returns: The bounding rectangle enclosing the given glyph index.
    func glyphRect(forGlyphIndex glyphIndex: Int, in textContainer: NSTextContainer) -> CGRect {
        let charIndex = self.characterIndexForGlyph(at: glyphIndex)
        let glyph = self.cgGlyph(at: glyphIndex)

        var ctFont: CTFont
        if let storage = self.textStorage, let uiFont = storage.attribute(.font, at: charIndex, effectiveRange: nil) as? UIFont {
            ctFont = uiFont as CTFont
        } else {
            ctFont = UIFont.systemFont(ofSize: REText.CoreTextDefaultFontSize) as CTFont
        }
        //                                    Glyph Advance
        //                             +-------------------------+
        //                             |                         |
        //                             |                         |
        // +------------------------+--|-------------------------|--+-----------+-----+ What TextKit returns sometimes
        // |                        |  |             XXXXXXXXXXX +  |           |     | (approx. correct height, but
        // |               ---------|--+---------+  XXX       XXXX +|-----------|-----|  sometimes inaccurate bounding
        // |               |        |             XXX          XXXXX|           |     |  widths)
        // |               |        |             XX             XX |           |     |
        // |               |        |            XX                 |           |     |
        // |               |        |           XXX                 |           |     |
        // |               |        |           XX                  |           |     |
        // |               |        |      XXXXXXXXXXX              |           |     |
        // |   Cap Height->|        |          XX                   |           |     |
        // |               |        |          XX                   |  Ascent-->|     |
        // |               |        |          XX                   |           |     |
        // |               |        |          XX                   |           |     |
        // |               |        |          X                    |           |     |
        // |               |        |          X                    |           |     |
        // |               |        |          X                    |           |     |
        // |               |        |         XX                    |           |     |
        // |               |        |         X                     |           |     |
        // |               ---------|-------+ X +-------------------------------------|
        // |                        |        XX                     |                 |
        // |                        |        X                      |                 |
        // |                        |      XX         Descent------>|                 |
        // |                        | XXXXXX                        |                 |
        // |                        |  XXX                          |                 |
        // +------------------------+-------------------------------------------------+
        //                                                          |
        //                                                          +--+Actual bounding box
        
        var mutableGlyph = glyph
        let advance = CTFontGetAdvancesForGlyphs(ctFont, .horizontal, &mutableGlyph, nil, 1)
        let ascent = CTFontGetAscent(ctFont)
        let descent = CTFontGetDescent(ctFont)

        /// Textkit's glyphs count not equal CoreText glyphs count, and the CoreText removed glyphs if glyph == 0. It's means the glyph not suitable for font.
        if glyph == 0 && glyphIndex > 0 {
            return self.glyphRect(forGlyphIndex: glyphIndex - 1, in: textContainer)
        }
        
        let glyphRect = self.boundingRect(forGlyphRange: NSMakeRange(glyphIndex, 1), in: textContainer)
        
        /// If it is a NSTextAttachment(glyph == kCGFontIndexInvalid), we don't have the matched glyph and use width of glyphRect instead of advance.
        let lineHeight = (glyph == kCGFontIndexInvalid) ? glyphRect.size.height : ascent + descent
        let location = self.location(forGlyphAt: glyphIndex)
        let lineFragmentRect = self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        let baseline = location.y + lineFragmentRect.minY
        
        var properGlyphRect: CGRect
        /// We are just measuring the line heights here, so we can use the
        /// heights used by TextKit, which tend to be pretty good.
        properGlyphRect = CGRect(
            x: lineFragmentRect.minX + location.x,
            y: (glyph == kCGFontIndexInvalid) ? glyphRect.minY : baseline - ascent,
            width: (glyph == kCGFontIndexInvalid) ? glyphRect.width : advance,
            height: lineHeight
        )
        return properGlyphRect
    }

    /// If the given glyph does not have an explicit location set for it (for example, if it is part of (but not first in) a sequence of nominally spaced characters), the baselineOffset is calculated by glyph advancements from the location of the most recent preceding glyph with a location set.
    /// Glyph baselineOffset are relative to their line fragment rectangle's origin. The line fragment rectangle in turn is defined in the coordinate system of the text container where it resides.
    /// This method causes glyph generation and layout for the line fragment containing the specified glyph, or if noncontiguous layout is not enabled, up to and including that line fragment.
    ///
    /// - Parameter glyphIndex: The glyph index.
    /// - Returns: The baselineOffset for given glyphs range.
    func baselineOffset(forGlyphIndex glyphIndex: Int) -> CGFloat {
        var glyphRange: NSRange = NSMakeRange(0, 0)
        _ = self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &glyphRange)
        return self.baselineOffset(forGlyphRange: glyphRange)
    }

    /// Detect number of lines in text container.
    ///
    /// - Parameter textContainer: The text container which for detecting.
    /// - Returns: The lines counts.
    func numberOfLines(in textContainer: NSTextContainer) -> Int {
        var glyphRangeTotal = NSMakeRange(0, 0)
        var lineRange = NSMakeRange(0, 0)
        var rect: CGRect
        var lastOriginY: CGFloat = -1.0
        var numberOfLines: Int = -1
        
        glyphRangeTotal = self.glyphRange(for: textContainer)
        while lineRange.location < NSMaxRange(glyphRangeTotal) {
            rect = self.lineFragmentRect(forGlyphAt: lineRange.location, effectiveRange: &lineRange)
            if rect.minY > lastOriginY {
                numberOfLines += 1
            }
            lastOriginY = rect.minY
            lineRange.location = NSMaxRange(lineRange)
        }
        
        return numberOfLines
    }

    func backgroundsInfo(forGlyphRange glyphsToShow: NSRange, in textContainer: NSTextContainer) -> [TextBackgroundInfo] {
        var infos: [TextBackgroundInfo] = []
        
        let normalBackgroundsInfo = backgroundsInfo(with: .normal, forGlyphRange: glyphsToShow, in: textContainer)
        let blockBackgroundsInfo = backgroundsInfo(with: .block, forGlyphRange: glyphsToShow, in: textContainer)
        
        /// Rendering order: block > normal
        if !blockBackgroundsInfo.isEmpty {
            infos.append(contentsOf: blockBackgroundsInfo)
        }
        if !normalBackgroundsInfo.isEmpty {
            infos.append(contentsOf: normalBackgroundsInfo)
        }
        
        return infos
    }

    func attachmentsInfo(forGlyphRange glyphsToShow: NSRange, in textContainer: NSTextContainer) -> [TextAttachmentInfo] {
        var infos: [TextAttachmentInfo] = []
        
        guard glyphsToShow.length > 0, let textStorage = self.textStorage else { return infos }
        
        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        textStorage.enumerateAttribute(.attachment, in: characterRange, options: .longestEffectiveRangeNotRequired) { value, range, stop in
            guard let attachment = value as? TextAttachment else {
                return
            }
            
            let glyphRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            var attachmentFrame = self.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            let location = self.location(forGlyphAt: glyphRange.location)
            
            /// location.y is attachment's frame maxY，this behaviors depends on TextKit and MPITextAttachment implementation.
            attachmentFrame.origin.y += location.y
            attachmentFrame.origin.y -= attachment.attachmentSize.height
            attachmentFrame.size.height = attachment.attachmentSize.height
            
            infos.append(TextAttachmentInfo(attachment: attachment, frame: attachmentFrame, characterIndex: UInt(range.location)))
        }
        return infos
    }

    func drawBackground(with backgroundsInfo: [TextBackgroundInfo], at origin: CGPoint) {
        if backgroundsInfo.isEmpty { return }
        
        for info in backgroundsInfo {
            fillBackground(info.background, rectArray: info.rects, at: origin, forCharacterRange: info.characterRanges)
        }
    }

    @MainActor
    func drawImageAttachments(
        with attachmentsInfo: [TextAttachmentInfo],
        at origin: CGPoint,
        in textContainer: NSTextContainer
    ) {
        if attachmentsInfo.isEmpty { return }
        
        for info in attachmentsInfo {
            var frame = info.frame
            let characterIndex = info.characterIndex
            frame.origin.x += origin.x
            frame.origin.y += origin.y
            if case let .image(image) = info.attachment.content {
                info.attachment.drawAttachment(
                    in: textContainer,
                    textView: nil,
                    proposedRect: frame,
                    characterIndex: characterIndex
                )
            }
        }
    }

    @MainActor
    func drawViewAndLayerAttachments(
        with attachmentsInfo: [TextAttachmentInfo],
        at origin: CGPoint,
        in textContainer: NSTextContainer,
        textView: UIView
    ) {
        if attachmentsInfo.isEmpty { return }
        
        for info in attachmentsInfo {
            var frame = info.frame
            let characterIndex = info.characterIndex
            frame.origin.x += origin.x
            frame.origin.y += origin.y
            let content = info.attachment.content
            switch content {
            case .view, .layer:
                info.attachment.drawAttachment(in: textContainer, textView: textView, proposedRect: frame, characterIndex: characterIndex)
            default:
                break
            }
        }
    }

    func drawDebug(with debugOption: TextDebugOption, forGlyphRange glyphsToShow: NSRange, at point: CGPoint) {
        guard debugOption.needsDrawDebug() else {
            return
        }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        UIGraphicsPushContext(context)
        context.saveGState()
        context.translateBy(x: point.x, y: point.y)
        context.setLineWidth(REText.onePixel)
        context.setLineDash(phase: 0, lengths: [])
        context.setLineJoin(.miter)
        context.setLineCap(.butt)
        
        self.enumerateLineFragments(forGlyphRange: glyphsToShow) { rect, usedRect, textContainer, glyphRange, stop in
            if let color = debugOption.lineFragmentFillColor {
                color.setFill()
                context.addRect(rect.pixelRound())
                context.fillPath()
            }
            if let color = debugOption.lineFragmentBorderColor {
                color.setStroke()
                context.addRect(rect.pixelHalf())
                context.strokePath()
            }
            if let color = debugOption.lineFragmentUsedFillColor {
                color.setFill()
                context.addRect(usedRect.pixelRound())
                context.fillPath()
            }
            if let color = debugOption.lineFragmentUsedBorderColor {
                color.setStroke()
                context.addRect(usedRect.pixelHalf())
                context.strokePath()
            }
            if let color = debugOption.baselineColor {
                let baselineOffset = self.baselineOffset(forGlyphRange: glyphRange)
                color.setStroke()
                let x1 = usedRect.origin.x.pixelHalf()
                let x2 = (usedRect.origin.x + usedRect.size.width).pixelHalf()
                let y =  (rect.minY + baselineOffset).pixelHalf()
                context.move(to: CGPoint(x: x1, y: y))
                context.addLine(to: CGPoint(x: x2, y: y))
                context.strokePath()
            }
            if debugOption.glyphFillColor != nil || debugOption.glyphBorderColor != nil {
                for g in 0..<glyphRange.length {
                    let glyphRect = self.glyphRect(forGlyphIndex: glyphRange.location + g, in: textContainer)
                    
                    if let color = debugOption.glyphFillColor {
                        color.setFill()
                        context.addRect(glyphRect.pixelRound())
                        context.fillPath()
                    }
                    if let color = debugOption.glyphBorderColor {
                        color.setStroke()
                        context.addRect(glyphRect.pixelHalf())
                        context.strokePath()
                    }
                }
            }
        }
        context.restoreGState()
        UIGraphicsPopContext()
    }
    
    // MARK: - Background
    
    private func backgroundsInfo(
        with backgroundType: TextBackgroundType,
        forGlyphRange glyphsToShow: NSRange,
        in textContainer: NSTextContainer
    ) -> [TextBackgroundInfo] {
        var infos: [TextBackgroundInfo] = []
        
        guard glyphsToShow.length > 0,
              let textStorage = self.textStorage else {
            return infos
        }
        
        let characterRangeToShow = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        
        let attributeKey: NSAttributedString.Key = (backgroundType == .normal)
            ? .background
            : .blockBackground
        
        textStorage.enumerateAttribute(attributeKey, in: characterRangeToShow, options: []) { value, range, stop in
            guard let bgValue = value as? TextBackground else {
                return
            }
            
            let glyphRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            if glyphRange.location == NSNotFound {
                return
            }
            
            var rects: [CGRect] = []
            switch backgroundType {
            case .normal:
                self.enumerateEnclosingRects(
                    forGlyphRange: glyphRange,
                    withinSelectedGlyphRange: NSMakeRange(NSNotFound, 0),
                    in: textContainer
                ) {
                    rect,
                    stopEnumerate in
                    var proposedRect = rect
                    
                    /// This method may return a larger value.
                    /// NSRange glyphRange = [self glyphRangeForBoundingRect:proposedRect inTextContainer:textContainer];
                    let startGlyphIndex = self.glyphIndex(
                        for: .init(x: proposedRect.minX.pixelCeil(), y: proposedRect.midY),
                        in: textContainer
                    )
                    let endGlyphIndex = self.glyphIndex(
                        for: .init(x: proposedRect.maxX.pixelFloor(), y: proposedRect.midY),
                        in: textContainer
                    )
                    
                    let currentGlyphRange = NSMakeRange(startGlyphIndex, endGlyphIndex - startGlyphIndex + 1)
                    let characterRange = self.characterRange(forGlyphRange: currentGlyphRange, actualGlyphRange: nil)
                    
                    proposedRect = bgValue.backgroundRect(
                        for: textContainer,
                        proposedRect: proposedRect,
                        characterRange: characterRange
                    )
                    
                    rects.append(proposedRect)
                }
            case .block:
                var blockRect: CGRect
                var effectiveGlyphRange: NSRange = NSMakeRange(0, 0)
                let startLineFragmentRect = self.lineFragmentRect(forGlyphAt: glyphRange.location, effectiveRange: &effectiveGlyphRange)
                let maxGlyphIndex = NSMaxRange(glyphRange) - 1
                
                if NSLocationInRange(maxGlyphIndex, effectiveGlyphRange) { // in the same line
                    let startLineUsedFragment = self.lineFragmentUsedRect(forGlyphAt: glyphRange.location, effectiveRange: nil)
                    blockRect = startLineFragmentRect
                    blockRect.size.height = startLineUsedFragment.height
                } else {
                    let endLineFragmentRect = self.lineFragmentRect(forGlyphAt: maxGlyphIndex, effectiveRange: nil)
                    let endLineUsedFragmentRect = self.lineFragmentUsedRect(forGlyphAt: maxGlyphIndex, effectiveRange: nil)
                    blockRect = endLineFragmentRect
                    blockRect.size.height = endLineUsedFragmentRect.height
                    blockRect = startLineFragmentRect.union(blockRect)
                }
                blockRect = bgValue.backgroundRect(
                    for: textContainer,
                    proposedRect: blockRect,
                    characterRange: range
                )
                rects.append(blockRect)
            }
            
            infos.append(TextBackgroundInfo(background: bgValue, rects: rects, characterRanges: range))
        }
        return infos
    }

    private func fillBackground(
        _ background: TextBackground,
        rectArray: [CGRect],
        at point: CGPoint,
        forCharacterRange charRange: NSRange
    ) {
        guard let strokeColor = background.borderColor else { return }
        guard let fillColor = background.fillColor else { return }
        let strokeWidth = background.borderWidth
        guard strokeWidth > 0 else { return }
        let cornerRadius = background.cornerRadius
        let borderEdges = background.borderEdges
        let lineJoin = background.lineJoin
        let lineCap = background.lineCap
        
        /// background
        var paths: [UIBezierPath] = []
        for rect in rectArray {
            var rect = rect
            rect.origin.x += point.x
            rect.origin.y += point.y
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            path.close()
            paths.append(path)
        }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        for path in paths {
            context.addPath(path.cgPath)
        }
        context.setFillColor(fillColor.cgColor)
        context.fillPath()
        context.restoreGState()
        
        /// stroke
        let inset = strokeWidth * 0.5
        var strokePaths: [UIBezierPath] = []
        for rect in rectArray {
            var rect = rect
            rect.origin.x += point.x
            rect.origin.y += point.y
            rect = rect.insetBy(dx: inset, dy: inset)
            
            let path: UIBezierPath
            if borderEdges == .all {
                var scaledCornerRadius = cornerRadius
                if inset > 0 && rect.height > 0 {
                    scaledCornerRadius = (cornerRadius * (1 - inset / rect.height)).pixelFloor()
                }
                path = UIBezierPath(roundedRect: rect, cornerRadius: scaledCornerRadius)
                path.close()
            } else {
                path = UIBezierPath()
                let minX = rect.minX
                let maxX = rect.maxX
                let minY = rect.minY
                let maxY = rect.maxY
                if borderEdges.contains(.top) {
                    path.move(to: CGPoint(x: maxX, y: minY))
                    path.addLine(to: CGPoint(x: minX, y: minY))
                }
                if borderEdges.contains(.left) {
                    path.move(to: CGPoint(x: minX, y: minY))
                    path.addLine(to: CGPoint(x: minX, y: maxY))
                }
                if borderEdges.contains(.bottom) {
                    path.move(to: CGPoint(x: minX, y: maxY))
                    path.addLine(to: CGPoint(x: maxX, y: maxY))
                }
                if borderEdges.contains(.right) {
                    path.move(to: CGPoint(x: maxX, y: maxY))
                    path.addLine(to: CGPoint(x: maxX, y: minY))
                }
            }
            strokePaths.append(path)
        }
        
        context.saveGState()
        for path in strokePaths {
            context.addPath(path.cgPath)
        }
        context.setLineWidth(strokeWidth)
        context.setLineJoin(lineJoin)
        context.setLineCap(lineCap)
        context.setStrokeColor(strokeColor.cgColor)
        context.strokePath()
        context.restoreGState()
    }

    private func baselineOffset(forGlyphRange glyphRange: NSRange) -> CGFloat {
        let maxRange = NSMaxRange(glyphRange)
        var index = glyphRange.location
        var glyph: CGGlyph = CGGlyph(kCGFontIndexInvalid)
        
        while glyph == kCGFontIndexInvalid && index < maxRange {
            glyph = self.cgGlyph(at: index)
            index += 1
        }
        
        let finalGlyphIndex = index - 1
        let baselineOffset = self.location(forGlyphAt: finalGlyphIndex).y
        
        if glyph == kCGFontIndexInvalid {
            let charIndex = self.characterIndexForGlyph(at: finalGlyphIndex)
            if let storage = self.textStorage, let font = storage.attribute(.font, at: charIndex, effectiveRange: nil) as? UIFont {
                return baselineOffset + font.descender
            }
        }
        
        return baselineOffset
    }
}
