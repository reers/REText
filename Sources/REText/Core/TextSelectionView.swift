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

class TextSelectionGrabberKnob: UIView {
    
}

class TextSelectionGrabber: UIView {
    private static let grabberTouchHitTestExtend: CGFloat = 20.0
    private static let knobTouchHitTestExtend: CGFloat = 7.0
    
    var knob: TextSelectionGrabberKnob
    var knobDirection: UITextLayoutDirection = .up {
        didSet {
            updateKnob()
        }
    }

    var knobDiameter: CGFloat = 14 {
        didSet {
            var knobFrame = knob.frame
            knobFrame.size = CGSize(width: knobDiameter, height: knobDiameter)
            updateKnob()
        }
    }

    var grabberColor: UIColor? {
        didSet {
            backgroundColor = grabberColor
            knob.backgroundColor = grabberColor
        }
    }
    
    override init(frame: CGRect) {
        knob = TextSelectionGrabberKnob(frame: CGRect(x: 0, y: 0, width: knobDiameter, height: knobDiameter))
        super.init(frame: frame)
        addSubview(knob)
    }
    
    required init?(coder: NSCoder) {
        knob = TextSelectionGrabberKnob(frame: .zero)
        super.init(coder: coder)
        addSubview(knob)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateKnob()
    }
    
    var touchRect: CGRect {
        var rect = frame.insetBy(dx: -Self.grabberTouchHitTestExtend, dy: -Self.grabberTouchHitTestExtend)
        var insets = UIEdgeInsets.zero
        
        switch knobDirection {
        case .up:
            insets.top = -Self.knobTouchHitTestExtend
        case .right:
            insets.right = -Self.knobTouchHitTestExtend
        case .down:
            insets.bottom = -Self.knobTouchHitTestExtend
        case .left:
            insets.left = -Self.knobTouchHitTestExtend
        @unknown default:
            break
        }
        
        rect = rect.inset(by: insets)
        return rect
    }
    
    private func updateKnob() {
        var knobHidden = false
        var frame = knob.frame
        frame.size = CGSize(width: knobDiameter, height: knobDiameter)
        let offset: CGFloat = 0.5
        
        switch knobDirection {
        case .up:
            frame.origin.y = -frame.size.height + offset
            frame.origin.x = (bounds.size.width - frame.size.width) / 2
        case .right:
            frame.origin.x = bounds.size.width - offset
            frame.origin.y = (bounds.size.height - frame.size.height) / 2
        case .down:
            frame.origin.y = bounds.size.height - offset
            frame.origin.x = (bounds.size.width - frame.size.width) / 2
        case .left:
            frame.origin.x = -frame.size.width + offset
            frame.origin.y = (bounds.size.height - frame.size.height) / 2
        @unknown default:
            knobHidden = true
        }
        
        knob.frame = frame
        knob.isHidden = knobHidden
        knob.layer.cornerRadius = knobDiameter * 0.5
    }
}

class TextSelectionView: UIView {
    
    private static let selectionAlpha: CGFloat = 0.2
   
    var startGrabber: TextSelectionGrabber
    var endGrabber: TextSelectionGrabber
    private var selectionViews: [UIView] = []
    
    var grabberColor: UIColor? {
        didSet {
            startGrabber.grabberColor = grabberColor
            endGrabber.grabberColor = grabberColor
        }
    }
    
    var selectionColor: UIColor? {
        didSet {
            if oldValue != selectionColor {
                selectionViews.forEach { $0.backgroundColor = selectionColor }
            }
        }
    }
    
    var verticalForm: Bool = false {
        didSet {
            if oldValue != verticalForm {
                startGrabber.knobDirection = verticalForm ? .right : .up
                endGrabber.knobDirection = verticalForm ? .left : .down
            }
        }
    }
    
    var grabberWidth: CGFloat = 2.0 {
        didSet {
            var startGrabberFrame = startGrabber.frame
            var endGrabberFrame = endGrabber.frame
            
            if verticalForm {
                startGrabberFrame.origin.y = startGrabberFrame.maxY - grabberWidth
                startGrabberFrame.size.height = grabberWidth
                endGrabberFrame.size.height = grabberWidth
            } else {
                startGrabberFrame.origin.x = startGrabberFrame.maxX - grabberWidth
                startGrabberFrame.size.width = grabberWidth
                endGrabberFrame.size.width = grabberWidth
            }
            
            startGrabber.frame = startGrabberFrame
            endGrabber.frame = endGrabberFrame
        }
    }
    
    private(set) var selectionRects: [TextSelectionRect]?
    
