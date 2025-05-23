//
//  TextRenderer.swift
//  REText
//
//  Created by phoenix on 2025/4/24.
//

import UIKit

/// TextRenderer - A class to render text with TextKit
class TextRenderer {
    
    /// The render attributes used for rendering.
    let renderAttributes: TextRenderAttributes
    
    /// The constrained size for rendering.
    let constrainedSize: CGSize
    
    /// Stored attachments info and it's useful for drawing.
    private var attachmentsInfo: [TextAttachmentInfo] = []
    
    // Private properties
    private var context: TextKitContext
    private var calculatedSize: CGSize = .zero
    private var truncationInfo: TextTruncationInfo?
    private var backgroundsInfo: [TextBackgroundInfo] = []
    private var glyphsToShow: NSRange = NSRange(location: NSNotFound, length: 0)
    
    /// Initialize the renderer with render attributes and constrained size.
    /// - Parameters:
    ///   - renderAttributes: The attributes used for rendering.
    ///   - constrainedSize: The constrained size for rendering.
    init(renderAttributes: TextRenderAttributes, constrainedSize: CGSize) {
        self.renderAttributes = renderAttributes
        self.constrainedSize = constrainedSize
        
        // TextKit renders incorrectly by truncating. e.g. text = @"/a/n/n/nb", maximumNumberOfLines = 2.
        var lineBreakMode = renderAttributes.lineBreakMode
        if lineBreakMode == .byTruncatingTail {
            lineBreakMode = .byWordWrapping
        }
        
        context = TextKitContext(
            attributedString: renderAttributes.attributedText,
            lineBreakMode: lineBreakMode,
            maximumNumberOfLines: renderAttributes.maximumNumberOfLines,
            exclusionPaths: renderAttributes.exclusionPaths,
            constrainedSize: constrainedSize
        )
        
        calculateSize()
        calculateGlyphsToShow()
        calculateExtraInfos()
    }
    
    /// Calculate the render size and truncation information
    private func calculateSize() {
        var boundingRect = CGRect.zero
        var truncationInfo: TextTruncationInfo?
        context.withLockedTextKitComponents { layoutManager, textStorage, textContainer in
            layoutManager.ensureLayout(for: textContainer)
            boundingRect = layoutManager.usedRect(for: textContainer)
            
            let truncationRenderAttributesBuilder = TextRenderAttributesBuilder()
            truncationRenderAttributesBuilder.attributedText = self.renderAttributes.truncationAttributedText
            truncationRenderAttributesBuilder.lineBreakMode = self.renderAttributes.lineBreakMode
            let truncationRenderAttributes = TextRenderAttributes(builder: truncationRenderAttributesBuilder)
            
            if let truncater = truncaterForRenderAttributes(truncationRenderAttributes) {
                truncationInfo = truncater.truncate(
                    with: layoutManager,
                    textStorage: textStorage,
                    textContainer: textContainer
                )
                
                if truncationInfo != nil {
                    layoutManager.ensureLayout(for: textContainer)
                    let truncatedBoundingRect = layoutManager.usedRect(for: textContainer)
                    
                    // We should use the maximum height
                    boundingRect.size.height = max(truncatedBoundingRect.height, boundingRect.height)
                }
            }
        }
        
        // TextKit often returns incorrect glyph bounding rects in the horizontal direction,
        // so we clip to our bounding rect to make sure our width calculations aren't being
        // offset by glyphs going beyond the constrained rect.
        boundingRect.size = CGSize(
            width: ceil(boundingRect.size.width),
            height: ceil(boundingRect.size.height)
        )
        boundingRect = boundingRect.intersection(CGRect(origin: .zero, size: constrainedSize))
        
        let size = boundingRect.size
        
        // Update textContainer's size if needed
        var newConstrainedSize = constrainedSize
        if constrainedSize.width > REText.containerMaxSize.width - .ulpOfOne {
            newConstrainedSize.width = size.width
        }
        if constrainedSize.height > REText.containerMaxSize.height - .ulpOfOne {
            newConstrainedSize.height = size.height
        }
        
        if newConstrainedSize != constrainedSize {
            context.withLockedTextKitComponents { layoutManager, textStorage, textContainer in
                textContainer.size = newConstrainedSize
                layoutManager.ensureLayout(for: textContainer)
            }
        }
        
        calculatedSize = size
        self.truncationInfo = truncationInfo
    }
    
