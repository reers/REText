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
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let attr = NSAttributedString(string: "123", attributes: [.font:Test()])
        attr.enumerateAttribute(.font, in: .init(location: 0, length: 3)) { value, range, stop in
            print(value)
        }
    }


}

