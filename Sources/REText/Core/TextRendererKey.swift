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

/// A key object used for caching text renderers.
final class TextRendererKey: NSObject {

    /// The text attributes used for rendering.
    let attributes: TextRenderAttributes

    /// The constrained size for text layout.
    let constrainedSize: CGSize

    /// Initializes a renderer key with the specified attributes and constrained size.
    ///
    /// - Parameters:
    ///   - attributes: The text attributes.
    ///   - constrainedSize: The constrained size.
    init(attributes: TextRenderAttributes, constrainedSize: CGSize) {
        self.attributes = attributes
        self.constrainedSize = constrainedSize
        super.init()
    }
}

extension TextRendererKey {
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(attributes)
        hasher.combine(constrainedSize.width)
        hasher.combine(constrainedSize.height)
        return hasher.finalize()
    }

    override func isEqual(_ object: Any?) -> Bool {
        if self === object as? TextRendererKey {
            return true
        }
        
        guard let other = object as? TextRendererKey else {
            return false
        }
        return objectIsEqual(attributes, other.attributes) && constrainedSize == other.constrainedSize
    }
}