    /// Calculate the glyphs to show range
    private func calculateGlyphsToShow() {
        var glyphsToShow = NSRange(location: NSNotFound, length: 0)
        
        context.withLockedTextKitComponents { layoutManager, textStorage, textContainer in
            glyphsToShow = layoutManager.glyphRange(for: textContainer)
        }
        
        self.glyphsToShow = glyphsToShow
    }
    
    /// Calculate extra information such as attachments and backgrounds
    private func calculateExtraInfos() {
        var attachmentsInfo: [TextAttachmentInfo] = []
        var backgroundsInfo: [TextBackgroundInfo] = []
        
        context.withLockedTextKitComponents { layoutManager, textStorage, textContainer in
            let glyphsToShow = layoutManager.glyphRange(for: textContainer)
            if glyphsToShow.location != NSNotFound {
                attachmentsInfo = layoutManager.attachmentsInfo(forGlyphRange: glyphsToShow, in: textContainer)
                backgroundsInfo = layoutManager.backgroundsInfo(forGlyphRange: glyphsToShow, in: textContainer)
            }
        }
        
        self.attachmentsInfo = attachmentsInfo
        self.backgroundsInfo = backgroundsInfo
    }
    
    /// The render's size.
    var size: CGSize {
        return calculatedSize
    }
    
    /// Whether or not the text is truncated.
    var isTruncated: Bool {
        return truncationInfo != nil
    }
    
    /// The text truncation range if text if truncated.
    var truncationRange: NSRange {
        if isTruncated, let range = truncationInfo?.characterRange {
            return range
        }
        return NSRange(location: NSNotFound, length: 0)
    }
    
    /// Draw everything without view and layer for given point.
    /// - Parameters:
    ///   - point: The point indicates where to start drawing.
    ///   - debugOption: How to drawing debug.
    @MainActor
    func draw(at point: CGPoint, debugOption: TextDebugOption?) {
        let glyphsToShow = self.glyphsToShow
        let attachmentsInfo = self.attachmentsInfo
        let backgroundsInfo = self.backgroundsInfo
        
        context.withLockedTextKitComponents { layoutManager, textStorage, textContainer in
            if glyphsToShow.location != NSNotFound {
                layoutManager.drawBackground(forGlyphRange: glyphsToShow, at: point)
                
                if !backgroundsInfo.isEmpty {
                    layoutManager.drawBackground(with: backgroundsInfo, at: point)
                }
                
                layoutManager.drawGlyphs(forGlyphRange: glyphsToShow, at: point)
                
                if !attachmentsInfo.isEmpty {
                    layoutManager.drawImageAttachments(
                        with: attachmentsInfo,
                        at: point,
                        in: textContainer
                    )
                }
                
                if let debugOption = debugOption {
                    layoutManager.drawDebug(
                        with: debugOption,
                        forGlyphRange: glyphsToShow,
                        at: point
                    )
                }
            }
        }
    }
    
    /// It's must be on main thread.
    /// - Parameters:
    ///   - point: Draw view and layer for given point.
    ///   - referenceTextView: NSAttachment will be drawed to it.
    @MainActor
    func drawViewAndLayer(at point: CGPoint, referenceTextView: UIView) {
        let glyphsToShow = self.glyphsToShow
        let attachmentsInfo = self.attachmentsInfo
        
        context.withLockedTextKitComponents { layoutManager, textStorage, textContainer in
            if glyphsToShow.location != NSNotFound {
                layoutManager.drawViewAndLayerAttachments(
                    with: attachmentsInfo,
                    at: point,
                    in: textContainer,
                    textView: referenceTextView
                )
            }
        }
    }
    
    /// Helper function to get a truncater for render attributes
    private func truncaterForRenderAttributes(_ renderAttributes: TextRenderAttributes) -> TextTruncating? {
        // Currently only tail is supported
        if renderAttributes.lineBreakMode != .byTruncatingTail {
            return nil
        }
        
        let cache = Self.truncaterCache
        let key = TextRendererKey(attributes: renderAttributes, constrainedSize: REText.containerMaxSize)
        
        if let truncater = cache.object(forKey: key) {
            return truncater
        }
        
        var truncater: TextTruncating?
        if renderAttributes.lineBreakMode == .byTruncatingTail {
            truncater = TextTailTruncater(
                truncationAttributedString: renderAttributes.attributedText,
                avoidTailTruncationSet: REText.defaultAvoidTruncationCharacterSet
            )
        }
        if let truncater = truncater {
            cache.setObject(truncater, forKey: key)
        }
        return truncater
    }
    
