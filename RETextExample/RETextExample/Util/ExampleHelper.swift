//
//  ExampleHelper.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/1.
//

import UIKit
import REText

private var debugEnabled = false

class ExampleHelper {
    
    static func addDebugOption(to viewController: UIViewController) {
        let switcher = UISwitch()
        switcher.layer.setValue(0.8, forKeyPath: "transform.scale")
        
        switcher.isOn = debugEnabled
        switcher.addTarget(self, action: #selector(toggleAction(_:)), for: .valueChanged)
        
        let item = UIBarButtonItem(customView: switcher)
        viewController.navigationItem.rightBarButtonItem = item
    }
    
    static func setDebug(_ debug: Bool) {
        let debugOptions = TextDebugOption()
        
        if debug {
            debugOptions.baselineColor = UIColor.red.withAlphaComponent(0.5)
            debugOptions.lineFragmentBorderColor = UIColor.red.withAlphaComponent(0.2)
            debugOptions.lineFragmentUsedBorderColor = UIColor(red: 0.0, green: 0.463, blue: 1.0, alpha: 0.2)
            debugOptions.glyphBorderColor = UIColor(red: 1.0, green: 0.524, blue: 0.0, alpha: 0.2)
        } else {
            debugOptions.clear()
        }
        
        TextDebugOption.shared = debugOptions
        debugEnabled = debug
    }
    
    static var isDebug: Bool {
        return debugEnabled
    }
    
    @objc private static func toggleAction(_ switcher: UISwitch) {
        setDebug(switcher.isOn)
    }
}
