//
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

extension UIView {
    /// Converts a point from the receiver's coordinate system to that of the specified view or window.
    ///
    /// - Parameters:
    ///   - point: A point specified in the local coordinate system (bounds) of the receiver.
    ///   - view: The view or window into whose coordinate system point is to be converted.
    ///           If view is nil, this method instead converts to window base coordinates.
    /// - Returns: The point converted to the coordinate system of view.
    func convert(point: CGPoint, toViewOrWindow view: UIView?) -> CGPoint {
        guard let view = view else {
            if let window = self as? UIWindow {
                return window.convert(point, to: nil)
            } else {
                return self.convert(point, to: nil)
            }
        }
        
        let from: UIWindow? = (self as? UIWindow) ?? self.window
        let to: UIWindow? = (view as? UIWindow) ?? view.window
        
        guard let fromWindow = from,
              let toWindow = to,
              fromWindow != toWindow else {
            return self.convert(point, to: view)
        }
        
        var convertedPoint = point
        
        // Step 1: Convert from current view to source window coordinate system
        convertedPoint = fromWindow.convert(convertedPoint, from: self)
        
        // Step 2: Convert between windows through screen coordinate system
        // 2a: Convert from source window to screen coordinate system
        convertedPoint = fromWindow.convert(convertedPoint, to: nil)
        
        // 2b: Convert from screen coordinate system to target window coordinate system
        convertedPoint = toWindow.convert(convertedPoint, from: nil)
        
        // Step 3: Convert from target window to target view coordinate system
        convertedPoint = view.convert(convertedPoint, from: toWindow)
        
        return convertedPoint
    }
    
    /// Converts a point from the coordinate system of a given view or window to that of the receiver.
    ///
    /// - Parameters:
    ///   - point: A point specified in the local coordinate system (bounds) of view.
    ///   - view: The view or window with point in its coordinate system.
    ///           If view is nil, this method instead converts from window base coordinates.
    /// - Returns: The point converted to the local coordinate system (bounds) of the receiver.
    func convert(point: CGPoint, fromViewOrWindow view: UIView?) -> CGPoint {
        guard let view = view else {
            if let window = self as? UIWindow {
                return window.convert(point, from: nil as UIWindow?)
            } else {
                return self.convert(point, from: nil as UIView?)
            }
        }
        
        let from: UIWindow? = (view as? UIWindow) ?? view.window
        let to: UIWindow? = (self as? UIWindow) ?? self.window
        
        guard let fromWindow = from,
              let toWindow = to,
              fromWindow != toWindow else {
            return self.convert(point, from: view)
        }
        
        var convertedPoint = point
        
        // Step 1: Convert from source view to source window coordinate system
        convertedPoint = fromWindow.convert(convertedPoint, from: view)
        
        // Step 2: Convert between windows through screen coordinate system
        // 2a: Convert from source window to screen coordinate system
        convertedPoint = fromWindow.convert(convertedPoint, to: nil)
        
        // 2b: Convert from screen coordinate system to target window coordinate system
        convertedPoint = toWindow.convert(convertedPoint, from: nil)
        
        // Step 3: Convert from target window to current view coordinate system
        convertedPoint = self.convert(convertedPoint, from: toWindow)
        
        return convertedPoint
    }
    
    /// Converts a rectangle from the receiver's coordinate system to that of another view or window.
    ///
    /// - Parameters:
    ///   - rect: A rectangle specified in the local coordinate system (bounds) of the receiver.
    ///   - view: The view or window that is the target of the conversion operation.
    ///           If view is nil, this method instead converts to window base coordinates.
    /// - Returns: The converted rectangle.
    func convert(rect: CGRect, toViewOrWindow view: UIView?) -> CGRect {
        guard let view = view else {
            if let window = self as? UIWindow {
                return window.convert(rect, to: nil)
            } else {
                return self.convert(rect, to: nil)
            }
        }
        
        let from: UIWindow? = (self as? UIWindow) ?? self.window
        let to: UIWindow? = (view as? UIWindow) ?? view.window
        
        guard let fromWindow = from,
              let toWindow = to,
              fromWindow != toWindow else {
            return self.convert(rect, to: view)
        }
        
        var convertedRect = rect
        
        // Step 1: Convert from current view to source window coordinate system
        convertedRect = fromWindow.convert(convertedRect, from: self)
        
        // Step 2: Convert between windows through screen coordinate system
        // 2a: Convert from source window to screen coordinate system
        convertedRect = fromWindow.convert(convertedRect, to: nil)
        
        // 2b: Convert from screen coordinate system to target window coordinate system
        convertedRect = toWindow.convert(convertedRect, from: nil)
        
        // Step 3: Convert from target window to target view coordinate system
        convertedRect = view.convert(convertedRect, from: toWindow)
        
        return convertedRect
    }
    
    /// Converts a rectangle from the coordinate system of another view or window to that of the receiver.
    ///
    /// - Parameters:
    ///   - rect: A rectangle specified in the local coordinate system (bounds) of view.
    ///   - view: The view or window with rect in its coordinate system.
    ///           If view is nil, this method instead converts from window base coordinates.
    /// - Returns: The converted rectangle.
    func convert(rect: CGRect, fromViewOrWindow view: UIView?) -> CGRect {
        guard let view = view else {
            if let window = self as? UIWindow {
                return window.convert(rect, from: nil)
            } else {
                return self.convert(rect, from: nil)
            }
        }
        
        let from: UIWindow? = (view as? UIWindow) ?? view.window
        let to: UIWindow? = (self as? UIWindow) ?? self.window
        
        guard let fromWindow = from,
              let toWindow = to,
              fromWindow != toWindow else {
            return self.convert(rect, from: view)
        }
        
        var convertedRect = rect
        
        // Step 1: Convert from source view to source window coordinate system
        convertedRect = fromWindow.convert(convertedRect, from: view)
        
        // Step 2: Convert between windows through screen coordinate system
        // 2a: Convert from source window to screen coordinate system
        convertedRect = fromWindow.convert(convertedRect, to: nil)
        
        // 2b: Convert from screen coordinate system to target window coordinate system
        convertedRect = toWindow.convert(convertedRect, from: nil)
        
        // Step 3: Convert from target window to current view coordinate system
        convertedRect = self.convert(convertedRect, from: toWindow)
        
        return convertedRect
    }
}
