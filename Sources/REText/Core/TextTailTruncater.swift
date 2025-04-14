//
//  TextTailTruncater.swift
//  REText
//
//  Created by phoenix on 2025/4/14.
//

import UIKit

class TextTailTruncater: TextTruncating {
    
    private var truncationAttributedString: NSAttributedString?
    private var avoidTailTruncationSet: NSCharacterSet?
    private var truncationUsedRect: CGRect?
    
    required init(truncationAttributedString: NSAttributedString?, avoidTailTruncationSet: NSCharacterSet?) {
        self.truncationAttributedString = truncationAttributedString
        self.avoidTailTruncationSet = avoidTailTruncationSet
    }
    
    /// Calculates the intersection of the truncation message within the end of the last line.
    private func calculateCharacterIndexBeforeTruncationMessage(
        _ layoutManager: TextLayoutManager,
        textStorage: NSTextStorage,
        textContainer: NSTextContainer
    ) -> Int {
        let visibleGlyphRange = layoutManager.glyphRange(
            forBoundingRect: CGRect(origin: .zero, size: textContainer.size),
            in: textContainer
        )
        
        let lastVisibleGlyphIndex = NSMaxRange(visibleGlyphRange) - 1
        if lastVisibleGlyphIndex < 0 {
            return NSNotFound
        }
        
        var lastLineRange = NSRange()
        let lastLineRect = layoutManager.lineFragmentRect(forGlyphAt: lastVisibleGlyphIndex, effectiveRange: &lastLineRange)
        
        let constrainedRect = CGRect(origin: .zero, size: textContainer.size)
        let lastLineUsedRect = layoutManager.lineFragmentUsedRect(forGlyphAt: lastVisibleGlyphIndex, effectiveRange: nil)
        
        let lastVisibleCharacterIndex = layoutManager.characterIndexForGlyph(at: lastVisibleGlyphIndex)
        if lastVisibleCharacterIndex >= textStorage.length {
            return NSNotFound
        }
        
        let paragraphStyle = textStorage.attribute(.paragraphStyle, at: lastVisibleCharacterIndex, effectiveRange: nil) as? NSParagraphStyle
        
        // We assume LTR so long as the writing direction is not
        let rtlWritingDirection = paragraphStyle?.baseWritingDirection == .rightToLeft
        // We only want to treat the truncation rect as left-aligned in the case that we are right-aligned and our writing
        // direction is RTL.
        let leftAligned = lastLineRect.minX == lastLineUsedRect.minX || !rtlWritingDirection
        
        if truncationUsedRect == nil, let truncationAttributedString = truncationAttributedString {
            let maxSize = CGSize(width: 0x100000, height: 0x100000)
            let truncationUsedRect = truncationAttributedString.boundingRect(
                with: maxSize,
                options: .usesLineFragmentOrigin,
                context: nil
            )
            self.truncationUsedRect = truncationUsedRect
        }
        
        guard let truncationUsedRect = truncationUsedRect else {
            return NSNotFound
        }
        
        let truncationOriginX = leftAligned
            ? constrainedRect.maxX - truncationUsedRect.size.width
            : constrainedRect.minX
        
        let translatedTruncationRect = CGRect(
            x: truncationOriginX,
            y: lastLineRect.minY,
            width: truncationUsedRect.size.width,
            height: truncationUsedRect.size.height
        )
        
        // Determine which glyph is the first to be clipped / overlaps the truncation message.
        let truncationMessageX = leftAligned
            ? translatedTruncationRect.minX
            : translatedTruncationRect.maxX
        
        let beginningOfTruncationMessage = CGPoint(
            x: truncationMessageX,
            y: translatedTruncationRect.midY
        )
        
        let firstClippedGlyphIndex = layoutManager.glyphIndex(
            for: beginningOfTruncationMessage,
            in: textContainer,
            fractionOfDistanceThroughGlyph: nil
        )
        
        // If it didn't intersect with any text then it should just return the last visible character index, since the
        // truncation rect can fully fit on the line without clipping any other text.
        if firstClippedGlyphIndex == NSNotFound {
            return layoutManager.characterIndexForGlyph(at: lastVisibleGlyphIndex)
        }
        
        let firstCharacterIndexToReplace = layoutManager.characterIndexForGlyph(at: firstClippedGlyphIndex)
        
        // Break on word boundaries
        return findTruncationInsertionPoint(
            atOrBeforeCharacterIndex: firstCharacterIndexToReplace,
            layoutManager: layoutManager,
            textStorage: textStorage
        )
    }
    
