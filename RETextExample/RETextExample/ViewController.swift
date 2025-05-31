//
//  ViewController.swift
//  RETextExample
//
//  Created by phoenix on 2025/4/4.
//

import UIKit
import REText

struct Test {
    
}
class ViewController: UIViewController, RELabelDelegate {

    func label(_ label: RELabel, shouldInteractWith link: TextLink, for attributedText: NSAttributedString, in range: NSRange) -> Bool {
        return true
    }
    
    func label(_ label: RELabel, didInteractWith link: TextLink, for attributedText: NSAttributedString, in range: NSRange, interaction: TextItemInteraction) {
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .lightGray
        
        view.addSubview(label)
        label.frame = .init(x: 20, y: 200, width: 300, height: 60)
    }

    private lazy var label: RELabel = {
        let view = RELabel()
//        view.text = "哈哈哈哈哈"
        let attr = NSMutableAttributedString()
        attr.append(.init(string: "哈哈哈哈哈哈", attributes: [.foregroundColor: UIColor.blue]))
        attr.append(.init(string: "12333333", attributes: [.textLink: TextLink(value: "http://google.com")]))
        view.attributedText = attr
        view.font = .boldSystemFont(ofSize: 20)
//        view.textColor = .white
        view.textAlignment = .center
        view.textVerticalAlignment = .bottom
        view.backgroundColor = .red
        view.delegate = self
        return view
    }()

}

