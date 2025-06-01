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
import Dispatch

public protocol RELabelDelegate: NSObjectProtocol {
    /// Asks the delegate if the specified text view should allow the specified type of user interaction with the given URL in the given range of text.
    /// - Parameters:
    ///   - label: Reference label.
    ///   - link: TextLink instance.
    ///   - attributedText: The attributedText, if link in truncation, it's truncationAttributedText.
    ///   - characterRange: Current interactive characterRange.
    /// - Returns: true if interaction with the URL should be allowed; false if interaction should not be allowed.
    func label(
        _ label: RELabel,
        shouldInteractWith link: TextLink,
        for attributedText: NSAttributedString,
        in range: NSRange
    ) -> Bool
    
    /// User Interacted link.
    /// - Parameters:
    ///   - label: Reference label.
    ///   - link: TextLink instance.
    ///   - attributedText: The attributedText, if link in truncation, it's truncationAttributedText.
    ///   - characterRange: Current interactive characterRange.
    ///   - interaction: Interaction type.
    func label(
        _ label: RELabel,
        didInteractWith link: TextLink,
        for attributedText: NSAttributedString,
        in range: NSRange,
        interaction: TextItemInteraction
    )
    
    /// Asks the delegate if the specified text should have another attributes when highlighted.
    /// - Parameters:
    ///   - label: Reference label.
    ///   - link: TextLink instance.
    ///   - attributedText: The attributedText, if link in truncation, it's truncationAttributedText.
    ///   - characterRange: Current interactive characterRange.
    func label(
        _ label: RELabel,
        highlightedTextAttributesWith link: TextLink,
        for attributedText: NSAttributedString,
        in range: NSRange
    ) -> [NSAttributedString.Key: Any]?
    
    /// The text view will begin selection triggered by longpress.
    /// - Parameters:
    ///   - label: Reference label.
    ///   - selectedRange: Selection of text.
    func labelWillBeginSelection(_ label: RELabel, selectedRange: UnsafeMutablePointer<NSRange>)
    
    /// The menu items will be used by menu. If menu items is empty, menu will not be shown.
    /// - Parameter label: Reference Label.
    func menuItems(for label: RELabel) -> [UIMenuItem]?
    
    /// The visibility of the menu.
    /// - Parameter label: Reference Label.
    func menuVisible(for label: RELabel) -> Bool
    
    /// Customize menu showing. You should implement menuVisibleForLabel:.
    /// - Parameters:
    ///   - label: Reference label.
    ///   - menuItems: The custom menu items for the menu.
    ///   - targetRect: A rectangle that defines the area that is to be the target of the menu commands.
    func label(_ label: RELabel, showMenuWith menuItems: [UIMenuItem], targetRect: CGRect)
    
    /// Customize menu hiding.
    /// - Parameter label: Reference label.
    func labelHideMenu(_ label: RELabel)
}

public extension RELabelDelegate {
    func label(
        _ label: RELabel,
        shouldInteractWith link: TextLink,
        for attributedText: NSAttributedString,
        in range: NSRange
    ) -> Bool {
        return true
    }
    
    func label(
        _ label: RELabel,
        didInteractWith link: TextLink,
        for attributedText: NSAttributedString,
        in range: NSRange,
        interaction: TextItemInteraction
    ) {}
    
    func label(
        _ label: RELabel,
        highlightedTextAttributesWith link: TextLink,
        for attributedText: NSAttributedString,
        in range: NSRange
    ) -> [NSAttributedString.Key: Any]? {
        return nil
    }
    
    func labelWillBeginSelection(_ label: RELabel, selectedRange: UnsafeMutablePointer<NSRange>) {}
    
    func menuItems(for label: RELabel) -> [UIMenuItem]? {
        return nil
    }
    
    func menuVisible(for label: RELabel) -> Bool {
        return false
    }
    
    func label(_ label: RELabel, showMenuWith menuItems: [UIMenuItem], targetRect: CGRect) {}
    
    func labelHideMenu(_ label: RELabel) {}
}

public extension RELabel {
    
    /// Composed by truncationAttributedToken and additionalTruncationAttributedMessage.
    /// - Parameters:
    ///   - attributedText: The current styled text.
    ///   - token: The truncation token string used when text is truncated.
    ///   - additionalMessage: The second attributed string appended for truncation.
    static func truncationAttributedText(
        withTokenAndAdditionalMessage attributedText: NSAttributedString?,
        token: NSAttributedString?,
        additionalMessage: NSAttributedString?
    ) -> NSAttributedString {
        var truncationAttributedText: NSAttributedString
        
        if let token = token, let additionalMessage = additionalMessage {
            let newComposedTruncationString = NSMutableAttributedString(attributedString: token)
            newComposedTruncationString.append(additionalMessage)
            truncationAttributedText = newComposedTruncationString
        } else if let token = token {
            truncationAttributedText = token
        } else if let additionalMessage = additionalMessage {
            truncationAttributedText = additionalMessage
        } else {
            truncationAttributedText = REText.defaultTruncationAttributedToken
        }
        
        truncationAttributedText = Self.prepareTruncationText(forDrawing: attributedText, truncationAttributedText)
        return truncationAttributedText
    }

