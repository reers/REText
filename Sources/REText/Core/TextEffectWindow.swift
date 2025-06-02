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

class TextEffectWindowViewController: UIViewController {
    override var shouldAutorotate: Bool {
        return false
    }
}

class TextEffectWindow: UIWindow {
    
    private static var _sharedWindow: TextEffectWindow?
    
    static var shared: TextEffectWindow {
        if let window = _sharedWindow {
            return window
        }
        
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
        
        guard let scene = windowScene else {
            let window = TextEffectWindow()
            _sharedWindow = window
            return window
        }
        
        let window = TextEffectWindow(windowScene: scene)
        _sharedWindow = window
        return window
    }
    
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        setupWindow()
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupWindow()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupWindow() {
        self.frame = UIScreen.main.bounds
        self.isUserInteractionEnabled = false
        self.windowLevel = .statusBar + 1
        self.rootViewController = TextEffectWindowViewController()
        self.isOpaque = false
        self.backgroundColor = .clear
        self.layer.backgroundColor = UIColor.clear.cgColor
        self.isHidden = false
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    @objc
    func _canAffectStatusBarAppearance() -> Bool {
        return false
    }
    
    /// Show the magnifier in this window with a 'popup' animation.
    func showMagnifier(_ magnifier: TextMagnifier?) {
        guard let mag = magnifier else { return }
        if mag.superview !== self {
            addSubview(mag)
        }
        let rotation = updateMagnifier(mag)
        let center = convert(point: mag.hostPopoverCenter, fromViewOrWindow: mag.hostView)
        var trans = CGAffineTransform(rotationAngle: rotation)
        trans = trans.scaledBy(x: 0.3, y: 0.3)
        mag.transform = trans
        mag.center = center
        if mag.type == .ranged {
            mag.alpha = 0
        }
        let time: TimeInterval = (mag.type == .caret) ? 0.08 : 0.1
        UIView.animate(
            withDuration: time,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState],
            animations: {
                if mag.type == .caret {
                    var newCenter = CGPoint(x: 0, y: -mag.fitsSize.height / 2)
                    newCenter = newCenter.applying(CGAffineTransform(rotationAngle: rotation))
                    newCenter.x += center.x
                    newCenter.y += center.y
                    mag.center = self.correctedCenter(newCenter, for: mag, rotation: rotation)
                } else {
                    mag.center = self.correctedCenter(center, for: mag, rotation: rotation)
                }
                mag.transform = CGAffineTransform(rotationAngle: rotation)
                mag.alpha = 1
            },
            completion: nil
        )
    }
    
    /// Update the magnifier content and position. @param magnifier A magnifier.
    func moveMagnifier(_ magnifier: TextMagnifier?) {
        guard let mag = magnifier else { return }
        let rotation = updateMagnifier(mag)
        let center = convert(mag.hostPopoverCenter, from: mag.hostView)
        if mag.type == .caret {
            var newCenter = CGPoint(x: 0, y: -mag.fitsSize.height / 2)
            newCenter = newCenter.applying(CGAffineTransform(rotationAngle: rotation))
            newCenter.x += center.x
            newCenter.y += center.y
            mag.center = correctedCenter(newCenter, for: mag, rotation: rotation)
        } else {
            mag.center = correctedCenter(center, for: mag, rotation: rotation)
        }
        mag.transform = CGAffineTransform(rotationAngle: rotation)
    }
    
