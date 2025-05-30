//
//  DefaultValues.swift
//  REText
//
//  Created by phoenix on 2025/5/30.
//

import UIKit

extension REText {
    
    static let containerMaxSize = CGSize(width: 0x100000, height: 0x100000)
    
    static let defaultAvoidTruncationCharacterSet: CharacterSet = {
        var mutableCharacterSet = CharacterSet()
        mutableCharacterSet.formUnion(CharacterSet.newlines)
        return mutableCharacterSet
    }()

    @MainActor
    static let defaultLinkTextAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor(red: 69 / 255.0, green: 110 / 255.0, blue: 192 / 255.0, alpha: 1.0)
    ]
    
    @MainActor
    static let defaultHighlightedLinkTextAttributes: [NSAttributedString.Key: Any] = [
        .background: TextBackground(cornerRadius: 3.0, fillColor: .lightGray)
    ]
    
    @MainActor
    static let defaultTruncationAttributedToken: NSAttributedString = NSAttributedString(
        string: NSLocalizedString("\u{2026}", comment: "Default truncation string")
    )
    
    @MainActor
    static let defaultTruncationToken: String = defaultTruncationAttributedToken.string
    
    static let CoreTextDefaultFontSize: CGFloat = 12
}