    /// Calculate the text view size. This method can warms up the cache.
    /// And background thread usage supported.
    /// - Parameters:
    ///   - attributes: The text attributes.
    ///   - fitsSize: The text fits size.
    ///   - textContainerInset: The textContainer insets.
    /// - Returns: Suggest text view size.
    static func suggestFrameSize(
        for attributes: TextRenderAttributes,
        fitsSize: CGSize,
        textContainerInset: UIEdgeInsets
    ) -> CGSize {
        if attributes.attributedText?.length == 0 {
            return .zero
        }
        
        var fitsSize = fitsSize
        if fitsSize.width < CGFloat.ulpOfOne || fitsSize.width > REText.containerMaxSize.width {
            fitsSize.width = REText.containerMaxSize.width
        }
        if fitsSize.height < CGFloat.ulpOfOne || fitsSize.height > REText.containerMaxSize.height {
            fitsSize.height = REText.containerMaxSize.height
        }
        
        let horizontalValue = textContainerInset.horizontalValue
        let verticalValue = textContainerInset.verticalValue
        
        var constrainedSize = fitsSize
        if constrainedSize.width < REText.containerMaxSize.width - CGFloat.ulpOfOne {
            constrainedSize.width = fitsSize.width - horizontalValue
        }
        if constrainedSize.height < REText.containerMaxSize.height - CGFloat.ulpOfOne {
            constrainedSize.height = fitsSize.height - verticalValue
        }
        
        let key = TextRendererKey(attributes: attributes, constrainedSize: constrainedSize)
        
        var renderer: TextRenderer?
        var textSize: CGSize = .zero
        
        if let textSizeValue = Self.textSize(for: key) {
            textSize = textSizeValue
        } else {
            renderer = TextRenderer(renderAttributes: attributes, constrainedSize: constrainedSize)
            textSize = renderer!.size
            Self.cacheTextSize(for: key, textSize: textSize)
        }
        
        var suggestSize = CGSize(width: textSize.width + horizontalValue, height: textSize.height + verticalValue)
        
        if suggestSize.width > fitsSize.width {
            suggestSize.width = fitsSize.width
        }
        if suggestSize.height > fitsSize.height {
            suggestSize.height = fitsSize.height
        }
        
        if let renderer = renderer {
            // Cache Renderer for render
            var constrainedSize = constrainedSize
            if constrainedSize.width > REText.containerMaxSize.width - CGFloat.ulpOfOne {
                constrainedSize.width = textSize.width
            }
            if constrainedSize.height > REText.containerMaxSize.height - CGFloat.ulpOfOne {
                constrainedSize.height = textSize.height
            }
            cacheRenderer(renderer, attributes: attributes, constrainedSize: constrainedSize)
        }
        
        return suggestSize
    }
}

@MainActor
open class RELabel: UIView {
    
    // MARK: - Properties
    
    /// The receiver's delegate.
    open weak var delegate: RELabelDelegate?
    
    /// `NSAttributedString` attributes applied to links when touched.
    open var highlightedLinkTextAttributes: [NSAttributedString.Key: Any]?
    
    
    /// The debug option to display CoreText layout result.
    /// The default value is [TextDebugOption sharedDebugOption].
    private var debugOption: TextDebugOption? {
        didSet {
            if debugOption?.needsDrawDebug() != oldValue?.needsDrawDebug() {
                setNeedsUpdateContents()
            }
        }
    }
    
    // MARK: - Accessing the Text Attributes
    
    /// The underlying attributed string drawn by the label.
    /// NOTE: If set, the label ignores other properties.
    open var attributedText: NSAttributedString? {
        get {
            return _attributedText
        }
        set {
            if objectIsEqual(_attributedText, newValue) {
                return
            }
            _attributedText = newValue?.copy() as? NSAttributedString
            invalidate()
        }
    }
    
    /// Ignore common properties (such as text, font, textColor, attributedText...) and
    /// only use the text renderer to display content.
    /// 
    /// Set it to get higher performance.
    open var textRenderer: TextRenderer? {
        didSet {
            if _textRenderer === textRenderer {
                return
            }
            _textRenderer = textRenderer
            invalidate()
        }
    }
    
    /// The text displayed by the label. Default is nil.
    /// Set a new value to this property also replaces the text in `attributedText`.
    /// Get the value returns the plain text in `attributedText`.
    open var text: String? {
        get {
            return attributedText?.string
        }
        set {
            if let text = newValue {
                let attributedText = NSMutableAttributedString(string: text, attributes: attributesByProperties)
                attributedText.setAlignment(textAlignment, range: attributedText.rangeOfAll)
                self.attributedText = attributedText
            } else {
                self.attributedText = nil
            }
        }
    }
    
    /// The font of the text. Default is 17-point system font.
    /// Set a new value to this property also causes the new font to be applied to the entire `attributedText`.
    open var font: UIFont {
        get {
            return _font ?? defaultFont
        }
        set {
            if objectIsEqual(_font, newValue) {
                return
            }
            _font = newValue
            updateAttributedTextAttribute(.font, value: _font)
        }
    }
    
    /// The color of the text. Default is black.
    /// Set a new value to this property also causes the new color to be applied to the entire `attributedText`.
    open var textColor: UIColor {
        get {
            return _textColor ?? defaultTextColor
        }
        set {
            if objectIsEqual(_textColor, newValue) {
                return
            }
            _textColor = newValue
            updateAttributedTextAttribute(.foregroundColor, value: _textColor)
        }
    }
    