    private static let truncaterCache: MemoryCache<TextRendererKey, TextTruncating> = {
        let cache = MemoryCache<TextRendererKey, TextTruncating>()
        cache.countLimit = 200
        return cache
    }()
}

/// Extension providing additional TextKit-based functionality
extension TextRenderer {
    
    /// Returns the value for the attribute with a given name of the character at a given index, and by reference the range over which the attribute applies.
    /// - Parameters:
    ///   - name: The name of an attribute.
    ///   - point: The index at which to test for attributeName.
    ///   - effectiveRange: If the named attribute does not exist at index, the range is (NSNotFound, 0).
    ///   - inTruncation: Indicates the attribute is in truncation.
    /// - Returns: Returns The value for the attribute named attributeName of the character at index, or nil if there is no such attribute.
    func attribute(_ name: NSAttributedString.Key, at point: CGPoint, effectiveRange: NSRangePointer?, inTruncation: UnsafeMutablePointer<Bool>?) -> Any? {
        var value: Any?
        var attributeRange = NSRange(location: NSNotFound, length: 0)
        var inTruncationFlag = false
        let truncationCharacterRange = truncationInfo?.characterRange
        
        context.withLockedTextKitComponents { layoutManager, textStorage, textContainer in
            // Find the range
            let visibleGlyphsRange = layoutManager.glyphRange(
                forBoundingRect: CGRect(origin: .zero, size: textContainer.size),
                in: textContainer
            )
            let visibleCharactersRange = layoutManager.characterRange(
                forGlyphRange: visibleGlyphsRange,
                actualGlyphRange: nil
            )
            let glyphIndex = layoutManager.glyphIndex(for: point, in: textContainer)
            
            if glyphIndex != NSNotFound {
                let glyphRect = layoutManager.boundingRect(
                    forGlyphRange: NSRange(location: glyphIndex, length: 1),
                    in: textContainer
                )
                if glyphRect.contains(point) {
                    let characterIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
                    
                    var tempRange = NSRange(location: 0, length: 0)
                    value = textStorage.attribute(name, at: characterIndex, longestEffectiveRange: &tempRange, in: visibleCharactersRange)
                    
                    if value != nil {
                        attributeRange = tempRange
                    } else {
                        attributeRange = NSRange(location: NSNotFound, length: 0)
                    }
                }
            }
            
            // Check that the range is in truncation
            if let truncationRange = truncationCharacterRange,
               NSLocationInRange(attributeRange.location, truncationRange) {
                inTruncationFlag = true
                attributeRange = NSRange(
                    location: attributeRange.location - truncationRange.location,
                    length: attributeRange.length
                )
            } else {
                inTruncationFlag = false
            }
        }
        
        if let effectiveRange = effectiveRange {
            effectiveRange.pointee = attributeRange
        }
        
        if let inTruncation = inTruncation {
            inTruncation.pointee = inTruncationFlag
        }
        
        return value
    }
    
    /// Returns the index of the character for the given point. Returns NSNotFound if index in truncation.
    /// - Parameter point: The character's point.
    /// - Returns: The character index.
    func characterIndex(for point: CGPoint) -> Int {
        var characterIndex: Int = NSNotFound
        
        context.withLockedTextKitComponents { layoutManager, textStorage, textContainer in
            let glyphIndex = layoutManager.glyphIndex(for: point, in: textContainer)
            if glyphIndex != NSNotFound {
                characterIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            }
        }
        
        if isTruncated {
            if NSLocationInRange(characterIndex, truncationRange) {
                return NSNotFound
            }
        }
        
        return characterIndex
    }
    
    /// Return the range for the text enclosing a character index in a text word unit.
    /// - Parameter characterIndex: The character for which to return the range.
    /// - Returns: The range enclosing the character.
    func rangeEnclosingCharacter(for index: Int) -> NSRange {
        var text: String?
        
        context.withLockedTextKitComponents { layoutManager, textStorage, textContainer in
            text = textStorage.string
        }
        
        guard let text = text else {
            return NSRange(location: NSNotFound, length: 0)
        }
        
        var resultRange = NSRange(location: NSNotFound, length: 0)
        let string = text as CFString
        let range = CFRange(location: 0, length: text.count)
        let flag = kCFStringTokenizerUnitWord
        let locale = CFLocaleCopyCurrent()
        let tokenizer = CFStringTokenizerCreate(kCFAllocatorDefault, string, range, flag, locale)
        
        var tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        while tokenType.rawValue != 0 {
            let currentTokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            if currentTokenRange.location <= index
               && currentTokenRange.location + currentTokenRange.length > index {
                resultRange = NSRange(location: currentTokenRange.location, length: currentTokenRange.length)
                break
            }
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer)
        }
        
