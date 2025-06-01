//
//  REExampleNavigationController.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/1.
//

import UIKit
import ReerKit

class REExampleNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fpsLabel = FPSLabel()
        fpsLabel.sizeToFit()
        view.addSubview(fpsLabel)
        
        fpsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fpsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),
            fpsLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -15)
        ])
    }
}
