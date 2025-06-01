//
//  TextSelectionLabel.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/2.
//


import UIKit
import REText

class TextSelectionLabel: RELabel {
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
            || (action == #selector(selectAll(_:))
               ? !NSEqualRanges(selectedRange, NSRange(location: 0, length: attributedText?.length ?? 0))
               : false)
            || action == #selector(hello(_:))
    }
    
    override func selectAll(_ sender: Any?) {
        hideMenu()
        selectedRange = NSRange(location: 0, length: attributedText?.length ?? 0)
        showMenu()
    }
    
    @objc
    func hello(_ sender: Any?) {
        print("Hello")
    }
}

@objc(TextSelectionViewController)
class TextSelectionViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        ExampleHelper.addDebugOption(to: self)
        
        let text = "The UIKit framework includes several classes whose purpose is to display text in an app's user interface: UITextView, UITextField, and UILabel, as described in Displaying Text Content in iOS. Text views, created from the UITextView class, are meant to display large amounts of text. Underlying UITextView is a powerful layout engine called Text Kit. If you need to customize the layout process or you need to intervene in that behavior, you can use Text Kit. For smaller amounts of text and special needs requiring custom solutions, you can use alternative, lower-level technologies, as described in Lower Level Text-Handling Technologies."
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .paragraphStyle: paragraphStyle
            ]
        )
        
        if let range = text.range(of: "Text-Handling") {
            let nsRange = NSRange(range, in: text)
            attributedText.addAttributes([
                .textLink: TextLink(),
                .foregroundColor: UIColor(red: 0.093, green: 0.492, blue: 1.000, alpha: 1.000)
            ], range: nsRange)
        }
        
        let textView = TextSelectionLabel()
        textView.isSelectable = true
        textView.numberOfLines = 0
        textView.textVerticalAlignment = .top
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.attributedText = attributedText
        textView.tintColor = .red
        
        if let range = text.range(of: "Text-Handling") {
            textView.selectedRange = NSRange(range, in: text)
        }
        
        textView.delegate = self
        view.addSubview(textView)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}

// MARK: - RELabelDelegate

extension TextSelectionViewController: RELabelDelegate {
    func labelWillBeginSelection(_ label: RELabel, selectedRange: UnsafeMutablePointer<NSRange>) {
        // You can change the selectedRange if you need.
        // selectedRange.pointee = NSRange(location: 0, length: label.attributedText?.length ?? 0)
    }
    
    func menuItems(for label: RELabel) -> [UIMenuItem]? {
        let helloItem = UIMenuItem(title: "Hello", action: #selector(TextSelectionLabel.hello(_:)))
        return [helloItem]
    }
    
    /*
    func menuVisible(for label: RELabel) -> Bool {
        
    }
    
    func label(_ label: RELabel, showMenuWith menuItems: [UIMenuItem], targetRect: CGRect) {
        
    }
    
    func labelHideMenu(_ label: RELabel) {
        
    }
    */
}
