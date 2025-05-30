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

@MainActor
public protocol TextInteractable: NSObjectProtocol {
    
    var attributedText: NSAttributedString? { get }
    
    var textRenderer: TextRenderer? { get set }
    
    var truncationAttributedText: NSAttributedString { get }
    
    var isSelectable: Bool { get }
    
    var selectedRange: NSRange { get }
    
    func shouldInteractLink(with linkRange: NSRange, for attributedText: NSAttributedString) -> Bool
    
    func highlightedLinkTextAttributes(with linkRange: NSRange, for attributedText: NSAttributedString) -> [NSAttributedString.Key: Any]
    
    func tapLink(with linkRange: NSRange, for attributedText: NSAttributedString)
    
    func longPressLink(with linkRange: NSRange, for attributedText: NSAttributedString)
    
    func linkRange(at point: CGPoint, inTruncation: UnsafeMutablePointer<Bool>?) -> NSRange
    
    func selection(at point: CGPoint) -> Bool
    
    func grabberType(at point: CGPoint) -> TextSelectionGrabberType
    
    func grabberRect(for grabberType: TextSelectionGrabberType) -> CGRect
    
    func characterIndex(for point: CGPoint) -> Int
    
    func beginSelection(at point: CGPoint)
    
    func updateSelection(with range: NSRange)
    
    func endSelection()
    
    var isMenuVisible: Bool { get }
    
    func showMenu()
    
    func hideMenu()
}

typealias TextInteractableView = UIView & TextInteractable

@MainActor
protocol TextInteractionManagerDelegate: NSObjectProtocol {
    func interactionManager(
        _ interactionManager: TextInteractionManager,
        didUpdateHighlightedAttributedText highlightedAttributedText: NSAttributedString?
    )
}

@MainActor
class TextInteractionManager: NSObject {
    