    /// Remove the magnifier from this window with a 'shrink' animation. @param magnifier A magnifier.
    func hideMagnifier(_ magnifier: TextMagnifier?) {
        guard let mag = magnifier, mag.superview === self else { return }
        let rotation = updateMagnifier(mag)
        let center = convert(mag.hostPopoverCenter, from: mag.hostView)
        let time: TimeInterval = (mag.type == .caret) ? 0.20 : 0.15
        UIView.animate(
            withDuration: time,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState],
            animations: {
                var trans = CGAffineTransform(rotationAngle: rotation)
                trans = trans.scaledBy(x: 0.01, y: 0.01)
                mag.transform = trans
                if mag.type == .caret {
                    var newCenter = CGPoint(x: 0, y: -mag.fitsSize.height / 2)
                    newCenter = newCenter.applying(CGAffineTransform(rotationAngle: rotation))
                    newCenter.x += center.x
                    newCenter.y += center.y
                    mag.center = self.correctedCenter(newCenter, for: mag, rotation: rotation)
                } else {
                    mag.center = self.correctedCenter(center, for: mag, rotation: rotation)
                    mag.alpha = 0
                }
            },
            completion: { finished in
                if finished {
                    mag.removeFromSuperview()
                    mag.transform = .identity
                    mag.alpha = 1
                }
            })
    }
    
    // MARK: - Private
    
    private func correctedCenter(_ center: CGPoint, for mag: TextMagnifier, rotation: CGFloat) -> CGPoint {
        var center = center
        var degree = rotation * 180 / .pi
        degree /= 45.0
        if degree < 0 { degree += CGFloat(Int(-degree / 8.0 + 1) * 8) }
        if degree > 8 { degree -= CGFloat(Int(degree / 8.0) * 8) }
        
        let caretExt: CGFloat = 10
        if degree <= 1 || degree >= 7 { // top
            if mag.type == .caret {
                if center.y < caretExt { center.y = caretExt }
            } else if mag.type == .ranged {
                if center.y < mag.bounds.size.height { center.y = mag.bounds.size.height }
            }
        } else if 1 < degree && degree < 3 { // right
            if mag.type == .caret {
                if center.x > bounds.size.width - caretExt { center.x = bounds.size.width - caretExt }
            } else if mag.type == .ranged {
                if center.x > bounds.size.width - mag.bounds.size.height { center.x = bounds.size.width - mag.bounds.size.height }
            }
        } else if 3 <= degree && degree <= 5 { // bottom
            if mag.type == .caret {
                if center.y > bounds.size.height - caretExt { center.y = bounds.size.height - caretExt }
            } else if mag.type == .ranged {
                if center.y > mag.bounds.size.height { center.y = mag.bounds.size.height }
            }
        } else if 5 < degree && degree < 7 { // left
            if mag.type == .caret {
                if center.x < caretExt { center.x = caretExt }
            } else if mag.type == .ranged {
                if center.x < mag.bounds.size.height { center.x = mag.bounds.size.height }
            }
        }
        return center
    }
    
    /// Capture screen snapshot and set it to magnifier.
    /// @return Magnifier rotation radius.
    @MainActor
    private func updateMagnifier(_ mag: TextMagnifier) -> CGFloat {
        guard let hostView = mag.hostView else { return 0 }
        guard let hostWindow = (hostView is UIWindow) ? (hostView as? UIWindow) : hostView.window else { return 0 }
        let captureCenter = convert(point: mag.hostCaptureCenter, fromViewOrWindow: hostView)
        var captureRect = CGRect(origin: .zero, size: mag.snapshotSize)
        captureRect.origin.x = captureCenter.x - captureRect.size.width / 2
        captureRect.origin.y = captureCenter.y - captureRect.size.height / 2
        
        let trans = REText.affineTransformFromViews(from: hostView, to: self)
        let rotation = atan2(trans.b, trans.a)
        
        if mag.captureDisabled {
            if mag.snapshot == nil || mag.snapshot?.size.width ?? 0 > 1 {
                struct Placeholder {
                    nonisolated(unsafe) static var image: UIImage?
                }
                if Placeholder.image == nil {
                    let rect = mag.bounds
                    let renderer = UIGraphicsImageRenderer(size: rect.size)
                    Placeholder.image = renderer.image { ctx in
                        UIColor(white: 1, alpha: 0.8).set()
                        ctx.fill(rect)
                    }
                }
                mag.captureFadeAnimation = true
                mag.snapshot = Placeholder.image
                mag.captureFadeAnimation = false
            }
            return rotation
        }
        
        let renderer = UIGraphicsImageRenderer(size: captureRect.size)
        let image = renderer.image { ctx in
            let context = ctx.cgContext
            var tp = CGPoint(x: captureRect.size.width / 2, y: captureRect.size.height / 2)
            tp = tp.applying(CGAffineTransform(rotationAngle: rotation))
            context.rotate(by: -rotation)
            context.translateBy(x: tp.x - captureCenter.x, y: tp.y - captureCenter.y)
            context.concatenate(REText.affineTransformFromViews(from: hostWindow, to: self))
            hostWindow.layer.render(in: context)
        }
        if mag.snapshot?.size.width == 1 {
            mag.captureFadeAnimation = true
        }
        mag.snapshot = image
        mag.captureFadeAnimation = false
        return rotation
    }
}


