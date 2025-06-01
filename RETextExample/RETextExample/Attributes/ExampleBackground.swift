//
//  ExampleBackground.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/1.
//

import UIKit
import REText

class ExampleBackground: TextBackground {
    var height: CGFloat
    init(height: CGFloat, cornerRadius: CGFloat = 0, fillColor: UIColor? = nil) {
        self.height = height
        super.init(cornerRadius: cornerRadius, fillColor: fillColor)
    }
    
    override func backgroundRect(for textContainer: NSTextContainer, proposedRect: CGRect, characterRange: NSRange) -> CGRect {
        var propsedRect = super.backgroundRect(for: textContainer, proposedRect: proposedRect, characterRange: characterRange)
        if height > 0 {
            propsedRect.size.height = height
        }
        return propsedRect
    }
}

extension ExampleBackground {
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(super.hash)
        hasher.combine(height)
        return hasher.finalize()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if !super.isEqual(object) {
            return false
        }
        if self === object as AnyObject? { return false }
        guard let other = object as? ExampleBackground else { return false }
        
        return abs(height - other.height) < CGFloat.ulpOfOne
    }
}