    /// The shadow color of the text. Default is nil.
    /// Set a new value to this property also causes the shadow color to be applied to the entire `attributedText`.
    open var shadowColor: UIColor? {
        didSet {
            if objectIsEqual(oldValue, shadowColor) {
                return
            }
            updateAttributedTextAttribute(.shadow, value: shadowByProperties)
        }
    }
    
    /// The shadow offset of the text. Default is CGSizeMake(0, -1) -- a top shadow.
    /// Set a new value to this property also causes the shadow offset to be applied to the entire `attributedText`.
    open var shadowOffset: CGSize = CGSize(width: 0, height: -1) {
        didSet {
            if oldValue == shadowOffset {
                return
            }
            updateAttributedTextAttribute(.shadow, value: shadowByProperties)
        }
    }
    
    /// The shadow blur of the text. Default is 0.
    /// Set a new value to this property also causes the shadow blur to be applied to the entire `attributedText`.
    open var shadowBlurRadius: CGFloat = 0 {
        didSet {
            if abs(oldValue - shadowBlurRadius) < CGFloat.ulpOfOne {
                return
            }
            updateAttributedTextAttribute(.shadow, value: shadowByProperties)
        }
    }
    
    /// The technique to use for aligning the text. Default is NSTextAlignmentLeft.
    /// Set a new value to this property also causes the new alignment to be applied to the entire `attributedText`.
    open var textAlignment: NSTextAlignment = .left {
        didSet {
            if oldValue == textAlignment {
                return
            }
            if let attributedText {
                let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
                mutableAttributedText.setAlignment(textAlignment, range: attributedText.rangeOfAll)
                self.attributedText = mutableAttributedText.copy() as? NSAttributedString
            }
        }
    }
    
    /// The text vertical aligmnent in container. Default is TextVerticalAlignmentCenter.
    open var textVerticalAlignment: TextVerticalAlignment = .center
    
    /// The technique to use for wrapping and truncating the label's text.
    /// Default is NSLineBreakByTruncatingTail.
    /// 
    /// Notice: Currently, only tail is supported for truncating.
    open var lineBreakMode: NSLineBreakMode = .byTruncatingTail {
        didSet {
            if oldValue == lineBreakMode {
                return
            }
            invalidate()
        }
    }
    
    /// The truncation token string used when text is truncated. Default is nil.
    /// When the value is nil, the label use "…" as default truncation token.
    open var truncationAttributedToken: NSAttributedString? {
        didSet {
            if objectIsEqual(oldValue, truncationAttributedToken) {
                return
            }
            invalidateAttachments()
            invalidateTruncationAttributedText()
            setNeedsUpdateContents()
        }
    }
    
    /// The second attributed string appended for truncation.
    /// This string will be highlighted on touches.
    /// Default is nil.
    open var additionalTruncationAttributedMessage: NSAttributedString? {
        didSet {
            if objectIsEqual(oldValue, additionalTruncationAttributedMessage) {
                return
            }
            invalidateAttachments()
            invalidateTruncationAttributedText()
            setNeedsUpdateContents()
        }
    }
    
    /// Whether or not the text is truncated. It's expensive if text not rendered.
    open var isTruncated: Bool {
        return currentRenderer.isTruncated ?? false
    }
    
    /// The text truncation range if text if truncated.
    open var truncationRange: NSRange {
        return currentRenderer.truncationRange ?? NSRange(location: NSNotFound, length: 0)
    }
    
    /// The maximum number of lines to use for rendering text. Default value is 1.
    /// 0 means no limit.
    open var numberOfLines: Int = 1 {
        didSet {
            if oldValue == numberOfLines {
                return
            }
            invalidate()
        }
    }
    
    // MARK: - Configuring the Text Selection
    
    /// Toggle selectability, which controls the ability of the user to select content
    /// Note: You can change the selection's style with tintColor.
    open var isSelectable: Bool = false {
        didSet {
            if oldValue != isSelectable {
                if isSelectable {
                    if selectionView == nil {
                        selectionView = TextSelectionView()
                        addSubview(selectionView!)
                    }
                }
                updateSelectionView()
                interactionManager.grabberPanGestureRecognizer.isEnabled = isSelectable
            }
        }
    }
    
    /// The current selection range of the receiver.
    open var selectedRange: NSRange = NSRange(location: NSNotFound, length: 0) {
        didSet {
            if !isSelectable {
                return
            }
            if NSEqualRanges(oldValue, selectedRange) {
                return
            }
            updateSelectionView()
        }
    }
    
    // MARK: - Configuring the Text Container
    
    /// The inset of the text container's layout area within the text view's content area.
    /// Default value is UIEdgeInsetsZero.
    open var textContainerInset: UIEdgeInsets = .zero {
        didSet {
            if oldValue == textContainerInset {
                return
            }
            invalidate()
        }
    }
    
    /// An array of UIBezierPath representing the exclusion paths inside the receiver's bounding rect.
    /// The default value is empty.
    open var exclusionPaths: [UIBezierPath]? {
        didSet {
            if arrayIsEqual(oldValue, exclusionPaths) {
                return
            }
            let textRect = textRectForBounds(bounds, textSize: currentRenderer.size)
            _exclusionPaths = exclusionPaths
            
            _exclusionPaths?.forEach { path in
                path.apply(CGAffineTransform(translationX: -textRect.origin.x, y: -textRect.origin.y))
            }
            invalidate()
        }
    }
    
    // MARK: - Getting the Layout Constraints
    