    /// Finds the first whitespace at or before the character index do we don't truncate in the middle of words
    /// If there are multiple whitespaces together (say a space and a newline), this will backtrack to the first one
    private func findTruncationInsertionPoint(
        atOrBeforeCharacterIndex firstCharacterIndexToReplace: Int,
        layoutManager: NSLayoutManager,
        textStorage: NSTextStorage
    ) -> Int {
        // Don't attempt to truncate beyond the end of the string
        if firstCharacterIndexToReplace >= textStorage.length {
            return 0
        }
        
        var rangeOfLastVisibleAvoidedChars = NSRange(location: NSNotFound, length: 0)
        
        if let avoidTailTruncationSet = avoidTailTruncationSet {
            // Find the glyph range of the line fragment containing the first character to replace.
            var lineGlyphRange = NSRange()
            layoutManager.lineFragmentRect(
                forGlyphAt: layoutManager.glyphIndexForCharacter(at: firstCharacterIndexToReplace),
                effectiveRange: &lineGlyphRange
            )
            
            // Look for the first whitespace from the end of the line, starting from the truncation point
            let startingSearchIndex = layoutManager.characterIndexForGlyph(at: lineGlyphRange.location)
            let endingSearchIndex = firstCharacterIndexToReplace
            let rangeToSearch = NSRange(location: startingSearchIndex, length: endingSearchIndex - startingSearchIndex)
            
            rangeOfLastVisibleAvoidedChars = (textStorage.string as NSString).rangeOfCharacter(
                from: avoidTailTruncationSet as CharacterSet,
                options: .backwards,
                range: rangeToSearch
            )
        }
        
        // Couldn't find a good place to truncate. Might be because there is no whitespace in the text, or we're dealing
        // with a foreign language encoding. Settle for truncating at the original place, which may be mid-word.
        if rangeOfLastVisibleAvoidedChars.location == NSNotFound {
            return firstCharacterIndexToReplace
        } else {
            return rangeOfLastVisibleAvoidedChars.location
        }
    }
    
    func truncate(
        with layoutManager: TextLayoutManager,
        textStorage: NSTextStorage,
        textContainer: NSTextContainer
    ) -> TextTruncationInfo? {
        let originalStringLength = textStorage.length
        
        if originalStringLength == 0 {
            return nil
        }
        
        let visibleGlyphRange = layoutManager.glyphRange(
            forBoundingRect: CGRect(origin: .zero, size: textContainer.size),
            in: textContainer
        )
        
        var visibleCharacterRange = layoutManager.characterRange(
            forGlyphRange: visibleGlyphRange,
            actualGlyphRange: nil
        )
        
        // Check if text is truncated, and if so apply our truncation string
        if visibleCharacterRange.length < originalStringLength,
           let truncationAttributedString = truncationAttributedString,
           truncationAttributedString.length > 0 {
            
            let firstCharacterIndexToReplace = calculateCharacterIndexBeforeTruncationMessage(
                layoutManager,
                textStorage: textStorage,
                textContainer: textContainer
            )
            
            if firstCharacterIndexToReplace == 0 || firstCharacterIndexToReplace == NSNotFound {
                return nil
            }
            
            // Update/truncate the visible range of text
            visibleCharacterRange = NSRange(
                location: visibleCharacterRange.location,
                length: firstCharacterIndexToReplace - visibleCharacterRange.location
            )
            
            let truncationReplacementRange = NSRange(
                location: firstCharacterIndexToReplace,
                length: originalStringLength - firstCharacterIndexToReplace
            )
            
            // Replace the end of the visible message with the truncation string
            textStorage.replaceCharacters(
                in: truncationReplacementRange,
                with: truncationAttributedString
            )
            
            let truncationCharacterRange = NSRange(
                location: firstCharacterIndexToReplace,
                length: truncationAttributedString.length
            )
            
            let visibleCharacterRanges = [visibleCharacterRange]
            
            return TextTruncationInfo(
                characterRange: truncationCharacterRange,
                visibleCharacterRanges: visibleCharacterRanges
            )
        }
        
        return nil
    }
}
