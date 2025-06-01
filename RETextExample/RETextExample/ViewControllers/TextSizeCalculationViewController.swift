//
//  TextSizeCalculationViewController.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/2.
//

import UIKit
import REText

@objc(TextSizeCalculationViewController)
class TextSizeCalculationViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        ExampleHelper.addDebugOption(to: self)
        
        let text = """
        Here's to the crazy ones, the misfits, the rebels, the troublemakers, the round pegs in the square holes… the ones who see things differently -- they're not fond of rules… You can quote them, disagree with them, glorify or vilify them, but the only thing you can't do is ignore them because they change things… they push the human race forward, and while some may see them as the crazy ones, we see genius, because the ones who are crazy enough to think that they can change the world, are the ones who do.
        """
        
        let attributedText = NSAttributedString(
            string: text,
            attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]
        )
        
        let token = REText.defaultTruncationAttributedToken
        
        let additionalMessage = NSAttributedString(
            string: "more",
            attributes: [
                .foregroundColor: UIColor(red: 0.000, green: 0.449, blue: 1.000, alpha: 1.000),
                .textLink: TextLink()
            ]
        )
        let truncationAttributedText = RELabel.truncationAttributedText(
            withTokenAndAdditionalMessage: attributedText,
            token: token,
            additionalMessage: additionalMessage
        )
        
        let fitsSize = CGSize(width: view.frame.width - 30, height: .greatestFiniteMagnitude)
        
        // You can change it for testing
        let numberOfLines: Int = 5
        
        let renderAttributesBuilder = TextRenderAttributesBuilder()
        renderAttributesBuilder.attributedText = attributedText
        renderAttributesBuilder.truncationAttributedText = truncationAttributedText
        renderAttributesBuilder.maximumNumberOfLines = numberOfLines
        
        let textSize = RELabel.suggestFrameSize(
            for: renderAttributesBuilder.build(),
            fitsSize: fitsSize,
            textContainerInset: .zero
        )
        
        let label = RELabel()
        label.attributedText = attributedText
        label.truncationAttributedToken = token
        label.additionalTruncationAttributedMessage = additionalMessage
        label.numberOfLines = numberOfLines
        
        let labelSize = label.sizeThatFits(fitsSize)
        let labelFrame = CGRect(origin: .zero, size: labelSize)
        label.frame = labelFrame
        label.center = view.center
        view.addSubview(label)
        
        assert(textSize == labelSize, "They have to be the same size.")
    }
}
