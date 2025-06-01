//
//  TextAttributesSeparationViewController.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/2.
//


import UIKit
import REText

extension NSAttributedString.Key {
    static let textSeparator = NSAttributedString.Key(rawValue: "TextAttributesSeparator")
}

@objc(TextAttributesSeparationViewController)
class TextAttributesSeparationViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        ExampleHelper.addDebugOption(to: self)
        
        /**
         Important: We should use an attribute to separate attachText1's attributes and attachText2's attributes, 
         if attachText1's attributes are equal to attachText2's attributes, then attributes will be merged.
         
         e.g.1
            let attributedText = NSMutableAttributedString()
            let font = UIFont.systemFont(ofSize: 15)
            do {
                let part1 = NSAttributedString(string: "part1", attributes: [.font: font])
                attributedText.append(part1)
            }
            do {
                let part2 = NSAttributedString(string: "part2", attributes: [.font: font])
                attributedText.append(part2)
            }
            print("attributedText: \(attributedText)")
            Prints: 『
                attributedText: part1part2{
                    NSFont = "<UICTFont: 0x7f8173c08650> font-family: \".SFUI-Regular\"; font-weight: normal; font-style: normal; font-size: 15.00pt";
                }
            』
            NSFont is merged.
         
         e.g.2
             let attributedText = NSMutableAttributedString()
             let font1 = UIFont.systemFont(ofSize: 15)
             let font2 = UIFont.systemFont(ofSize: 16)
             do {
                 let part1 = NSAttributedString(string: "part1", attributes: [.font: font1])
                 attributedText.append(part1)
             }
             do {
                 let part2 = NSAttributedString(string: "part2", attributes: [.font: font2])
                 attributedText.append(part2)
             }
             print("attributedText: \(attributedText)")
            Prints: 『
                attributedText: part1{
                    NSFont = "<UICTFont: 0x7fb3c9513750> font-family: \".SFUI-Regular\"; font-weight: normal; font-style: normal; font-size: 15.00pt";
                }part2{
                    NSFont = "<UICTFont: 0x7fb3c950aba0> font-family: \".SFUI-Regular\"; font-weight: normal; font-style: normal; font-size: 16.00pt";
                }
            』
         NSFont is not merged because font1 is not equal to font2.
        */
        
        /** --------------------------------- */
        let attributedText = NSMutableAttributedString()
        
        guard var image = UIImage(named: "dribbble64_imageio") else { return }
        image = UIImage(cgImage: image.cgImage!, scale: 2, orientation: .up)
        
        let attach1 = TextAttachment()
        attach1.content = .image(image)
        let attachText1 = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attach1))
        attachText1.addAttribute(
            .backedString,
            value: TextBackedString(string: "[dribbble]"),
            range: attachText1.rangeOfAll
        )
        
        let attributesSeparator1 = NSNumber(value: attributedText.length)
        attachText1.addAttribute(
            .textSeparator,
            value: attributesSeparator1,
            range: attachText1.rangeOfAll
        )
        
        attributedText.append(attachText1)
        
        /** --------------------------------- */
        let attach2 = TextAttachment()
        attach2.content = .image(image)
        let attachText2 = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attach2))
        attachText2.addAttribute(
            .background,
            value: TextBackedString(string: "[dribbble]"),
            range: attachText2.rangeOfAll
        )
        
        /** Notice:
         - attach1 is equal to attach2
         - attributesSeparator1 is *not* equal to attributesSeparator2
         */
        let attributesSeparator2 = NSNumber(value: attributedText.length)
        attachText2.addAttribute(
            .textSeparator,
            value: attributesSeparator2,
            range: attachText2.rangeOfAll
        )
        
        attributedText.append(attachText2)
        
        let label = RELabel()
        label.isSelectable = true
        label.onSelectionWillBegin = { label, selectedRange in
            selectedRange.pointee = label.attributedText?.rangeOfAll ?? NSRange(location: 0, length: 0)
        }
        label.attributedText = attributedText
        label.sizeToFit()
        label.center = view.center
        view.addSubview(label)
        
        let plainText = attributedText.plainText(for: attributedText.rangeOfAll)
        print("plainText: \(plainText)")
    }
}