        if resultRange.location == NSNotFound {
            resultRange = NSRange(location: index, length: 1)
        }
        
        return resultRange
    }
    
    /// Returns an array of selection rects corresponding to the range of text.
    /// The start and end rect can be used to show grabber.
    /// - Parameter characterRange: The characterRangefor which to return selection rectangles.
    /// - Returns: An array of `TextSelectionRect` objects that encompass the selection.
    /// If not found, the array is empty.
    @MainActor
    func selectionRects(for characterRange: NSRange) -> [TextSelectionRect] {
        var selectionRects: [TextSelectionRect] = []
        
        context.withLockedTextKitComponents {
            layoutManager,
            textStorage,
            textContainer in
            let glyphRange = layoutManager.glyphRange(
                forCharacterRange: characterRange,
                actualCharacterRange: nil
            )
            
            layoutManager.enumerateEnclosingRects(
                forGlyphRange: glyphRange,
                withinSelectedGlyphRange: glyphRange,
                in: textContainer
            ) { rect, stop in
                let startGlyphIndex = layoutManager.glyphIndex(
                    for: CGPoint(x: ceil(rect.minX), y: rect.midY),
                    in: textContainer
                )
                let startCharacterIndex = layoutManager.characterIndexForGlyph(at: startGlyphIndex)
                
                let paragraphStyle = textStorage.attribute(
                    .paragraphStyle,
                    at: startCharacterIndex,
                    effectiveRange: nil
                ) as? NSParagraphStyle
                
                let selectionRect = TextSelectionRect(
                    rect: rect,
                    writingDirection: paragraphStyle?.baseWritingDirection ?? .leftToRight,
                    containsStart: false,
                    containsEnd: false,
                    isVertical: textContainer.layoutOrientation == .vertical
                )
                selectionRects.append(selectionRect)
            }
        }
        
        if selectionRects.count > 0 {
            let startSelectionRect = selectionRects[0]
            startSelectionRect.containsStart = true
            
            let endSelectionRect = selectionRects[selectionRects.count - 1]
            endSelectionRect.containsEnd = true
        }
        
        return selectionRects
    }
    
    /// Returns the rect for the line fragment.
    /// - Parameters:
    ///   - characterIndex: The character for which to return the line fragment rectangle.
    ///   - effectiveCharacterRange: If not NULL, on output, the range for all chracters in the line fragment.
    /// - Returns: The line fragment used rect.
    func lineFragmentUsedRect(forCharacterAt index: Int, effectiveRange: NSRangePointer?) -> CGRect {
        var lineFragmentUsedRect = CGRect.zero
        
        context.withLockedTextKitComponents { layoutManager, textStorage, textContainer in
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: index)
            var effectiveGlyphRange = NSRange(location: 0, length: 0)
            
            lineFragmentUsedRect = layoutManager.lineFragmentUsedRect(
                forGlyphAt: glyphIndex,
                effectiveRange: &effectiveGlyphRange
            )
            
            if let effectiveRange = effectiveRange {
                effectiveRange.pointee = layoutManager.characterRange(
                    forGlyphRange: effectiveGlyphRange,
                    actualGlyphRange: nil
                )
            }
        }
        
        return lineFragmentUsedRect
    }
    
    /// Returns the rect for the line used fragment.
    /// - Parameters:
    ///   - characterIndex: The character for which to return the line fragment rectangle.
    ///   - effectiveCharacterRange: If not NULL, on output, the range for all chracters in the line fragment.
    /// - Returns: The line fragment rect.
    func lineFragmentRect(forCharacterAt index: Int, effectiveRange: NSRangePointer?) -> CGRect {
        var lineFragmentRect = CGRect.zero
        
        context.withLockedTextKitComponents { layoutManager, textStorage, textContainer in
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: index)
            var effectiveGlyphRange = NSRange(location: 0, length: 0)
            
            lineFragmentRect = layoutManager.lineFragmentRect(
                forGlyphAt: glyphIndex,
                effectiveRange: &effectiveGlyphRange
            )
            
            if let effectiveRange = effectiveRange {
                effectiveRange.pointee = layoutManager.characterRange(
                    forGlyphRange: effectiveGlyphRange,
                    actualGlyphRange: nil
                )
            }
        }
        
        return lineFragmentRect
    }
}
