//
//  ExampleAttachment.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/1.
//

import UIKit
import REText

class ExampleAttachment: TextAttachment, @unchecked Sendable {
    
    private var isHighlighted: Bool = false
    
    convenience init(image: UIImage) {
        self.init()
        self.content = .image(image)
    }
    
    override func drawAttachment(
        in textContainer: NSTextContainer,
        textView: UIView?,
        proposedRect: CGRect,
        characterIndex: UInt
    ) {
        let highlightedNumber = textContainer.layoutManager?.textStorage?.attribute(
            .highlighted,
            at: Int(characterIndex),
            effectiveRange: nil
        ) as? NSNumber
        
        self.isHighlighted = highlightedNumber?.boolValue ?? false
        
        super.drawAttachment(
            in: textContainer,
            textView: textView,
            proposedRect: proposedRect,
            characterIndex: characterIndex
        )
    }
    
    override func drawAttachment(in rect: CGRect, textView: UIView?) {
        guard let content = self.content else { return }
        
        switch content {
        case .image(let uIImage):
            if isHighlighted {
                uIImage.draw(in: rect, blendMode: .multiply, alpha: 0.5)
            } else {
                uIImage.draw(in: rect)
            }
        default:
            break
        }
    }
}
