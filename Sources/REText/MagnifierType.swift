//
//  MagnifierType.swift
//  REText
//
//  Created by phoenix on 2025/4/18.
//


import UIKit

/// Magnifier type
enum MagnifierType: Int {
    case caret  /// Circular magnifier
    case ranged /// Round rectangle magnifier
}

/// A magnifier view which can be displayed in `TextEffectWindow`.
///
/// Use `magnifier(type:)` to create instance.
/// Typically, you should not use this class directly.
class TextMagnifier: UIView {
    
    /// Type of magnifier
    var type: MagnifierType { fatalError("Subclass must override") }
    
    /// The 'best' size for magnifier view.
    var fitsSize: CGSize { fatalError("Subclass must override") }
    
    /// The 'best' snapshot image size for magnifier.
    var snapshotSize: CGSize { fatalError("Subclass must override") }
    
    /// The image in magnifier (readwrite).
    var snapshot: UIImage?
    
    /// The coordinate based view.
    weak var hostView: UIView?
    
    /// The snapshot capture center in `hostView`.
    var hostCaptureCenter: CGPoint = .zero
    
    /// The popover center in `hostView`.
    var hostPopoverCenter: CGPoint = .zero
    
    /// The host view is vertical form.
    var hostVerticalForm: Bool = false
    
    /// A hint for `TextEffectWindow` to disable capture.
    var captureDisabled: Bool = false
    
    /// Show fade animation when the snapshot image changed.
    var captureFadeAnimation: Bool = false
    
    /// Create a mangifier with the specified type.
    /// - Parameter type: The magnifier type.
    static func magnifier(type: MagnifierType) -> TextMagnifier {
        switch type {
        case .caret: return TextCaretMagnifier()
        case .ranged: return TextRangedMagnifier()
        }
    }
    
