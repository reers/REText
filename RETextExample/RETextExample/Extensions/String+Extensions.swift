//
//  String+Extensions.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/1.
//

import UIKit

extension String {
    
    func appendingNameScale(_ scale: CGFloat) -> String {
        if abs(Float(scale) - 1) <= Float.ulpOfOne || isEmpty || hasSuffix("/") {
            return self
        }
        return "\(self)@\(Int(scale))x"
    }
    
    func appendingPathScale(_ scale: CGFloat) -> String {
        if abs(Float(scale) - 1) <= Float.ulpOfOne || isEmpty || hasSuffix("/") {
            return self
        }
        
        let ext = (self as NSString).pathExtension
        var extRange = NSRange(location: count - ext.count, length: 0)
        if ext.count > 0 {
            extRange.location -= 1
        }
        
        let scaleStr = "@\(scale)x"
        return (self as NSString).replacingCharacters(in: extRange, with: scaleStr)
    }
}
