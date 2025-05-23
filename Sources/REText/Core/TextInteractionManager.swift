//
//  TextInteractionManager.swift
//  REText
//
//  Created by phoenix on 2025/5/23.
//

import UIKit

protocol TextInteractable: NSObjectProtocol {
    
    var attributedText: NSAttributedString? { get }
    
    var textRenderer: TextRenderer? { get set }
    
    var truncationAttributedText: NSAttributedString? { get }
    
    var isSelectable: Bool { get }
    
    var selectedRange: NSRange { get }
    
    func shouldInteractLink(with linkRange: NSRange, for attributedText: NSAttributedString) -> Bool
    
    func highlightedLinkTextAttributes(with linkRange: NSRange, for attributedText: NSAttributedString) -> [String: Any]
    
    func tapLink(with linkRange: NSRange, for attributedText: NSAttributedString)
    
    func longPressLink(with linkRange: NSRange, for attributedText: NSAttributedString)
    
    func linkRange(at point: CGPoint, inTruncation: UnsafeMutablePointer<Bool>?) -> NSRange
    
    func selection(at point: CGPoint) -> Bool
    
    func grabberType(at point: CGPoint) -> TextSelectionGrabberType
    
    func grabberRect(for grabberType: TextSelectionGrabberType) -> CGRect
    
    func characterIndex(for point: CGPoint) -> UInt
    
    func beginSelection(at point: CGPoint)
    
    func updateSelection(with range: NSRange)
    
    func endSelection()
    
    var isMenuVisible: Bool { get }
    
    func showMenu()
    
    func hideMenu()
}
