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

extension NSAttributedString.Key {
    public static let background = NSAttributedString.Key(rawValue: "RETextBackgroundAttributeName")
    public static let blockBackground = NSAttributedString.Key(rawValue: "RETextBlockBackgroundAttributeName")
}

public class TextBackground: NSObject {
    public var borderWidth: CGFloat = 0
    public var borderColor: UIColor?
    public var borderEdges: UIRectEdge = .all
    public var lineJoin: CGLineJoin = .round
    public var lineCap: CGLineCap = .round
    public var insets: UIEdgeInsets = .zero
    public var cornerRadius: CGFloat = 0
    public var fillColor: UIColor?
    
    public init(cornerRadius: CGFloat = 0, fillColor: UIColor? = nil) {
        self.cornerRadius = cornerRadius
        self.fillColor = fillColor
    }
    
    public func backgroundRect(
        for textContainer: NSTextContainer,
        proposedRect: CGRect,
        characterRange: NSRange
    ) -> CGRect {
        return proposedRect.inset(by: insets)
    }
}

extension TextBackground {
    
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(borderWidth)
        hasher.combine(borderColor)
        hasher.combine(borderEdges.rawValue)
        hasher.combine(lineJoin)
        hasher.combine(lineCap)
        hasher.combine(insets.top)
        hasher.combine(insets.left)
        hasher.combine(insets.bottom)
        hasher.combine(insets.right)
        hasher.combine(cornerRadius)
        hasher.combine(fillColor)
        return hasher.finalize()
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        if self === object as AnyObject? { return true }
        guard let other = object as? TextBackground else { return false }
        
        return abs(borderWidth - other.borderWidth) < .ulpOfOne
            && objectIsEqual(borderColor, other.borderColor)
            && borderEdges == other.borderEdges
            && lineJoin == other.lineJoin
            && lineCap == other.lineCap
            && insets == other.insets
            && abs(cornerRadius - other.cornerRadius) < .ulpOfOne
            && objectIsEqual(fillColor, other.fillColor)
    }
}
