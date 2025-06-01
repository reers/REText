//
//  DemoNavigationController.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/1.
//

import UIKit
import ReerKit

class DemoNavigationController: UINavigationController {
    let fpsLabel = FPSLabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        fpsLabel.sizeToFit()
        view.addSubview(fpsLabel)
        
        fpsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fpsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 38),
            fpsLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20)
        ])
    }
}
