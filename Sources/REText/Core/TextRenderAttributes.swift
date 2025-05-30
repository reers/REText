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

/// Represents the immutable rendering attributes for text.
public class TextRenderAttributes: NSObject {

    /// The attributed string to be rendered.
    /// Default is nil.
    let attributedText: NSAttributedString?

    /// The line break mode to use.
    /// Default is NSLineBreakByTruncatingTail.
    let lineBreakMode: NSLineBreakMode

    /// The maximum number of lines to render. 0 means no limit.
    /// Default is 1.
    let maximumNumberOfLines: Int // Changed from NSUInteger to Int

    /// An array of UIBezierPath objects representing exclusion paths.
    /// Default is nil.
    let exclusionPaths: [UIBezierPath]

    /// The attributed string to use for truncation.
    /// Default is nil.
    let truncationAttributedText: NSAttributedString?

    /// Designated initializer.
    fileprivate init(
        attributedText: NSAttributedString?,
        lineBreakMode: NSLineBreakMode,
        maximumNumberOfLines: Int,
        exclusionPaths: [UIBezierPath],
        truncationAttributedText: NSAttributedString?
    ) {
        self.attributedText = attributedText
        self.lineBreakMode = lineBreakMode
        self.maximumNumberOfLines = maximumNumberOfLines
        self.exclusionPaths = exclusionPaths
        self.truncationAttributedText = truncationAttributedText
        super.init()
    }
}

extension TextRenderAttributes {

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(attributedText)
        hasher.combine(lineBreakMode)
        hasher.combine(maximumNumberOfLines)
        hasher.combine(exclusionPaths)
        hasher.combine(truncationAttributedText)
        return hasher.finalize()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        if self === object as? AnyObject {
            return true
        }
        guard let other = object as? TextRenderAttributes else {
            return false
        }
        
        return objectIsEqual(attributedText, other.attributedText)
            && lineBreakMode == other.lineBreakMode
            && maximumNumberOfLines == other.maximumNumberOfLines
            && exclusionPaths == other.exclusionPaths
            && objectIsEqual(truncationAttributedText, other.attributedText)
    }
}


/// A mutable builder class for creating TextRenderAttributes instances.
class TextRenderAttributesBuilder {

    /// The attributed string to be rendered.
    /// Default is nil.
    var attributedText: NSAttributedString? = nil

    /// The line break mode to use.
    /// Default is NSLineBreakByTruncatingTail.
    var lineBreakMode: NSLineBreakMode = .byTruncatingTail

    /// The maximum number of lines to render. 0 means no limit.
    /// Default is 1.
    var maximumNumberOfLines: Int = 1

    /// An array of UIBezierPath objects representing exclusion paths.
    /// Default is nil.
    var exclusionPaths: [UIBezierPath] = []

    /// The attributed string to use for truncation.
    /// Default is nil.
    /// Note: You should use TextTruncationAttributedTextWithTokenAndAdditionalMessage() to get it. // Assuming function name also loses prefix
    var truncationAttributedText: NSAttributedString? = nil

    /// Initializes a new builder with default values.
    init() {
        self.lineBreakMode = .byTruncatingTail
        self.maximumNumberOfLines = 1
    }

    /// Initializes a builder with values from an existing TextRenderAttributes instance.
    /// - Parameter renderAttributes: The attributes to copy values from.
    init(renderAttributes: TextRenderAttributes) {
        self.attributedText = renderAttributes.attributedText
        self.exclusionPaths = renderAttributes.exclusionPaths
        self.lineBreakMode = renderAttributes.lineBreakMode
        self.maximumNumberOfLines = renderAttributes.maximumNumberOfLines
        self.truncationAttributedText = renderAttributes.truncationAttributedText
    }

    /// Builds an immutable TextRenderAttributes instance from the builder's current state.
    /// - Returns: A new TextRenderAttributes instance.
    func build() -> TextRenderAttributes {
        return TextRenderAttributes(
            attributedText: self.attributedText,
            lineBreakMode: self.lineBreakMode,
            maximumNumberOfLines: self.maximumNumberOfLines,
            exclusionPaths: self.exclusionPaths,
            truncationAttributedText: self.truncationAttributedText
        )
    }
}

// This extension provides the convenience initializer on TextRenderAttributes
// similar to the Objective-C category `MPITextRenderAttributes (MPITextBuilderAdditions)`
extension TextRenderAttributes {
    /// Initializes TextRenderAttributes using a builder instance.
    /// - Parameter builder: The builder containing the desired attributes.
    convenience init(builder: TextRenderAttributesBuilder) {
        self.init(
            attributedText: builder.attributedText,
            lineBreakMode: builder.lineBreakMode,
            maximumNumberOfLines: builder.maximumNumberOfLines,
            exclusionPaths: builder.exclusionPaths,
            truncationAttributedText: builder.truncationAttributedText
        )
    }
}