    /// The preferred maximum width (in points) for a multiline label.
    /// 
    /// Support for constraint-based layout (auto layout).
    /// If nonzero, this is used when determining -intrinsicContentSize for multiline labels.
    /// 
    /// NOTE: It's contains textContainerInset.
    open var preferredMaxLayoutWidth: CGFloat = 0 {
        didSet {
            if abs(oldValue - preferredMaxLayoutWidth) < CGFloat.ulpOfOne {
                return
            }
            invalidate()
        }
    }
    
    // MARK: - Configuring the Display Mode
    
    /// A Boolean value indicating whether the layout and rendering codes are running
    /// asynchronously on background threads.
    /// 
    /// The default value is `false`.
    open var displaysAsynchronously: Bool = false {
        didSet {
            if oldValue != displaysAsynchronously {
                setNeedsUpdateContents()
            }
        }
    }
    
    /// If the value is YES, and the layer is rendered asynchronously, then it will
    /// set label.layer.contents to nil before display.
    /// 
    /// The default value is `true`.
    /// 
    /// When the asynchronously display is enabled, the layer's content will
    /// be updated after the background render process finished. If the render process
    /// can not finished in a vsync time (1/60 second), the old content will be still kept
    /// for display. You may manually clear the content by set the layer.contents to nil
    /// after you update the label's properties, or you can just set this property to YES.
    open var clearContentsBeforeAsynchronouslyDisplay: Bool = true
    
    /// If the value is NO, and the layer is rendered asynchronously, then it will add
    /// a fade animation on layer when the contents of layer changed.
    /// 
    /// The default value is `true`.
    open var fadeOnAsynchronouslyDisplay: Bool = true
    
    // MARK: - Private Properties
    
    private var _attributedText: NSAttributedString?
    private var _textRenderer: TextRenderer?
    private var _font: UIFont?
    private var _textColor: UIColor?
    private var _exclusionPaths: [UIBezierPath]?
    private var _truncationAttributedText: NSAttributedString?
    
    private var interactionManager: TextInteractionManager!
    private var selectionView: TextSelectionView?
    private var attachmentViews: [UIView] = []
    private var attachmentLayers: [CALayer] = []
    private var menuType: TextMenuType = .none
    
    private struct State {
        var contentsUpdated = false
        var attachmentsNeedsUpdate = false
    }
    private var state = State()
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    deinit {
        #if DEBUG
        TextDebugOption.removeDebugTarget(self)
        #endif
    }
    
    private func commonInit() {
        interactionManager = TextInteractionManager(interactableView: self)
        interactionManager.delegate = self
        
        layer.contentsScale = REText.screenScale
        contentMode = .redraw
        isOpaque = false
        
        highlightedLinkTextAttributes = REText.defaultHighlightedLinkTextAttributes
        
        #if DEBUG
        debugOption = TextDebugOption.shared
        TextDebugOption.addDebugTarget(self)
        #endif
    }
    
    // MARK: - Override Methods
    
    open override class var layerClass: AnyClass {
        return AsyncLayer.self
    }
    
    open override var intrinsicContentSize: CGSize {
        var width = frame.width
        if numberOfLines == 1 {
            width = REText.containerMaxSize.width
        }
        
        if preferredMaxLayoutWidth > CGFloat.ulpOfOne {
            width = preferredMaxLayoutWidth
        }
        
        return sizeThatFits(CGSize(width: width, height: REText.containerMaxSize.height))
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        if let textRenderer = textRenderer {
            return CGSize(
                width: textRenderer.size.width + textContainerInset.horizontalValue,
                height: textRenderer.size.height + textContainerInset.verticalValue
            )
        }
        
        let renderAttributes = self.renderAttributes
        var size = size
        if size == bounds.size {
            size.height = REText.containerMaxSize.height
        }
        return Self.suggestFrameSize(for: renderAttributes, fitsSize: size, textContainerInset: textContainerInset)
    }
    
    open override var bounds: CGRect {
        didSet {
            // https://stackoverflow.com/questions/17491376/ios-autolayout-multi-line-uilabel
            let oldSize = oldValue.size
            let newSize = bounds.size
            if oldSize != newSize {
                invalidate()
            }
        }
    }
    
