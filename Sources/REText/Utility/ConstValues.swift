//
//  Copyright © 2019 meitu.
//  Copyright © 2025 reers.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
