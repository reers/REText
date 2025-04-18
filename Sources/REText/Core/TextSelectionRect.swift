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