    open override var frame: CGRect {
        didSet {
            let oldSize = oldValue.size
            let newSize = bounds.size
            if oldSize != newSize {
                invalidate()
            }
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        selectionView?.frame = bounds
    }
    
    // MARK: - Responder
    
    open override var canBecomeFirstResponder: Bool {
        return isSelectable
    }
    
    @discardableResult
    open override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            hideMenu()
        }
        return result
    }
    
    // MARK: - UIAccessibility
    
    open override var accessibilityLabel: String? {
        get {
            return super.accessibilityLabel ?? text
        }
        set {
            super.accessibilityLabel = newValue
        }
    }
    
    open override var accessibilityAttributedLabel: NSAttributedString? {
        get {
            return super.accessibilityAttributedLabel ?? attributedText
        }
        set {
            super.accessibilityAttributedLabel = newValue
        }
    }
    
    // MARK: - UIResponderStandardEditActions
    
    open override func copy(_ sender: Any?) {
        let string = attributedText?.plainText(for: selectedRange)
        if let string = string, !string.isEmpty {
            UIPasteboard.general.string = string
        }
    }
    
    // MARK: - Public Methods
    
    /// To show menu by selectedRange.
    open func showMenu() {
        var menuItems: [UIMenuItem]?
        if let items = delegate?.menuItems(for: self) {
            menuItems = items
            if items.isEmpty {
                return
            }
        }
        
        if !isFirstResponder {
            becomeFirstResponder()
        }
        
        var targetRect = CGRect.null
        for selectionRect in selectionView?.selectionRects ?? [] {
            targetRect = targetRect.union(selectionRect.rect)
        }
        
        if let delegate = delegate {
            menuType = .custom
            delegate.label(self, showMenuWith: menuItems ?? [], targetRect: targetRect)
        } else {
            menuType = .system
            UIMenuController.shared.menuItems = menuItems
            UIMenuController.shared.showMenu(from: self, rect: targetRect)
        }
    }
    
    /// To hide menu.
    open func hideMenu() {
        if !isMenuVisible {
            return
        }
        menuType = .none
        
        if let delegate = delegate {
            delegate.labelHideMenu(self)
        } else {
            UIMenuController.shared.hideMenu()
        }
    }
    
    // MARK: - Private Methods
    
    private var defaultFont: UIFont {
        return UIFont.systemFont(ofSize: 17)
    }
    
    private var defaultTextColor: UIColor {
        return UIColor.black
    }
    
    private var attributesByProperties: [NSAttributedString.Key: Any] {
        let font = self.font
        let textColor = self.textColor
        let shadow = shadowByProperties
        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: font
        ]
        if let shadow = shadow {
            attributes[.shadow] = shadow
        }
        return attributes
    }
    
    private var shadowByProperties: NSShadow? {
        guard let shadowColor = shadowColor, shadowBlurRadius > CGFloat.ulpOfOne else {
            return nil
        }
        
        let shadow = NSShadow()
        shadow.shadowColor = shadowColor
        shadow.shadowOffset = shadowOffset
        shadow.shadowBlurRadius = shadowBlurRadius
        return shadow
    }
    
    private func updateAttributedTextAttribute(_ name: NSAttributedString.Key, value: Any?) {
        guard let attributedText = self.attributedText else { return }
        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
        mutableAttributedText.setAttribute(name, value: value, range: mutableAttributedText.rangeOfAll)
        _attributedText = mutableAttributedText.copy() as? NSAttributedString
        
        setNeedsUpdateContents()
        
        if name == .font {
            invalidateAttachments()
            invalidateTruncationAttributedText()
            invalidateIntrinsicContentSize()
        }
    }
    
    private var renderAttributes: TextRenderAttributes {
        let hasActiveLink = interactionManager.hasActiveLink
        let activeInTruncation = interactionManager.activeInTruncation
        let highlightedAttributedText = interactionManager.highlightedAttributedText
        
        let attributesBuilder: TextRenderAttributesBuilder
        
        if let textRenderer = textRenderer {
            attributesBuilder = TextRenderAttributesBuilder(renderAttributes: textRenderer.renderAttributes)
            if hasActiveLink {
                if !activeInTruncation {
                    attributesBuilder.attributedText = highlightedAttributedText
                } else {
                    attributesBuilder.truncationAttributedText = highlightedAttributedText
                }
            }
        } else {
            attributesBuilder = TextRenderAttributesBuilder()
            attributesBuilder.lineBreakMode = lineBreakMode
            attributesBuilder.maximumNumberOfLines = numberOfLines
            attributesBuilder.exclusionPaths = exclusionPaths ?? []
            
            if hasActiveLink && !activeInTruncation {
                attributesBuilder.attributedText = highlightedAttributedText
            } else {
                attributesBuilder.attributedText = attributedText
            }
            
            if hasActiveLink && activeInTruncation {
                attributesBuilder.truncationAttributedText = highlightedAttributedText
            } else {
                attributesBuilder.truncationAttributedText = self.truncationAttributedText
            }
        }
        
        return attributesBuilder.build()
    }
    
    private var currentRenderer: TextRenderer {
        let hasActiveLink = interactionManager.hasActiveLink
        
        if let textRenderer = textRenderer {
            let textContainerSize = textRenderer.constrainedSize
            if hasActiveLink {
                let renderAttributes = self.renderAttributes
                return TextRenderer(renderAttributes: renderAttributes, constrainedSize: textContainerSize)
            } else {
                return textRenderer
            }
        } else {
            let renderAttributes = self.renderAttributes
            let textContainerSize = calculateTextContainerSize()
            if hasActiveLink {
                return TextRenderer(renderAttributes: renderAttributes, constrainedSize: textContainerSize)
            } else {
                return Self.rendererForAttributes(renderAttributes, constrainedSize: textContainerSize)
            }
        }
    }
    
    private func calculateTextContainerSize() -> CGSize {
        let frame = self.frame.inset(by: textContainerInset)
        return frame.size
    }
    
    private func textRectForBounds(_ bounds: CGRect, textSize: CGSize) -> CGRect {
        var textRect = bounds.inset(by: textContainerInset)
        
        if textSize.height < textRect.size.height {
            var yOffset: CGFloat = 0
            switch textVerticalAlignment {
            case .center:
                yOffset = (textRect.size.height - textSize.height) / 2
            case .bottom:
                yOffset = textRect.size.height - textSize.height
            case .top:
                break
            }
            textRect.origin.y += yOffset
        }
        
        return textRect
    }
    
    private func convertPoint(toTextKit point: CGPoint, forBounds bounds: CGRect, textSize: CGSize) -> CGPoint {
        let textRect = textRectForBounds(bounds, textSize: textSize)
        return CGPoint(x: point.x - textRect.origin.x, y: point.y - textRect.origin.y)
    }
    
    private func convertPoint(fromTextKit point: CGPoint, forBounds bounds: CGRect, textSize: CGSize) -> CGPoint {
        let textRect = textRectForBounds(bounds, textSize: textSize)
        return CGPoint(x: point.x + textRect.origin.x, y: point.y + textRect.origin.y)
    }
    
    private func convertRect(fromTextKit rect: CGRect, forBounds bounds: CGRect, textSize: CGSize) -> CGRect {
        let textRect = textRectForBounds(bounds, textSize: textSize)
        return rect.offsetBy(dx: textRect.origin.x, dy: textRect.origin.y)
    }
    
    private func invalidate() {
        invalidateAttachments()
        invalidateIntrinsicContentSize()
        invalidateTruncationAttributedText()
        setNeedsUpdateContents()
    }
    
    private func invalidateAttachments() {
        state.attachmentsNeedsUpdate = true
    }
    
    private func invalidateTruncationAttributedText() {
        _truncationAttributedText = nil
    }
    
    private func setNeedsUpdateContents() {
        if displaysAsynchronously && clearContentsBeforeAsynchronouslyDisplay {
            clearContentsIfNeeded()
        }
        setNeedsUpdateContentsWithoutClearContents()
    }
    
    private func setNeedsUpdateContentsWithoutClearContents() {
        state.contentsUpdated = false
        layer.setNeedsDisplay()
    }
    
    private func clearContentsIfNeeded() {
        guard let contents = layer.contents else { return }
        let image = castToCGImage(contents)
        layer.contents = nil
        if let image {
            Self.releaseQueue.async {
                _ = image
            }
        }
    }
    
    private func clearAttachmentViewsAndLayers() {
        for view in attachmentViews {
            if view.superview == self {
                view.removeFromSuperview()
            }
        }
        for layer in attachmentLayers {
            if layer.superlayer == self.layer {
                layer.removeFromSuperlayer()
            }
        }
        attachmentViews.removeAll()
        attachmentLayers.removeAll()
    }
    
    private func clearAttachmentViewsAndLayers(with attachmentsInfo: [TextAttachmentInfo]) {
        for view in attachmentViews {
            
            if view.superview == self && !contains(content: view, for: attachmentsInfo) {
                view.removeFromSuperview()
            }
        }
        for layer in attachmentLayers {
            if layer.superlayer == self.layer && !contains(content: layer, for: attachmentsInfo) {
                layer.removeFromSuperlayer()
            }
        }
        attachmentViews.removeAll()
        attachmentLayers.removeAll()
    }
    
    private func contains(content: Any, for attachmentsInfo: [TextAttachmentInfo]) -> Bool {
        for info in attachmentsInfo {
            switch info.attachment.content {
            case .image(let image):
                if image === content as AnyObject {
                    return true
                }
            case .layer(let layer):
                if layer === content as AnyObject {
                    return true
                }
            case .view(let view):
                if view === content as AnyObject {
                    return true
                }
            default:
                continue
            }
        }
        return false
    }
    
    // MARK: - Text Selection
    
    private func updateSelectionView() {
        guard let selectionView = selectionView else { return }
        
        let selectedRange = self.selectedRange
        selectionView.isHidden = !isSelectable || selectedRange.location == NSNotFound
        
        if selectionView.isHidden {
            return
        }
        
        let renderer = currentRenderer
        
        let selectionRects = renderer.selectionRects(for: selectedRange)
        selectionRects.forEach { selectionRect in
            selectionRect.rect = convertRect(fromTextKit: selectionRect.rect, forBounds: bounds, textSize: renderer.size)
        }
        
        let startGrabberHeight: CGFloat
        if selectionRects.count > 1 {
            let startLineFragmentRect = renderer.lineFragmentRect(
                forCharacterAt: selectedRange.location,
                effectiveRange: nil
            )
            startGrabberHeight = startLineFragmentRect.height
        } else {
            let startLineFragmentUsedRect = renderer.lineFragmentUsedRect(
                forCharacterAt: selectedRange.location,
                effectiveRange: nil
            )
            startGrabberHeight = startLineFragmentUsedRect.height
        }
        
        let endLineFragmentUsedRect = renderer.lineFragmentUsedRect(
            forCharacterAt: NSMaxRange(selectedRange) - 1,
            effectiveRange: nil
        )
        
        selectionView.updateSelectionRects(
            selectionRects,
            startGrabberHeight: startGrabberHeight,
            endGrabberHeight: endLineFragmentUsedRect.height
        )
    }
    
    open var isMenuVisible: Bool {
        switch menuType {
        case .system:
            return UIMenuController.shared.isMenuVisible
        case .custom:
            return delegate?.menuVisible(for: self) ?? false
        case .none:
            return false
        }
    }
    
    open override var tintColor: UIColor! {
        didSet {
            selectionView?.tintColor = tintColor
        }
    }

}