    override init(frame: CGRect) {
        // class cluster
        guard Swift.type(of: self) != TextMagnifier.self else {
            fatalError("Attempting to instantiate an abstract class. Use a concrete subclass instead.")
        }
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Caret Magnifier

private let captureDisableFadeTime: TimeInterval = 0.1

class TextCaretMagnifier: TextMagnifier {
    private let contentView: UIImageView
    private let coverView: UIImageView
    
    private static let multiple: CGFloat = 1.2
    private static let diameter: CGFloat = 113.0
    private static let padding: CGFloat = 7.0
    private static var size: CGSize {
        return CGSize(width: diameter + padding * 2, height: diameter + padding * 2)
    }
    
    override init(frame: CGRect) {
        contentView = UIImageView()
        coverView = UIImageView()
        
        super.init(frame: frame)
        
        contentView.frame = CGRect(x: Self.padding, y: Self.padding, width: Self.diameter, height: Self.diameter)
        contentView.layer.cornerRadius = Self.diameter / 2
        contentView.clipsToBounds = true
        addSubview(contentView)
        
        coverView.frame = CGRect(origin: .zero, size: Self.size)
        coverView.image = TextCaretMagnifier.coverImage
        addSubview(coverView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init() {
        self.init(frame: .zero)
        self.frame = CGRect(origin: .zero, size: self.sizeThatFits(.zero))
    }
    
    override var type: MagnifierType {
        return .caret
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return Self.size
    }
    
    override var snapshot: UIImage? {
        get {
            return contentView.image
        }
        set {
            if self.captureFadeAnimation {
                contentView.layer.removeAnimation(forKey: "contents")
                let animation = CABasicAnimation()
                animation.duration = captureDisableFadeTime
                animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
                contentView.layer.add(animation, forKey: "contents")
            }
            contentView.image = newValue
        }
    }
    
    override var snapshotSize: CGSize {
        let length = floor(Self.diameter / 1.2)
        return CGSize(width: length, height: length)
    }
    
    override var fitsSize: CGSize {
        return self.sizeThatFits(.zero)
    }
    
    private static let coverImage: UIImage = {
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: padding, dy: padding)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let ctx = context.cgContext
            
            let boxPath = CGPath(rect: CGRect(origin: .zero, size: size), transform: nil)
            let fillPath = CGPath(ellipseIn: rect, transform: nil)
            let strokePath = CGPath(ellipseIn: rect.pixelHalf(), transform: nil)
            
            // inner shadow
            ctx.saveGState()
            do {
                let blurRadius: CGFloat = 25
                let offset = CGSize(width: 0, height: 15)
                let shadowColor = UIColor(white: 0, alpha: 0.16).cgColor
                let opaqueShadowColor = shadowColor.copy(alpha: 1.0)!
                
                ctx.addPath(fillPath)
                ctx.clip()
                ctx.setAlpha(shadowColor.alpha)
                ctx.beginTransparencyLayer(auxiliaryInfo: nil)
                do {
                    ctx.setShadow(offset: offset, blur: blurRadius, color: opaqueShadowColor)
                    ctx.setBlendMode(.sourceOut)
                    ctx.setFillColor(opaqueShadowColor)
                    ctx.addPath(fillPath)
                    ctx.fillPath()
                }
                ctx.endTransparencyLayer()
            }
            ctx.restoreGState()
            
            // outer shadow
            ctx.saveGState()
            do {
                ctx.addPath(boxPath)
                ctx.addPath(fillPath)
                ctx.clip(using: .evenOdd)
                let shadowColor = UIColor(white: 0, alpha: 0.32).cgColor
                ctx.setShadow(offset: CGSize(width: 0, height: 1.5), blur: 3, color: shadowColor)
                ctx.beginTransparencyLayer(auxiliaryInfo: nil)
                do {
                    ctx.addPath(fillPath)
                    UIColor(white: 0.7, alpha: 1.0).setFill()
                    ctx.fillPath()
                }
                ctx.endTransparencyLayer()
            }
            ctx.restoreGState()
            
            // stroke
            ctx.saveGState()
            do {
                ctx.addPath(strokePath)
                UIColor(white: 0.6, alpha: 1).setStroke()
                ctx.setLineWidth(CGFloat.fromPixel(1))
                ctx.strokePath()
            }
            ctx.restoreGState()
        }
    }()
}

// MARK: - Ranged Magnifier

class TextRangedMagnifier: TextMagnifier {
    private let contentView: UIImageView
    private let coverView: UIImageView
    
    private static let multiple: CGFloat = 1.2
    private static let size = CGSize(width: 141, height: 60)
    private static let padding: CGFloat = CGFloat(6).pixelHalf()
    private static let radius: CGFloat = 6.0
    private static let height: CGFloat = 32.0
    private static let arrow: CGFloat = 14.0
    
    override init(frame: CGRect) {
        contentView = UIImageView()
        coverView = UIImageView()
        
        super.init(frame: frame)
        
        contentView.frame = CGRect(x: Self.padding, y: Self.padding, width: Self.size.width - 2 * Self.padding, height: Self.height)
        contentView.layer.cornerRadius = Self.radius
        contentView.clipsToBounds = true
        addSubview(contentView)
        
        coverView.frame = CGRect(origin: .zero, size: Self.size)
        coverView.image = TextRangedMagnifier.coverImage
        addSubview(coverView)
        
        self.layer.anchorPoint = CGPoint(x: 0.5, y: 1.2)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init() {
        self.init(frame: .zero)
        self.frame = CGRect(origin: .zero, size: self.sizeThatFits(.zero))
    }
    
    override var type: MagnifierType {
        return .ranged
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return Self.size
    }
    
    override var snapshot: UIImage? {
        get {
            return contentView.image
        }
        set {
            if self.captureFadeAnimation {
                contentView.layer.removeAnimation(forKey: "contents")
                let animation = CABasicAnimation()
                animation.duration = captureDisableFadeTime
                animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
                contentView.layer.add(animation, forKey: "contents")
            }
            contentView.image = newValue
        }
    }
    
    override var snapshotSize: CGSize {
        var size = CGSize.zero
        size.width = floor((Self.size.width - 2 * Self.padding) / Self.multiple)
        size.height = floor(Self.height / Self.multiple)
        return size
    }
    
    override var fitsSize: CGSize {
        return self.sizeThatFits(.zero)
    }
    
    private static let coverImage: UIImage = {
        let rect = CGRect(origin: .zero, size: size)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let ctx = context.cgContext
            
            let boxPath = CGPath(rect: rect, transform: nil)
            
            let path = CGMutablePath()
            path.move(to: CGPoint(x: padding + radius, y: padding))
            path.addLine(to: CGPoint(x: size.width - padding - radius, y: padding))
            path.addQuadCurve(to: CGPoint(x: size.width - padding, y: padding + radius), control: CGPoint(x: size.width - padding, y: padding))
            path.addLine(to: CGPoint(x: size.width - padding, y: height))
            path.addCurve(to: CGPoint(x: size.width - padding - radius, y: padding + height),
                          control1: CGPoint(x: size.width - padding, y: padding + height),
                          control2: CGPoint(x: size.width - padding - radius, y: padding + height))
            path.addLine(to: CGPoint(x: size.width / 2 + arrow, y: padding + height))
            path.addLine(to: CGPoint(x: size.width / 2, y: padding + height + arrow))
            path.addLine(to: CGPoint(x: size.width / 2 - arrow, y: padding + height))
            path.addLine(to: CGPoint(x: padding + radius, y: padding + height))
            path.addQuadCurve(to: CGPoint(x: padding, y: height), control: CGPoint(x: padding, y: padding + height))
            path.addLine(to: CGPoint(x: padding, y: padding + radius))
            path.addQuadCurve(to: CGPoint(x: padding + radius, y: padding), control: CGPoint(x: padding, y: padding))
            path.closeSubpath()
            
            let arrowPath = CGMutablePath()
            arrowPath.move(to: CGPoint(x: size.width / 2 - arrow, y: padding.pixelFloor() + height))
            arrowPath.addLine(to: CGPoint(x: size.width / 2 + arrow, y: padding.pixelFloor() + height))
            arrowPath.addLine(to: CGPoint(x: size.width / 2, y: padding + height + arrow))
            arrowPath.closeSubpath()
            
            // inner shadow
            ctx.saveGState()
            do {
                let blurRadius: CGFloat = 25
                let offset = CGSize(width: 0, height: 15)
                let shadowColor = UIColor(white: 0, alpha: 0.16).cgColor
                let opaqueShadowColor = shadowColor.copy(alpha: 1.0)!
                
                ctx.addPath(path)
                ctx.clip()
                ctx.setAlpha(shadowColor.alpha)
                ctx.beginTransparencyLayer(auxiliaryInfo: nil)
                do {
                    ctx.setShadow(offset: offset, blur: blurRadius, color: opaqueShadowColor)
                    ctx.setBlendMode(.sourceOut)
                    ctx.setFillColor(opaqueShadowColor)
                    ctx.addPath(path)
                    ctx.fillPath()
                }
                ctx.endTransparencyLayer()
            }
            ctx.restoreGState()
            
            // outer shadow
            ctx.saveGState()
            do {
                ctx.addPath(boxPath)
                ctx.addPath(path)
                ctx.clip(using: .evenOdd)
                let shadowColor = UIColor(white: 0, alpha: 0.32).cgColor
                ctx.setShadow(offset: CGSize(width: 0, height: 1.5), blur: 3, color: shadowColor)
                ctx.beginTransparencyLayer(auxiliaryInfo: nil)
                do {
                    ctx.addPath(path)
                    UIColor(white: 0.7, alpha: 1.0).setFill()
                    ctx.fillPath()
                }
                ctx.endTransparencyLayer()
            }
            ctx.restoreGState()
            
            // arrow
            ctx.saveGState()
            do {
                ctx.addPath(arrowPath)
                UIColor(white: 1, alpha: 0.95).set()
                ctx.fillPath()
            }
            ctx.restoreGState()
            
            // stroke
            ctx.saveGState()
            do {
                ctx.addPath(path)
                UIColor(white: 0.6, alpha: 1).setStroke()
                ctx.setLineWidth(CGFloat.fromPixel(1))
                ctx.strokePath()
            }
            ctx.restoreGState()
        }
    }()
}
