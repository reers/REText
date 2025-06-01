//
//  TextAttributesViewController.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/1.
//

import UIKit
import REText

@objc(TextAttributesViewController)
class TextAttributesViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        ExampleHelper.addDebugOption(to: self)
        
        let label = RELabel()
        label.numberOfLines = 0
        label.backgroundColor = UIColor(white: 0.933, alpha: 1.0)
        label.delegate = self
        label.frame = view.bounds
        view.addSubview(label)
        
        let text = NSMutableAttributedString()
        
        // Shadow example
        do {
            let shadow = NSShadow()
            shadow.shadowColor = UIColor(white: 0.0, alpha: 0.49)
            shadow.shadowOffset = CGSize(width: 0, height: 1)
            shadow.shadowBlurRadius = 5
            
            let one = NSMutableAttributedString(
                string: "Shadow",
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 30),
                    .foregroundColor: UIColor.white,
                    .shadow: shadow
                ]
            )
            text.append(one)
            text.append(padding())
        }
        
        // Background example
        do {
            let background = TextBackground(
                cornerRadius: 3,
                fillColor: UIColor(red: 1.0, green: 0.795, blue: 0.014, alpha: 1.0)
            )
            background.borderColor = UIColor(red: 1.0, green: 0.029, blue: 0.651, alpha: 1.0)
            background.borderWidth = 3
            background.insets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
            
            let one = NSMutableAttributedString(
                string: "Background",
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 30),
                    .foregroundColor: UIColor(red: 1.0, green: 0.029, blue: 0.651, alpha: 1.0),
                    .background: background
                ]
            )
            
            text.append(padding())
            text.append(one)
            text.append(padding())
            text.append(padding())
            text.append(padding())
            text.append(padding())
        }
        
        // Link example
        do {
            let link = TextLink(value: "I am a link.")
            let background = TextBackground(
                cornerRadius: 3,
                fillColor: UIColor(white: 0.0, alpha: 0.22)
            )
            
            let one = NSMutableAttributedString(
                string: "Link",
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 30),
                    .foregroundColor: UIColor(red: 0.093, green: 0.492, blue: 1.0, alpha: 1.0),
                    .background: background,
                    .textLink: link
                ]
            )
            
            text.append(one)
            text.append(padding())
            text.append(padding())
            text.append(padding())
            text.append(padding())
        }
        
        // Strikethrough example
        do {
            let link = TextLink(value: "I am a link.")
            let background = TextBackground(
                cornerRadius: 3,
                fillColor: UIColor(white: 0.0, alpha: 0.22)
            )
            
            let one = NSMutableAttributedString(
                string: "Strikethrough",
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 30),
                    .foregroundColor: UIColor.white,
                    .background: background,
                    .textLink: link,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: UIColor.black
                ]
            )
            
            text.append(one)
            text.append(padding())
            text.append(padding())
            text.append(padding())
        }
        
        // Underline example
        do {
            let link = TextLink(value: "I am a link.")
            let background = TextBackground(
                cornerRadius: 3,
                fillColor: UIColor(white: 0.0, alpha: 0.22)
            )
            
            let one = NSMutableAttributedString(
                string: "Underline",
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 30),
                    .foregroundColor: UIColor.white,
                    .background: background,
                    .textLink: link,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .underlineColor: UIColor.red
                ]
            )
            
            text.append(one)
            text.append(padding())
            text.append(padding())
            text.append(padding())
        }
        
        text.setAlignment(.center, range: text.rangeOfAll)
        
        // Quote example
        do {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.firstLineHeadIndent = 15
            paragraphStyle.headIndent = 15
            paragraphStyle.tailIndent = -3
            
            let background = TextBackground()
            background.borderWidth = 4
            background.borderColor = UIColor.lightGray
            background.borderEdges = .left
            background.insets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
            background.fillColor = UIColor.blue.withAlphaComponent(0.1)
            
            let quote = "『《我的阿勒泰》是作者十年来散文创作的合集。分为阿勒泰文字、阿勒泰角落和九篇雪三辑。这是一部描写疆北阿勒泰地区生活和风情的原生态散文集。充满生机活泼、新鲜动人的元素。记录作者在疆北阿勒泰地区生活的点滴，包括人与事的记忆。作者在十年前以天才的触觉和笔调初现文坛并引起震惊。作品风格清新、明快，质地纯粹，原生态地再现了疆北风物，带着非常活泼的生机。』"
            
            let one = NSMutableAttributedString(
                string: quote,
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .callout),
                    .paragraphStyle: paragraphStyle,
                    .blockBackground: background
                ]
            )
            
            let bookLink = TextLink(value: URL(string: "https://book.douban.com/subject/4884218/")!)
            let bookRange = (quote as NSString).range(of: "《我的阿勒泰》")
            let linkBackground = TextBackground(
                cornerRadius: 3,
                fillColor: UIColor(white: 0.0, alpha: 0.22)
            )
            
            one.addAttribute(.background, value: linkBackground, range: bookRange)
            one.addAttribute(.textLink, value: bookLink, range: bookRange)
            one.addAttribute(.foregroundColor, 
                           value: UIColor(red: 0.093, green: 0.492, blue: 1.0, alpha: 1.0), 
                           range: bookRange)
            
            text.append(one)
            text.append(padding())
        }
        
        label.attributedText = text
    }
    
    private func padding() -> NSAttributedString {
        return NSMutableAttributedString(
            string: "\n\n",
            attributes: [.font: UIFont.systemFont(ofSize: 4)]
        )
    }
    
    private func showMessage(_ msg: String) {
        let padding: CGFloat = 10
        
        let label = RELabel()
        label.text = msg
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = .white
        label.backgroundColor = UIColor(red: 0.033, green: 0.685, blue: 0.978, alpha: 0.73)
        label.textContainerInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        label.layer.cornerRadius = 5
        label.sizeToFit()
        
        var center = view.center
        center.y = 128
        label.center = center
        view.addSubview(label)
        
        label.alpha = 0
        UIView.animate(withDuration: 0.3) {
            label.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 2, options: .curveEaseInOut) {
                label.alpha = 0
            } completion: { _ in
                label.removeFromSuperview()
            }
        }
    }
 
}

// MARK: - RELabelDelegate

extension TextAttributesViewController: RELabelDelegate {
    
    func label(
        _ label: RELabel,
        highlightedTextAttributesWith link: TextLink,
        for attributedText: NSAttributedString,
        in range: NSRange
    ) -> [NSAttributedString.Key : Any]? {
        let background = TextBackground(cornerRadius: 3, fillColor: .red)
        background.borderColor = UIColor(red: 1.0, green: 0.029, blue: 0.651, alpha: 1.0)
        background.borderWidth = 3
        return [.background: background]
    }
    
    func label(
        _ label: RELabel,
        didInteractWith link: TextLink,
        for attributedText: NSAttributedString,
        in range: NSRange,
        interaction: TextItemInteraction
    ) {
        let interactionString = interaction == .tap ? "Tapped" : "Long pressed"
        let text = attributedText.attributedSubstring(from: range).string
        showMessage("\(interactionString): \(text)")
        
        if let url = link.value as? URL {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
