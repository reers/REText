//
//  TextInteractiveGestureRecognizerResult.swift
//  REText
//
//  Created by phoenix on 2025/4/24.
//

import UIKit

/// Type of result of the gesture in state UIGestureRecognizerState.recognized.
enum TextInteractiveGestureRecognizerResult {
    case unknown
    case tap
    case longPress
    case failed
    case cancelled
}

/// A discreet gesture recognizer.
class TextInteractiveGestureRecognizer: UIGestureRecognizer {
    
    /// The minimum period fingers must press on the view for the gesture to be recognized as a long press (default = 0.5s).
    var minimumPressDuration: CFTimeInterval = 0.5
    
    /// The maximum movement of the fingers on the view before the gesture gets recognized as failed (default = 10 points).
    var allowableMovement: CGFloat = 10
    
    /// Result code of the gesture when the gesture has been recognized (state is UIGestureRecognizerState.recognized).
    private(set) var result: TextInteractiveGestureRecognizerResult = .unknown
    
    private var initialPoint: CGPoint = .zero
    private var timer: Timer?
    
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        commonInit()
    }
    
    private func commonInit() {
        // Same defaults as UILongPressGestureRecognizer
        minimumPressDuration = 0.5
        allowableMovement = 10
        
        result = .unknown
        initialPoint = .zero
    }
    
    override func reset() {
        super.reset()
        
        result = .unknown
        initialPoint = .zero
        timer?.invalidate()
        timer = nil
    }
    
    @objc
    private func longPressed(_ timer: Timer) {
        timer.invalidate()
        
        result = .longPress
        state = .recognized
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        assert(result == .unknown, "Invalid result state")
        
        if let touch = touches.first {
            initialPoint = touch.location(in: view)
            state = .began
            
            timer = Timer.scheduledTimer(
                timeInterval: minimumPressDuration,
                target: self,
                selector: #selector(longPressed(_:)),
                userInfo: nil,
                repeats: false
            )
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        if let touch = touches.first, !touchIsCloseToInitialPoint(touch) {
            result = .failed
            state = .recognized
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        
        if let touch = touches.first, touchIsCloseToInitialPoint(touch) {
            result = .tap
            state = .recognized
        } else {
            result = .failed
            state = .recognized
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        
        result = .cancelled
        state = .cancelled
    }
    
    private func touchIsCloseToInitialPoint(_ touch: UITouch) -> Bool {
        let point = touch.location(in: view)
        let xDistance = initialPoint.x - point.x
        let yDistance = initialPoint.y - point.y
        let squaredDistance = (xDistance * xDistance) + (yDistance * yDistance)
        
        let isClose = squaredDistance <= (allowableMovement * allowableMovement)
        return isClose
    }
}
