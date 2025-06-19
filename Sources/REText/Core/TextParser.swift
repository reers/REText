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

/// The TextParser protocol declares the required method for text views and labels
/// to modify the text during editing and rendering.
///
/// You can implement this protocol to add features like:
/// - Code syntax highlighting
/// - Emoticon/emoji replacement
/// - Markdown parsing
/// - Custom text formatting
/// - URL detection and styling
///
/// The parser will be called automatically when text content changes, allowing
/// real-time text transformation and styling.
///
/// Example implementations might include:
/// - `MarkdownTextParser` for markdown syntax highlighting
/// - `EmoticonTextParser` for emoji replacement
/// - `CodeHighlightParser` for programming language syntax highlighting
public protocol TextParser: AnyObject {
    
    /// Called when text content changes in the associated text view or label.
    ///
    /// This method provides an opportunity to analyze and modify the text content,
    /// apply custom attributes, or perform content replacement. The implementation
    /// should be efficient as it may be called frequently during text editing.
    ///
    /// - Parameters:
    ///   - text: The mutable attributed string to be parsed and potentially modified.
    ///           This contains the current text content with existing attributes.
    ///           Pass `nil` if no text is available.
    ///   - selectedRange: A pointer to the current text selection range.
    ///                   If the text content is modified, this method should update
    ///                   the range accordingly to maintain proper cursor/selection position.
    ///                   Pass `nil` if no selection exists (e.g., in read-only labels).
    ///
    /// - Returns: `true` if the text content or attributes were modified during parsing,
    ///           `false` if no changes were made. This helps the text system optimize
    ///           redraws and notifications.
    ///
    /// - Note: This method should be implemented efficiently as it may be called
    ///         frequently during text editing. Consider caching parsed results
    ///         when appropriate.
    ///
    /// - Important: When modifying text content (not just attributes), ensure the
    ///             `selectedRange` is properly adjusted to reflect the new text length
    ///             and maintain user's intended cursor position.
    func parseText(_ text: NSMutableAttributedString?, selectedRange: UnsafeMutablePointer<NSRange>?) -> Bool
}