fileprivate extension RELabel {
    nonisolated static let asyncFadeDuration: TimeInterval = 0.08
    nonisolated static let asyncFadeAnimationKey = "contents"
    static var releaseQueue: DispatchQueue {
        return .global(qos: .background)
    }
    static let rendererCache: MemoryCache<TextRendererKey, TextRenderer> = {
        let cache = MemoryCache<TextRendererKey, TextRenderer>()
        cache.countLimit = 200
        return cache
    }()
    
    static let textSizeCache: MemoryCache<TextRendererKey, CGSize> = {
        let cache = MemoryCache<TextRendererKey, CGSize>()
        cache.countLimit = 1000
        return cache
    }()
    
    static func rendererForAttributes(_ attributes: TextRenderAttributes, constrainedSize: CGSize) -> TextRenderer {
        var constrainedSize = constrainedSize
        if constrainedSize.width < CGFloat.ulpOfOne || constrainedSize.height < CGFloat.ulpOfOne {
            constrainedSize = .init(width: 0.1, height: 0.1)
        }
        
        let key = TextRendererKey(attributes: attributes, constrainedSize: constrainedSize)
        
        if let renderer = rendererCache.object(forKey: key) {
            return renderer
        }
        
        let renderer = TextRenderer(renderAttributes: attributes, constrainedSize: constrainedSize)
        rendererCache.setObject(renderer, forKey: key)
        return renderer
    }
    
    static func cacheRenderer(_ renderer: TextRenderer, attributes: TextRenderAttributes, constrainedSize: CGSize) {
        let key = TextRendererKey(attributes: attributes, constrainedSize: constrainedSize)
        rendererCache.setObject(renderer, forKey: key)
    }
    
    static func textSize(for key: TextRendererKey) -> CGSize? {
        return textSizeCache.object(forKey: key)
    }
    
    static func cacheTextSize(for key: TextRendererKey, textSize: CGSize) {
        textSizeCache.setObject(textSize, forKey: key)
    }
    
    static func prepareTruncationText(
        forDrawing attributedText: NSAttributedString?,
        _ truncationText: NSAttributedString
    ) -> NSAttributedString {
        let truncationMutableString = NSMutableAttributedString(attributedString: truncationText)
        if let attributedText = attributedText, attributedText.length > 0 {
            let originalStringLength = attributedText.length
            let originalStringAttributes = attributedText.attributes(at: originalStringLength - 1, effectiveRange: nil)
            
            truncationText.enumerateAttributes(in: NSRange(location: 0, length: truncationText.length), options: []) { attributes, range, _ in
                var futureTruncationAttributes = originalStringAttributes
                for (key, value) in attributes {
                    futureTruncationAttributes[key] = value
                }
                truncationMutableString.setAttributes(futureTruncationAttributes, range: range)
            }
        }
        
        return truncationMutableString
    }
}


