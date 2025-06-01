//
//  TextAttachmentViewController.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/1.
//

import UIKit
import REText
import ReerKit

@objc(TextAttachmentViewController)
class TextAttachmentViewController: UIViewController, UIGestureRecognizerDelegate {

    private var reLabel: RELabel!
    private var dotView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        ExampleHelper.addDebugOption(to: self)

        let text = NSMutableAttributedString()
        let font = UIFont.systemFont(ofSize: 16)

        do {
            let title = "This is top aligned UIView attachment: "
            text.append(NSAttributedString(string: title))

            let switcher = UISwitch()
            switcher.sizeToFit()
            switcher.isOn = true
            
            let attachment = TextAttachment()
            attachment.content = .view(switcher)
            attachment.verticalAlignment = .top
            if let attachText = NSAttributedString(attachment: attachment).mutableCopy() as? NSMutableAttributedString {
                text.append(attachText)
            }
            text.append(NSAttributedString(string: "\n"))
        }

        do {
            let title = "This is center aligned UIImage attachment:"
            text.append(NSAttributedString(string: title))

            if let image = UIImage(named: "dribbble64_imageio") {
                let scaledImage = UIImage(cgImage: image.cgImage!, scale: 2.0, orientation: .up)

                let attachment = TextAttachment()
                attachment.content = .image(scaledImage)
                                               
                if let attachText = NSAttributedString(attachment: attachment).mutableCopy() as? NSMutableAttributedString {
                    text.append(attachText)
                }
            }
            text.append(NSAttributedString(string: "\n"))
        }

        do {
            let title = "This is bottom aligned UIView attachment: "
            text.append(NSAttributedString(string: title))

            let switcher = UISwitch()
            switcher.sizeToFit()
            switcher.isOn = true

            let attachment = TextAttachment()
            attachment.content = .view(switcher)
            attachment.verticalAlignment = .bottom
            if let attachText = NSAttributedString(attachment: attachment).mutableCopy() as? NSMutableAttributedString {
                text.append(attachText)
            }
            text.append(NSAttributedString(string: "\n"))
        }

        do {
            let title = "This is Animated Image attachment:"
            text.append(NSAttributedString(string: title))

            let names = ["001", "022", "019", "056", "085"]
            for name in names {
                guard let path = Bundle.main.pathForScaledResource(name, ofType: "gif", inDirectory: "EmoticonQQ.bundle") else {
                    print("Warning: Could not find path for \(name).gif")
                    continue
                }
                
                guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                    print("Warning: Could not load data for \(name).gif")
                    continue
                }

                guard let image = YYImage(data: data, scale: 2.0) else {
                    print("Warning: YYImage could not decode data for \(name).gif")
                    continue
                }
                image.preloadAllAnimatedImageFrames = true
                let imageView = YYAnimatedImageView(image: image)

                let attachment = TextAttachment()
                attachment.content = .view(imageView)

                if let attachText = NSAttributedString(attachment: attachment).mutableCopy() as? NSMutableAttributedString {
                    text.append(attachText)
                }
            }
            
            if let piaImage = YYImage(named: "pia") {
                piaImage.preloadAllAnimatedImageFrames = true
                
                let piaImageView = YYAnimatedImageView(image: piaImage)
                piaImageView.frame = CGRect(origin: .zero, size: piaImage.size)
                
                piaImageView.autoPlayAnimatedImage = false
                piaImageView.startAnimating()

                let attachment = TextAttachment()
                attachment.content = .view(piaImageView)
                attachment.verticalAlignment = .bottom

                if let attachText = NSAttributedString(attachment: attachment).mutableCopy() as? NSMutableAttributedString {
                    let backedString = TextBackedString(string: ":)")
                    attachText.addAttribute(
                        .backedString,
                        value: backedString,
                        range: NSRange(location: 0, length: attachText.length)
                    )
                    text.append(attachText)
                }
            } else {
                print("Warning: Could not load YYImage named 'pia'")
            }
            
            text.append(NSAttributedString(string: "\n"))
        }

        text.addAttribute(.font, value: font, range: NSRange(location: 0, length: text.length))

        reLabel = RELabel()
        reLabel.numberOfLines = 0
        reLabel.attributedText = text
        reLabel.truncationAttributedToken = NSAttributedString(string: "...")
        
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(red: 0.000, green: 0.449, blue: 1.000, alpha: 1.000),
            .textLink: TextLink(value: "")
        ]
        reLabel.additionalTruncationAttributedMessage = NSAttributedString(string: "more", attributes: linkAttributes)
        
        reLabel.isSelectable = true
        reLabel.layer.borderWidth = 0.5
        reLabel.layer.borderColor = UIColor(red: 0.000, green: 0.463, blue: 1.000, alpha: 1.000).cgColor
        reLabel.frame = CGRect(x: 0, y: 0, width: 260, height: 300)
        if let superview = self.view {
            reLabel.center = CGPoint(x: superview.frame.width / 2, y: superview.frame.height / 2)
            reLabel.re.left = 20
        }
        reLabel.onLinkInteraction = { label, link, attributedText, range, interaction in
            if interaction == .tap {
                label.sizeToFit()
            }
        }
        view.addSubview(reLabel)

        let dot = newDotView()
        dot.center = CGPoint(x: reLabel.frame.width, y: reLabel.frame.height)
        dot.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        reLabel.addSubview(dot)
        
        self.dotView = dot
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
    }

    func newDotView() -> UIView {
        let view = UIView()
        view.frame.size = CGSize(width: 50, height: 50)
        
        let dot = UIView()
        dot.frame.size = CGSize(width: 10, height: 10)
        dot.backgroundColor = UIColor(red: 0.000, green: 0.463, blue: 1.000, alpha: 1.000)
        dot.clipsToBounds = true
        dot.layer.cornerRadius = dot.frame.height / 2
        dot.center = CGPoint(x: view.frame.width / 2, y: view.frame.height / 2)
        view.addSubview(dot)
        
        return view
    }

    // MARK: - Action

    @objc func panAction(_ pan: UIPanGestureRecognizer) {
        if pan.state == .changed {
            let location = pan.location(in: view)
            let labelOrigin = reLabel.frame.origin
            let labelMinSize = CGSize(width: 30, height: 30)
            
            let width = location.x - labelOrigin.x
            let height = location.y - labelOrigin.y
            
            if width < labelMinSize.width || height < labelMinSize.height {
                return
            }
            
            reLabel.frame.size = CGSize(width: width, height: height)
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: view)
        let dotViewFrame = dotView.convert(dotView.bounds, to: view)
        return dotViewFrame.contains(location)
    }
}