    override init(frame: CGRect) {
        let grabberColor = UIColor(red: 69/255.0, green: 111/255.0, blue: 238/255.0, alpha: 1)
        
        startGrabber = TextSelectionGrabber()
        startGrabber.knobDirection = .up
        startGrabber.isHidden = true
        startGrabber.grabberColor = grabberColor
        startGrabber.layer.cornerRadius = grabberWidth * 0.5
        
        endGrabber = TextSelectionGrabber()
        endGrabber.knobDirection = .down
        endGrabber.isHidden = true
        endGrabber.grabberColor = grabberColor
        endGrabber.layer.cornerRadius = grabberWidth * 0.5
        
        super.init(frame: frame)
        
        isUserInteractionEnabled = false
        clipsToBounds = false
        selectionColor = grabberColor.withAlphaComponent(Self.selectionAlpha)
        
        addSubview(startGrabber)
        addSubview(endGrabber)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func isGrabberContainsPoint(_ point: CGPoint) -> Bool {
        return isStartGrabberContainsPoint(point) || isEndGrabberContainsPoint(point)
    }
    
    func isStartGrabberContainsPoint(_ point: CGPoint) -> Bool {
        if isHidden { return false }
        if startGrabber.isHidden { return false }
        
        let startRect = startGrabber.touchRect
        let endRect = endGrabber.touchRect
        
        if startRect.intersects(endRect) {
            let distStart = point.distance(to: startRect.center)
            let distEnd = point.distance(to: endRect.center)
            if distEnd <= distStart { return false }
        }
        
        return startRect.contains(point)
    }
    
    func isEndGrabberContainsPoint(_ point: CGPoint) -> Bool {
        if isHidden { return false }
        if endGrabber.isHidden { return false }
        
        let startRect = startGrabber.touchRect
        let endRect = endGrabber.touchRect
        
        if startRect.intersects(endRect) {
            let distStart = point.distance(to: startRect.center)
            let distEnd = point.distance(to: endRect.center)
            if distEnd > distStart { return false }
        }
        
        return endRect.contains(point)
    }
    
    func isSelectionRectsContainsPoint(_ point: CGPoint) -> Bool {
        if isHidden { return false }
        guard let rects = selectionRects, !rects.isEmpty else { return false }
        for rect in rects {
            if rect.rect.contains(point) { return true }
        }
        return false
    }
    
    func updateSelectionRects(
        _ selectionRects: [TextSelectionRect],
        startGrabberHeight: CGFloat,
        endGrabberHeight: CGFloat
    ) {
        self.selectionRects = selectionRects
        
        selectionViews.forEach { $0.removeFromSuperview() }
        selectionViews.removeAll()
        startGrabber.isHidden = true
        endGrabber.isHidden = true
        
        for selectionRect in selectionRects {
            var visualRect = selectionRect.rect
            visualRect = visualRect.standardized
            visualRect = visualRect.pixelRound()
            
            if selectionRect.containsStart || selectionRect.containsEnd {
                if selectionRect.containsStart {
                    startGrabber.isHidden = false
                    startGrabber.frame = grabberRect(
                        fromSelectionRect: visualRect,
                        isStart: true,
                        startGrabberHeight: startGrabberHeight,
                        endGrabberHeight: endGrabberHeight
                    )
                }
                
                if selectionRect.containsEnd {
                    endGrabber.isHidden = false
                    endGrabber.frame = grabberRect(
                        fromSelectionRect: visualRect,
                        isStart: false,
                        startGrabberHeight: startGrabberHeight,
                        endGrabberHeight: endGrabberHeight
                    )
                }
            }
            
            if visualRect.size.width > 0 && visualRect.size.height > 0 {
                let selectionView = UIView(frame: visualRect)
                selectionView.backgroundColor = selectionColor
                insertSubview(selectionView, at: 0)
                selectionViews.append(selectionView)
            }
        }
    }
    
    private func grabberRect(
        fromSelectionRect selectionRect: CGRect,
        isStart: Bool,
        startGrabberHeight: CGFloat,
        endGrabberHeight: CGFloat
    ) -> CGRect {
        let selectionRect = selectionRect.standardized
        var grabberRect = selectionRect.standardized
        let grabberWidth = self.grabberWidth
        
        if verticalForm {
            if isStart {
                grabberRect.origin.y = selectionRect.minY - grabberWidth
                grabberRect.size.width = startGrabberHeight
            } else {
                grabberRect.origin.y = selectionRect.maxY
                grabberRect.size.width = endGrabberHeight
            }
            grabberRect.size.height = grabberWidth
            
            if grabberRect.minY < 0 {
                grabberRect.origin.y = 0
            } else if grabberRect.maxY > bounds.height {
                grabberRect.origin.y = bounds.height - grabberWidth
            }
        } else {
            if isStart {
                grabberRect.origin.x = selectionRect.minX - grabberWidth
                grabberRect.origin.y = selectionRect.minY
                grabberRect.size.height = startGrabberHeight
            } else {
                grabberRect.origin.x = selectionRect.maxX
                grabberRect.origin.y = selectionRect.maxY - endGrabberHeight
                grabberRect.size.height = endGrabberHeight
            }
            grabberRect.size.width = grabberWidth
            
            if grabberRect.origin.x < 0 {
                grabberRect.origin.x = 0
            } else if grabberRect.maxX > bounds.width {
                grabberRect.origin.x = bounds.width - grabberWidth
            }
        }
        
        grabberRect = grabberRect.pixelRound()
        
        if grabberRect.origin.x.isNaN || grabberRect.origin.x.isInfinite { grabberRect.origin.x = 0 }
        if grabberRect.origin.y.isNaN || grabberRect.origin.y.isInfinite { grabberRect.origin.y = 0 }
        if grabberRect.size.width.isNaN || grabberRect.size.width.isInfinite { grabberRect.size.width = 0 }
        if grabberRect.size.height.isNaN || grabberRect.size.height.isInfinite { grabberRect.size.height = 0 }
        
        return grabberRect
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        startGrabber.grabberColor = tintColor
        endGrabber.grabberColor = tintColor
        selectionColor = tintColor.withAlphaComponent(Self.selectionAlpha)
    }
}
