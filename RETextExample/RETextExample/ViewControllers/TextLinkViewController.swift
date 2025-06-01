//
//  TextLinkViewController.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/2.
//


import UIKit
import REText

@objc(TextLinkViewController)
class TextLinkViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        ExampleHelper.addDebugOption(to: self)
        
        let helloWorldAttributedText = NSMutableAttributedString(string: "Hello World. ")
        let link = ExampleLink()
        link.value = "https://github.com/reers"
        link.linkType = .url
        
        let tapmeAttributedText = NSAttributedString(
            string: "Tap me!", 
            attributes: [
                .textLink: link, 
                .foregroundColor: UIColor(red: 0.000, green: 0.449, blue: 1.000, alpha: 1.000)
            ]
        )
        helloWorldAttributedText.append(tapmeAttributedText)
        
        let attributedText = NSMutableAttributedString()
        attributedText.append(helloWorldAttributedText)
        attributedText.append(NSAttributedString(string: "\n"))
        attributedText.append(helloWorldAttributedText)
        
        let fullRange = NSRange(location: 0, length: attributedText.length)
        attributedText.addAttribute(.font, value: UIFont.systemFont(ofSize: 25), range: fullRange)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        
        let reLabel = RELabel()
        reLabel.attributedText = attributedText
        reLabel.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        reLabel.numberOfLines = 0
        reLabel.delegate = self
        
        reLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reLabel)
        
        NSLayoutConstraint.activate([
            reLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            reLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - RELabelDelegate

extension TextLinkViewController: RELabelDelegate {
    func label(
        _ label: RELabel,
        didInteractWith link: TextLink,
        for attributedText: NSAttributedString,
        in range: NSRange,
        interaction: TextItemInteraction
    ) {
        guard let exLink = link as? ExampleLink else { return }
        
        let tappedText = attributedText.attributedSubstring(from: range).string
        let linkValue = exLink.value
        let linkType = exLink.linkType
        
        print("Tapped => text: \(tappedText), value: \(String(describing: linkValue)), linkType: \(linkType)")
    }
}