// MARK: - RELabel Extensions

extension RELabel: TextInteractable {
    /// Composed by truncationAttributedToken and additionalTruncationAttributedMessage.
    public var truncationAttributedText: NSAttributedString {
        if _truncationAttributedText == nil {
            _truncationAttributedText = Self.truncationAttributedText(
                withTokenAndAdditionalMessage: attributedText,
                token: truncationAttributedToken,
                additionalMessage: additionalTruncationAttributedMessage
            )
        }
        return _truncationAttributedText!
    }
    
    public func shouldInteractLink(with linkRange: NSRange, for attributedText: NSAttributedString) -> Bool {
        var shouldInteractLink = true
        if let delegate = delegate {
            if let value = attributedText.attribute(.textLink, at: linkRange.location, effectiveRange: nil) as? TextLink {
                shouldInteractLink = delegate.label(self, shouldInteractWith: value, for: attributedText, in: linkRange)
            } else {
                shouldInteractLink = false
            }
        }
        return shouldInteractLink
    }
    
    public func highlightedLinkTextAttributes(
        with linkRange: NSRange,
        for attributedText: NSAttributedString
    ) -> [NSAttributedString.Key : Any] {
        var textAttributes = highlightedLinkTextAttributes ?? [:]
        if let delegate = delegate {
            if let value = attributedText.attribute(.textLink, at: linkRange.location, effectiveRange: nil) as? TextLink {
                if let attributes = delegate.label(self, highlightedTextAttributesWith: value, for: attributedText, in: linkRange) {
                    textAttributes = attributes
                }
            }
        }
        return textAttributes
    }
    
    public func tapLink(with linkRange: NSRange, for attributedText: NSAttributedString) {
        if let delegate = delegate {
            if let value = attributedText.attribute(.textLink, at: linkRange.location, effectiveRange: nil) as? TextLink {
                delegate.label(self, didInteractWith: value, for: attributedText, in: linkRange, interaction: .tap)
            }
        }
    }
    
    public func longPressLink(with linkRange: NSRange, for attributedText: NSAttributedString) {
        if let delegate = delegate {
            if let value = attributedText.attribute(.textLink, at: linkRange.location, effectiveRange: nil) as? TextLink {
                delegate.label(self, didInteractWith: value, for: attributedText, in: linkRange, interaction: .longPress)
            }
        }
    }
    
    public func linkRange(at point: CGPoint, inTruncation: UnsafeMutablePointer<Bool>?) -> NSRange {
        if !state.contentsUpdated {
            return NSRange(location: NSNotFound, length: 0)
        }
        
        let renderer = currentRenderer
        
        let point = convertPoint(toTextKit: point, forBounds: bounds, textSize: renderer.size)
        
        var linkRange = NSRange()
        let link = renderer.attribute(.textLink, at: point, effectiveRange: &linkRange, inTruncation: inTruncation)
#if DEBUG
        if linkRange.location != NSNotFound {
            assert(link is TextLink, "The value for RETextLinkAttributeName must be of type TextLink.")
        }
#endif
        return linkRange
    }
    
