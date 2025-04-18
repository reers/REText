//
//  TextKitContext.swift
//  REText
//
//  Created by phoenix on 2025/4/18.
//


import UIKit
import os.lock

/// A threadsafe container for the TextKit components that TextKit uses to lay out and truncate its text.
///
/// This container is the sole owner and manager of the TextKit classes. This is an important model because of major
/// thread safety issues inside vanilla TextKit. It provides a central locking location for accessing TextKit methods.
final class TextKitContext {
    
    /// The layout manager used for text layout
    private var layoutManager: TextLayoutManager
    
    /// The text storage that contains the attributed string
    private var textStorage: NSTextStorage
    
    /// The text container that defines the layout constraints
    private var textContainer: NSTextContainer
    
    /// Lock used for all TextKit operations
    private var lock = os_unfair_lock()
    
    /// Initializes a new TextKit context with the specified parameters.
    ///
    /// - Parameters:
    ///   - attributedString: The attributed string to layout
    ///   - lineBreakMode: The line break mode
    ///   - maximumNumberOfLines: The maximum number of lines to display
    ///   - exclusionPaths: The exclusion paths to avoid during layout
    ///   - constrainedSize: The size constraints for layout
    init(
        attributedString: NSAttributedString?,
        lineBreakMode: NSLineBreakMode,
        maximumNumberOfLines: Int,
        exclusionPaths: [UIBezierPath],
        constrainedSize: CGSize
    ) {
        layoutManager = TextLayoutManager()
        textStorage = NSTextStorage()
        textContainer = NSTextContainer(size: .zero)
        
        // Concurrently initialising TextKit components crashes (rdar://18448377) so we use a global lock.
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        
        // Create the TextKit component stack with our default configuration.
        layoutManager = TextLayoutManager()
        layoutManager.usesFontLeading = false
        layoutManager.delegate = TextKitBugFixer.shared
        
        textContainer = NSTextContainer(size: constrainedSize)
        // We want the text laid out up to the very edges of the container.
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines = maximumNumberOfLines
        textContainer.exclusionPaths = exclusionPaths
        layoutManager.addTextContainer(textContainer)
        
        // CJK language layout issues.
        if let attributedString = attributedString {
            let attributedText = NSMutableAttributedString(attributedString: attributedString)
            attributedText.enumerateAttribute(.font, in: NSRange(location: 0, length: attributedText.length), options: []) { value, range, _ in
                if let font = value as? UIFont {
                    attributedText.addAttribute(.originalFont, value: font, range: range)
                }
            }
            textStorage = NSTextStorage(attributedString: attributedText)
        } else {
            textStorage = NSTextStorage()
        }
        
        textStorage.addLayoutManager(layoutManager)
    }
    
    /// All operations on TextKit values MUST occur within this locked context. Simultaneous access (even non-mutative) to
    /// TextKit components may cause crashes.
    ///
    /// The closure provided MUST not call out to client code from within its scope or it is possible for this to cause deadlocks
    /// in your application. Use with EXTREME care.
    ///
    /// Callers MUST NOT keep a ref to these internal objects and use them later. This WILL cause crashes in your application.
    func withLockedTextKitComponents(
        perform action: (
            _ layoutManager: TextLayoutManager,
            _ textStorage: NSTextStorage,
            _ textContainer: NSTextContainer
        ) -> Void
    ) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        action(layoutManager, textStorage, textContainer)
    }
}

