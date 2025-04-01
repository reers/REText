//
//  UIView+Extensions.swift
//  REText
//
//  Created by phoenix on 2025/4/1.
//

import UIKit

extension UIView {
    /// Converts a point from the receiver's coordinate system to that of the specified view or window.
    ///
    /// - Parameters:
    ///   - point: A point specified in the local coordinate system (bounds) of the receiver.
    ///   - view: The view or window into whose coordinate system point is to be converted.
    ///           If view is nil, this method instead converts to window self coordinates.
    /// - Returns: The point converted to the coordinate system of view.
    func convert(point: CGPoint, toViewOrWindow view: UIView?) -> CGPoint {
        guard let view = view else {
            if let window = self as? UIWindow {
                return window.convert(point, to: nil)
            } else {
                return self.convert(point, to: nil)
            }
        }
        var point = point
        let from = self is UIWindow ? (self as? UIWindow) : self.window
        let to = view is UIWindow ? (view as? UIWindow) : view.window
        if (from == nil || to == nil) || (from == to) {
            return self.convert(point, to: view)
        }
        point = self.convert(point, to: from!)
        point = to!.convert(point, from: from!)
        point = view.convert(point, from: to!)
        return point
    }
    
    /// Converts a point from the coordinate system of a given view or window to that of the receiver.
    ///
    /// - Parameters:
    ///   - point: A point specified in the local coordinate system (bounds) of view.
    ///   - view: The view or window with point in its coordinate system.
    ///           If view is nil, this method instead converts from window self coordinates.
    /// - Returns: The point converted to the local coordinate system (bounds) of the receiver.
    func convert(point: CGPoint, fromViewOrWindow view: UIView?) -> CGPoint {
        guard let view = view else {
            if let window = self as? UIWindow {
                return window.convert(point, from: nil)
            } else {
                return self.convert(point, from: nil)
            }
        }
        var point = point
        let from = view is UIWindow ? (view as? UIWindow) : view.window
        let to = self is UIWindow ? (self as? UIWindow) : self.window
        if (from == nil || to == nil) || (from == to) {
            return self.convert(point, from: view)
        }
        point = from!.convert(point, from: view)
        point = to!.convert(point, from: from!)
        point = self.convert(point, from: view)
        return point
    }
    
    /// Converts a rectangle from the receiver's coordinate system to that of another view or window.
    ///
    /// - Parameters:
    ///   - rect: A rectangle specified in the local coordinate system (bounds) of the receiver.
    ///   - view: The view or window that is the target of the conversion operation.
    ///           If view is nil, this method instead converts to window self coordinates.
    /// - Returns: The converted rectangle.
    func convert(rect: CGRect, toViewOrWindow view: UIView?) -> CGRect {
        guard let view = view else {
            if let window = self as? UIWindow {
                return window.convert(rect, to: nil)
            } else {
                return self.convert(rect, to: nil)
            }
        }
        var rect = rect
        let from = self is UIWindow ? (self as? UIWindow) : self.window
        let to = view is UIWindow ? (view as? UIWindow) : view.window
        if (from == nil || to == nil) || (from == to) {
            return self.convert(rect, to: view)
        }
        rect = self.convert(rect, to: from!)
        rect = to!.convert(rect, from: from!)
        rect = view.convert(rect, from: to!)
        return rect
    }
    
    /// Converts a rectangle from the coordinate system of another view or window to that of the receiver.
    ///
    /// - Parameters:
    ///   - rect: A rectangle specified in the local coordinate system (bounds) of view.
    ///   - view: The view or window with rect in its coordinate system.
    ///           If view is nil, this method instead converts from window self coordinates.
    /// - Returns: The converted rectangle.
    func convert(rect: CGRect, fromViewOrWindow view: UIView?) -> CGRect {
        guard let view = view else {
            if let window = self as? UIWindow {
                return window.convert(rect, from: nil)
            } else {
                return self.convert(rect, from: nil)
            }
        }
        var rect = rect
        let from = view is UIWindow ? (view as? UIWindow) : view.window
        let to = self is UIWindow ? (self as? UIWindow) : self.window
        if (from == nil || to == nil) || (from == to) {
            return self.convert(rect, from: view)
        }
        rect = from!.convert(rect, from: view)
        rect = to!.convert(rect, from: from!)
        rect = self.convert(rect, from: view)
        return rect
    }
}