    public func selection(at point: CGPoint) -> Bool {
        guard let selectionView = selectionView, !selectionView.isHidden else {
            return false
        }
        return selectionView.isSelectionRectsContainsPoint(point) || selectionView.isGrabberContainsPoint(point)
    }
    
    public func grabberType(at point: CGPoint) -> TextSelectionGrabberType {
        guard let selectionView = selectionView else {
            return .none
        }
        
        if selectionView.isStartGrabberContainsPoint(point) {
            return .start
        } else if selectionView.isEndGrabberContainsPoint(point) {
            return .end
        }
        
        return .none
    }
    
    public func grabberRect(for grabberType: TextSelectionGrabberType) -> CGRect {
        guard let selectionView = selectionView else {
            return .zero
        }
        
        switch grabberType {
        case .start:
            return selectionView.startGrabber.frame
        case .end:
            return selectionView.endGrabber.frame
        case .none:
            return .zero
        }
    }
    
    public func characterIndex(for point: CGPoint) -> Int {
        let renderer = currentRenderer
        
        let point = convertPoint(toTextKit: point, forBounds: bounds, textSize: renderer.size)
        let pointX = min(point.x, renderer.size.width) - 1
        let pointY = min(point.y, renderer.size.height) - 1
        let adjustedPoint = CGPoint(
            x: pointX < 0 ? 1 : pointX,
            y: pointY < 0 ? 1 : pointY
        )
        
        return renderer.characterIndex(for: adjustedPoint)
    }
    
    public func beginSelection(at point: CGPoint) {
        let renderer = currentRenderer
        let point = convertPoint(toTextKit: point, forBounds: bounds, textSize: renderer.size)
        let characterIndex = renderer.characterIndex(for: point)
        
        if characterIndex == NSNotFound {
            return
        }
        
        var selectedRange = renderer.rangeEnclosingCharacter(for: characterIndex)
        if selectedRange.location == NSNotFound {
            return
        }
        
        if let delegate = delegate {
            delegate.labelWillBeginSelection(self, selectedRange: &selectedRange)
        }
        
        self.selectedRange = selectedRange
        becomeFirstResponder()
        showMenu()
    }
    
    public func updateSelection(with range: NSRange) {
        selectedRange = range
    }
    
    public func endSelection() {
        selectedRange = NSRange(location: NSNotFound, length: 0)
        resignFirstResponder()
        hideMenu()
    }
}

extension RELabel: TextInteractionManagerDelegate {
    
    func interactionManager(
        _ interactionManager: TextInteractionManager,
        didUpdateHighlightedAttributedText highlightedAttributedText: NSAttributedString?
    ) {
        invalidateAttachments()
        setNeedsUpdateContentsWithoutClearContents()
    }
}

extension RELabel: @preconcurrency AsyncLayerDelegate {
    
    public func newAsyncDisplayTask() -> AsyncLayerDisplayTask {
        let bounds = self.bounds
        let displaysAsync = displaysAsynchronously
        let fadeForAsync = displaysAsync && fadeOnAsynchronouslyDisplay
        let contentsUptodate = state.contentsUpdated
        let debugOption = self.debugOption
        let attachmentsNeedsUpdate = state.attachmentsNeedsUpdate
        
        let renderer = currentRenderer
        let point = convertPoint(fromTextKit: .zero, forBounds: bounds, textSize: renderer.size)
        
        return AsyncLayerDisplayTask(
            displaysAsynchronously: displaysAsync,
            willDisplay: { [weak self] layer in
                guard let self = self else { return }
                layer.removeAnimation(forKey: Self.asyncFadeAnimationKey)
                if attachmentsNeedsUpdate {
                    syncOnMain {
                        self.clearAttachmentViewsAndLayers(with: renderer.attachmentsInfo)
                    }
                }
            },
            display: { context, size, isCancelled in
                if isCancelled() {
                    return
                }
                renderer.draw(at: point, debugOption: debugOption)
            },
            didDisplay: { [weak self] layer, finished in
                guard let self = self else { return }
                if !finished {
                    syncOnMain {
                        self.clearAttachmentViewsAndLayers()
                    }
                    return
                }
                
                if attachmentsNeedsUpdate {
                    syncOnMain {
                        self.state.attachmentsNeedsUpdate = false
                        
                        let point = self.convertPoint(fromTextKit: .zero, forBounds: bounds, textSize: renderer.size)
                        renderer.drawViewAndLayer(at: point, referenceTextView: self)
                        
                        for info in renderer.attachmentsInfo {
                            switch info.attachment.content {
                            case .view(let view):
                                attachmentViews.append(view)
                            case .layer(let contentLayer):
                                attachmentLayers.append(contentLayer)
                            default:
                                break
                            }
                        }
                    }
                }
                
                if !contentsUptodate {
                    syncOnMain {
                        self.state.contentsUpdated = true
                    }
                }
                
                if fadeForAsync {
                    let transition = CATransition()
                    transition.duration = Self.asyncFadeDuration
                    transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    transition.type = .fade
                    layer.add(transition, forKey: Self.asyncFadeAnimationKey)
                }
                syncOnMain {
                    self.updateSelectionView()
                }
            }
        )
    }
}

extension RELabel: @preconcurrency TextDebugTarget {
    public func setDebugOption(_ option: TextDebugOption?) {
        debugOption = option
    }
}
