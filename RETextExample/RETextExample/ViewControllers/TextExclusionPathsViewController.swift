//
//  TextExclusionPathsViewController.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/1.
//


import UIKit
import REText

@objc(TextExclusionPathsViewController)
class TextExclusionPathsViewController: UIViewController {
    
    private var dragView: UIImageView!
    private var textView: RELabel!
    private var layoutFlag: Bool = false
    private var shapeLayer: CAShapeLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        ExampleHelper.addDebugOption(to: self)
        
        let text = "The UIKit framework includes several classes whose purpose is to display text in an app's user interface: UITextView, UITextField, and UILabel, as described in Displaying Text Content in iOS. Text views, created from the UITextView class, are meant to display large amounts of text. Underlying UITextView is a powerful layout engine called Text Kit. If you need to customize the layout process or you need to intervene in that behavior, you can use Text Kit. For smaller amounts of text and special needs requiring custom solutions, you can use alternative, lower-level technologies, as described in Lower Level Text-Handling Technologies.\nText Kit is a set of classes and protocols in the UIKit framework providing high-quality typographical services that enable apps to store, lay out, and display text with all the characteristics of fine typesetting, such as kerning, ligatures, line breaking, and justification. Text Kit is built on top of Core Text, so it provides the same speed and power. UITextView is fully integrated with Text Kit; it provides editing and display capabilities that enable users to input text, specify formatting attributes, and view the results. The other Text Kit classes provide text storage and layout capabilities."
        
        let textView = RELabel()
        textView.numberOfLines = 0
        textView.textVerticalAlignment = .top
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.text = text
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.isSelectable = true
        view.addSubview(textView)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        self.textView = textView
        
        var image = UIImage(named: "dribbble256_imageio")!
        image = UIImage(cgImage: image.cgImage!, scale: 2, orientation: .up)
        
        dragView = UIImageView(image: image)
        dragView.isUserInteractionEnabled = true
        dragView.clipsToBounds = true
        dragView.layer.cornerRadius = dragView.frame.height / 2
        view.addSubview(dragView)
        
        shapeLayer = CAShapeLayer()
        shapeLayer.borderColor = UIColor.blue.cgColor
        shapeLayer.borderWidth = 1.0
        shapeLayer.fillColor = UIColor.green.withAlphaComponent(0.2).cgColor
        view.layer.addSublayer(shapeLayer)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        if let interactivePopGestureRecognizer = navigationController?.interactivePopGestureRecognizer {
            pan.require(toFail: interactivePopGestureRecognizer)
        }
        pan.delegate = self
        view.addGestureRecognizer(pan)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !layoutFlag {
            layoutFlag = true
            updateDragViewLocation(textView.center)
        }
    }
    
    @objc private func panAction(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: view)
        updateDragViewLocation(point)
    }
    
    private func updateDragViewLocation(_ location: CGPoint) {
        dragView.center = location
        
        let offsetFrame = dragView.frame.offsetBy(dx: -textView.frame.origin.x, dy: -textView.frame.origin.y)
        let path = UIBezierPath(roundedRect: offsetFrame, cornerRadius: dragView.layer.cornerRadius)
        textView.exclusionPaths = [path]
        
        shapeLayer.path = UIBezierPath(roundedRect: dragView.frame, cornerRadius: dragView.layer.cornerRadius).cgPath
    }
}

// MARK: - UIGestureRecognizerDelegate

extension TextExclusionPathsViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: view)
        return dragView.frame.contains(location)
    }
}
