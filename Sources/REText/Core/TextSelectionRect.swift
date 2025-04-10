//
//  TextSelectionRect.swift
//  REText
//
//  Created by phoenix on 2025/4/10.
//

import UIKit

class TextSelectionRect: UITextSelectionRect {
    private var _rect: CGRect
    private var _writingDirection: NSWritingDirection
    private var _containsStart: Bool
    private var _containsEnd: Bool
    private var _isVertical: Bool
    
    override var rect: CGRect {
        get { return _rect }
        set { _rect = newValue }
    }
    
    override var writingDirection: NSWritingDirection {
        get { return _writingDirection }
        set { _writingDirection = newValue }
    }
    
    override var containsStart: Bool {
        get { return _containsStart }
        set { _containsStart = newValue }
    }
    
    override var containsEnd: Bool {
        get { return _containsEnd }
        set { _containsEnd = newValue }
    }
    
    override var isVertical: Bool {
        get { return _isVertical }
        set { _isVertical = newValue }
    }
    
    init(
        rect: CGRect,
        writingDirection: NSWritingDirection,
        containsStart: Bool,
        containsEnd: Bool,
        isVertical: Bool
    ) {
        self._rect = rect
        self._writingDirection = writingDirection
        self._containsStart = containsStart
        self._containsEnd = containsEnd
        self._isVertical = isVertical
        super.init()
    }
}
