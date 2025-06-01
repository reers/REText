//
//  TextCustomAttributeViewController.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/1.
//


import UIKit
import REText
import MobileCoreServices

@objc(TextCustomAttributeViewController)
class TextCustomAttributeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        ExampleHelper.addDebugOption(to: self)
        
        let attributedText = NSMutableAttributedString()
        
        let font = UIFont.systemFont(ofSize: 30)
        let image = UIImage(named: "icon_text_tag_link")!
        
        let attachment = ExampleAttachment(image: image)
        attachment.contentSize = CGSize(width: font.pointSize, height: font.pointSize)
        let attachmentAttributedString = NSAttributedString(attachment: attachment)
        attributedText.append(attachmentAttributedString)
        
        let spacingAttachment = TextAttachment()
        spacingAttachment.contentSize = CGSize(width: 5, height: 0)
        let spacingAttachmentAttributedString = NSAttributedString(attachment: spacingAttachment)
        attributedText.append(spacingAttachmentAttributedString)
        
        let linkAttributedText = NSAttributedString(string: "Tap Me")
        attributedText.append(linkAttributedText)
        
        let textColor = UIColor(red: 56/255.0, green: 146/255.0, blue: 224/255.0, alpha: 1.0)
        let fullRange = NSRange(location: 0, length: attributedText.length)
        attributedText.addAttribute(.foregroundColor, value: textColor, range: fullRange)
        attributedText.addAttribute(.font, value: font, range: fullRange)
        attributedText.addAttribute(.textLink, value: TextLink(), range: attributedText.rangeOfAll)
        
        let background = ExampleBackground(height: 36, cornerRadius: 5, fillColor: .yellow)
        attributedText.addAttribute(.background, value: background, range: attributedText.rangeOfAll)
        
        let label = RELabel()
        label.highlightedLinkTextAttributes = nil
        label.delegate = self
        label.attributedText = attributedText
        label.textAlignment = .center
        label.backgroundColor = .lightGray
        label.frame = .init(x: 0, y: 0, width: 200, height: 50)
        label.center = view.center
        
        view.addSubview(label)
        
    }
}

// MARK: - RELabelDelegate

extension TextCustomAttributeViewController: RELabelDelegate {
    func label(
        _ label: RELabel,
        highlightedTextAttributesWith link: TextLink,
        for attributedText: NSAttributedString,
        in range: NSRange
    ) -> [NSAttributedString.Key : Any]? {
        if let textColor = attributedText.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? UIColor {
            let highlightedColor = textColor.withAlphaComponent(0.5)
            return [.foregroundColor: highlightedColor]
        }
        
        return nil
    }
}
