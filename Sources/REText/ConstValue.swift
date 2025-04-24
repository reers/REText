//
//  File.swift
//  REText
//
//  Created by phoenix on 2025/4/24.
//

import Foundation

extension REText {
    static let containerMaxSize = CGSize(width: 0x100000, height: 0x100000)
    
    static let defaultAvoidTruncationCharacterSet: CharacterSet = {
        var mutableCharacterSet = CharacterSet()
        mutableCharacterSet.formUnion(CharacterSet.newlines)
        return mutableCharacterSet
    }()
}
