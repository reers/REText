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

public enum Content: Hashable {
    case image(UIImage)
    case view(UIView)
    case layer(CALayer)
    
    @MainActor
    var size: CGSize {
        switch self {
        case .image(let image): return image.size
        case .view(let view): return view.bounds.size
        case .layer(let layer): return layer.bounds.size
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .image(let image):
            hasher.combine(0)
            hasher.combine(image)
        case .view(let view):
            hasher.combine(1)
            hasher.combine(ObjectIdentifier(view))
        case .layer(let layer):
            hasher.combine(2)
            hasher.combine(ObjectIdentifier(layer))
        }
    }
}

open class Attachment: NSTextAttachment, @unchecked Sendable {
    
    open var verticalAligment: VerticalAlignment = .center
    open var contentMode: UIView.ContentMode = .scaleToFill
    open var contentSize: CGSize = .zero
    open var contentInsets: UIEdgeInsets = .zero
    
    public init() {
        super.init(data: nil, ofType: nil)
        image = UIImage()
    }
    
    required public init?(coder: NSCoder) {
        super.init(data: nil, ofType: nil)
        image = UIImage()
    }
    
    open var content: Content? {
        didSet {
            guard content != oldValue else { return }
            syncOnMain { contentSize = content?.size ?? .zero }
        }
    }
    
    public var attachmentSize: CGSize {
        if bounds.size == .zero {
            return contentSize
        }
        return bounds.size
    }
    
    // MARK: - MPITextAttachmentContainer
    open override func attachmentBounds(
        for textContainer: NSTextContainer?,
        proposedLineFragment lineFrag: CGRect,
        glyphPosition position: CGPoint,
        characterIndex charIndex: Int
    ) -> CGRect {
        guard let layoutManager = textContainer?.layoutManager, let textStorage = layoutManager.textStorage else {
            return super.attachmentBounds(
                for: textContainer,
                proposedLineFragment: lineFrag,
                glyphPosition: position,
                characterIndex: charIndex
            )
        }
        
        let font = textStorage.attribute(
            .font,
            at: charIndex,
            effectiveRange: nil
        ) as? UIFont ?? .systemFont(ofSize: UIFont.systemFontSize)
        
        let attachmentSize = self.attachmentSize
        
        var y = font.descender
        
        switch verticalAligment {
        case .top:
            y -= attachmentSize.height - font.lineHeight
        case .center:
            y -= (attachmentSize.height - font.lineHeight) * 0.5
        case .bottom:
            break
        }
        
        return CGRect(origin: CGPoint(x: 0, y: y), size: attachmentSize)
    }
    
    @MainActor
    open func drawAttachment(
        in textContainer: NSTextContainer,
        textView: UIView,
        proposedRect: CGRect,
        characterIndex: UInt
    ) {
        var rect = proposedRect
        
        rect = rect.offsetBy(dx: bounds.origin.x, dy: bounds.origin.y)
        rect = rect.inset(by: contentInsets)
        rect = contentSize.fit(inRect: rect, mode: contentMode)
        rect = rect.pixelRound()
        
        drawAttachment(in: rect, textView: textView)
    }
    
    @MainActor
    open func drawAttachment(in rect: CGRect, textView: UIView) {
        switch content {
        case .image(let image):
            image.draw(in: rect)
        case .view(let view):
            if view.frame != rect {
                view.frame = rect
            }
            if view.superview != textView {
                textView.addSubview(view)
            }
        case .layer(let layer):
            if layer.frame != rect {
                layer.frame = rect
            }
            if layer.superlayer != textView.layer {
                textView.layer.addSublayer(layer)
            }
        default:
            break
        }
    }
}

extension Attachment {
    
    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(super.hash)
        if let content = content {
            hasher.combine(content)
        }
        hasher.combine(verticalAligment)
        hasher.combine(contentMode.rawValue)
        hasher.combine(contentSize.width)
        hasher.combine(contentSize.height)
        hasher.combine(bounds.origin.x)
        hasher.combine(bounds.origin.y)
        hasher.combine(bounds.size.width)
        hasher.combine(bounds.size.height)
        hasher.combine(contentInsets.top)
        hasher.combine(contentInsets.left)
        hasher.combine(contentInsets.bottom)
        hasher.combine(contentInsets.right)
        return hasher.finalize()
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard self !== object as AnyObject? else { return true }
        guard let other = object as? Attachment else { return false }
        guard super.isEqual(other) else { return false }
        
        return verticalAligment == other.verticalAligment
            && contentMode == other.contentMode
            && contentSize == other.contentSize
            && bounds == other.bounds
            && contentInsets == other.contentInsets
            && content == other.content
    }
}