    /// The gesture recognizer used to detect interactions in this text view.
    private(set) var interactiveGestureRecognizer: TextInteractiveGestureRecognizer
    private(set) lazy var grabberPanGestureRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(grabberPanAction(_:)))
        recognizer.delegate = self
        interactableView?.addGestureRecognizer(recognizer)
        return recognizer
    }()
    
    weak var delegate: TextInteractionManagerDelegate?
    
    var hasActiveLink: Bool {
        return activeLinkRange.location != NSNotFound && activeLinkRange.length > 0
    }
    
    private(set) var activeInTruncation: Bool = false
    
    private(set) var highlightedAttributedText: NSAttributedString?
    
    // MARK: - Private Properties
    
    private weak var interactableView: TextInteractableView?
    
    private lazy var rangedMagnifier: TextMagnifier = {
        let magnifier = TextMagnifier.magnifier(type: .ranged)
        magnifier.hostView = interactableView
        return magnifier
    }()
    
    private var trackingGrabberType: TextSelectionGrabberType = .none
    private var pinnedGrabberIndex: Int = NSNotFound
    
    private var activeLinkRange: NSRange = NSRange(location: NSNotFound, length: 0)
    private var snapshotAttributedText: NSAttributedString?
    
    private struct State {
        var showingRangedMagnifier: Bool = false
    }
    private var state = State()
    
    // MARK: - Initialization
    
    init(interactableView: TextInteractableView) {
        self.interactableView = interactableView
        
        interactiveGestureRecognizer = TextInteractiveGestureRecognizer(target: nil, action: nil)
        
        super.init()
        
        interactiveGestureRecognizer.addTarget(self, action: #selector(interactiveAction(_:)))
        interactiveGestureRecognizer.delegate = self
        interactableView.addGestureRecognizer(interactiveGestureRecognizer)
        
        activeLinkRange = NSRange(location: NSNotFound, length: 0)
    }
    
    // MARK: - Gesture Recognition
    
    @objc
    private func interactiveAction(_ recognizer: TextInteractiveGestureRecognizer) {
        guard let interactableView = interactableView else { return }
        
        let location = recognizer.location(in: interactableView)
        let state = recognizer.state
        
        if state == .began {
            showActiveLinkIfNeeded()
        } else if state == .ended {
            let inSelection = interactableView.isSelectable ? interactableView.selection(at: location) : false
            
            if recognizer.result == .tap {
                tapLinkIfNeeded()
                if inSelection {
                    if hasActiveLink {
                        hideMenu()
                    } else {
                        toggleMenu()
                    }
                } else {
                    endSelection()
                }
            } else if recognizer.result == .longPress {
                if interactableView.isSelectable {
                    if inSelection {
                        longPressLinkIfNeeded()
                        if hasActiveLink {
                            hideMenu()
                        }
                    } else {
                        beginSelection(at: location)
                    }
                } else {
                    longPressLinkIfNeeded()
                }
            }
        }
        
        if state == .ended || state == .cancelled || state == .failed {
            hideActiveLinkIfNeeded()
        }
    }
    
    @objc
    private func grabberPanAction(_ recognizer: UIPanGestureRecognizer) {
        guard let interactableView = interactableView else { return }
        
        let location = recognizer.location(in: interactableView)
        let state = recognizer.state
        let grabberType = trackingGrabberType
        
        if state == .began {
            hideMenu()
            
            if grabberType == .start {
                pinnedGrabberIndex = NSMaxRange(interactableView.selectedRange) - 1
            } else if grabberType == .end {
                pinnedGrabberIndex = interactableView.selectedRange.location
            }
        }
        
        let characterIndex = Int(interactableView.characterIndex(for: location))
        let pinnedGrabberIndex = self.pinnedGrabberIndex
        var selectedRange = interactableView.selectedRange
        let isStartGrabber = grabberType == .start
        
        if characterIndex != NSNotFound {
            if characterIndex < pinnedGrabberIndex {
                selectedRange = NSRange(
                    location: characterIndex,
                    length: pinnedGrabberIndex - characterIndex + (isStartGrabber ? 1 : 0)
                )
            } else if characterIndex > pinnedGrabberIndex {
                let location = isStartGrabber ? pinnedGrabberIndex + 1 : pinnedGrabberIndex
                selectedRange = NSRange(
                    location: location,
                    length: characterIndex - location + 1
                )
            } else {
                selectedRange = NSRange(location: pinnedGrabberIndex, length: 1)
            }
        }
        
        interactableView.updateSelection(with: selectedRange)
        
        if state == .began {
            showRangedMagnifier(at: characterIndex)
        } else if state == .changed {
            moveRangedMagnifier(at: characterIndex)
        }
        
        if state == .ended || state == .cancelled || state == .failed {
            hideRangedMagnifier()
            showMenu()
            
            self.trackingGrabberType = .none
            self.pinnedGrabberIndex = NSNotFound
        }
    }
    
    // MARK: - Private (Action)
    
    private func tapLinkIfNeeded() {
        guard hasActiveLink, let snapshotAttributedText = snapshotAttributedText else { return }
        interactableView?.tapLink(with: activeLinkRange, for: snapshotAttributedText)
    }
    
    private func longPressLinkIfNeeded() {
        guard hasActiveLink, let snapshotAttributedText = snapshotAttributedText else { return }
        interactableView?.longPressLink(with: activeLinkRange, for: snapshotAttributedText)
    }
    
    private func beginSelection(at point: CGPoint) {
        interactableView?.beginSelection(at: point)
    }
    
    private func endSelection() {
        interactableView?.endSelection()
    }
    
    // MARK: - Private (Utils)
    
    private func linkRange(at point: CGPoint, inTruncation: UnsafeMutablePointer<Bool>?) -> NSRange {
        return interactableView?.linkRange(
            at: point,
            inTruncation: inTruncation
        ) ?? NSRange(location: NSNotFound, length: 0)
    }
    
    private func linkRange(at point: CGPoint) -> NSRange {
        return linkRange(at: point, inTruncation: nil)
    }
    
    private func containsLink(at point: CGPoint) -> Bool {
        return linkRange(at: point).location != NSNotFound
    }
    
    private func notifyDidUpdateHighlightedAttributedText() {
        delegate?.interactionManager(self, didUpdateHighlightedAttributedText: highlightedAttributedText)
    }
    
    // MARK: - Private (Link)
    
    private func showActiveLinkIfNeeded() {
        guard hasActiveLink,
              let interactableView = interactableView,
              let snapshotAttributedText = snapshotAttributedText
        else { return }
        
        let highlightedLinkAttributedText = NSMutableAttributedString(attributedString: snapshotAttributedText.attributedSubstring(from: activeLinkRange))
        
        let textAttributes = interactableView.highlightedLinkTextAttributes(
            with: activeLinkRange,
            for: snapshotAttributedText
        )
        if !textAttributes.isEmpty {
            highlightedLinkAttributedText.addAttributes(
                textAttributes,
                range: highlightedLinkAttributedText.rangeOfAll
            )
        }
        highlightedLinkAttributedText.addAttribute(
            .highlighted,
            value: true,
            range: highlightedLinkAttributedText.rangeOfAll
        )
        
        let highlightedAttributedText = NSMutableAttributedString(attributedString: snapshotAttributedText)
        highlightedAttributedText.replaceCharacters(in: activeLinkRange, with: highlightedLinkAttributedText)
        
        self.highlightedAttributedText = highlightedAttributedText
        
        notifyDidUpdateHighlightedAttributedText()
    }
    
    private func hideActiveLinkIfNeeded() {
        guard hasActiveLink else { return }
        
        clearActiveLink()
        
        notifyDidUpdateHighlightedAttributedText()
    }
    
    private func captureAttributedText(activeInTruncation: Bool) -> NSAttributedString? {
        guard let interactableView = interactableView else { return nil }
        
        if let textRenderer = interactableView.textRenderer {
            let renderAttributes = textRenderer.renderAttributes
            return activeInTruncation ? renderAttributes.truncationAttributedText : renderAttributes.attributedText
        } else {
            return activeInTruncation ? interactableView.truncationAttributedText : interactableView.attributedText
        }
    }
    
    private func clearActiveLink() {
        activeLinkRange = NSRange(location: NSNotFound, length: 0)
        activeInTruncation = false
        highlightedAttributedText = nil
        snapshotAttributedText = nil
    }
    
    // MARK: - Private (Menu)
    
    private var isMenuVisible: Bool {
        return interactableView?.isMenuVisible ?? false
    }
    
    private func showMenu() {
        interactableView?.showMenu()
    }
    
    private func hideMenu() {
        interactableView?.hideMenu()
    }
    
    private func toggleMenu() {
        if isMenuVisible {
            hideMenu()
        } else {
            showMenu()
        }
    }
    
    // MARK: - Private (Magnifier)
    
    private func updateRangedMagnifierSetting(with characterIndex: Int) {
        guard let interactableView = interactableView else { return }
        
        let grabberType: TextSelectionGrabberType = characterIndex < pinnedGrabberIndex ? .start : .end
        let grabberRect = interactableView.grabberRect(for: grabberType)
        
        let grabberCenter = CGPoint(x: grabberRect.midX, y: grabberRect.midY)
        rangedMagnifier.hostCaptureCenter = grabberCenter
        rangedMagnifier.hostPopoverCenter = CGPoint(x: grabberCenter.x, y: grabberRect.minY)
    }
    
    private func showRangedMagnifier(at characterIndex: Int) {
        state.showingRangedMagnifier = true
        
        updateRangedMagnifierSetting(with: characterIndex)
        
        TextEffectWindow.shared.showMagnifier(rangedMagnifier)
    }
    
    private func moveRangedMagnifier(at characterIndex: Int) {
        updateRangedMagnifierSetting(with: characterIndex)
        TextEffectWindow.shared.moveMagnifier(rangedMagnifier)
    }
    
    private func hideRangedMagnifier() {
        guard state.showingRangedMagnifier else { return }
        state.showingRangedMagnifier = false
        
        TextEffectWindow.shared.hideMagnifier(rangedMagnifier)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension TextInteractionManager: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if let interactableView = interactableView, interactableView.isSelectable {
            if gestureRecognizer == grabberPanGestureRecognizer &&
               otherGestureRecognizer.view is UIScrollView {
                return true
            }
        }
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let interactableView = interactableView else { return false }
        
        let location = gestureRecognizer.location(in: interactableView)
        
        if gestureRecognizer == interactiveGestureRecognizer {
            let snapshotAttributedTextBefore = captureAttributedText(activeInTruncation: false)
            let snapshotTruncationAttributedTextBefore = captureAttributedText(activeInTruncation: true)
            
            var activeInTruncation = false
            let activeLinkRangePointer = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
            activeLinkRangePointer.pointee = activeInTruncation
            defer { activeLinkRangePointer.deallocate() }
            
            self.activeLinkRange = linkRange(at: location, inTruncation: activeLinkRangePointer)
            self.activeInTruncation = activeLinkRangePointer.pointee
            
            let snapshotAttributedTextEnd = captureAttributedText(activeInTruncation: false)
            let snapshotTruncationAttributedTextEnd = captureAttributedText(activeInTruncation: true)
            
            if snapshotAttributedTextBefore != snapshotAttributedTextEnd ||
               snapshotTruncationAttributedTextBefore != snapshotTruncationAttributedTextEnd {
                clearActiveLink()
            }
            
            if self.activeLinkRange.location != NSNotFound {
                if self.activeInTruncation {
                    snapshotAttributedText = snapshotTruncationAttributedTextEnd
                } else {
                    snapshotAttributedText = snapshotAttributedTextEnd
                }
                
                if let snapshotAttributedText = snapshotAttributedText {
                    let shouldInteractLink = interactableView.shouldInteractLink(with: self.activeLinkRange, for: snapshotAttributedText)
                    if !shouldInteractLink {
                        clearActiveLink()
                    }
                }
            }
            
            return interactableView.isSelectable ? true : hasActiveLink
        } else if interactableView.isSelectable && gestureRecognizer == grabberPanGestureRecognizer {
            trackingGrabberType = interactableView.grabberType(at: location)
            return trackingGrabberType != .none
        }
        
        return false
    }
}

