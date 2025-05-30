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
import Accelerate

public extension REText {
    static let screenScale: CGFloat = {
        return syncOnMain { UIScreen.main.scale }
    }()
    
    static let screenSize: CGSize = {
        return syncOnMain {
            var size = UIScreen.main.bounds.size
            if size.height < size.width {
                return .init(width: size.height, height: size.width)
            }
            return size
        }
    }()
    
    static let onePixel: CGFloat = 1.0 / screenScale
}

public extension CGFloat {
    /// Convert point to pixel.
    @inlinable
    func toPixel() -> CGFloat {
        return self * REText.screenScale
    }
    
    /// Convert pixel to point.
    @inlinable
    static func fromPixel(_ value: CGFloat) -> CGFloat {
        return value / REText.screenScale
    }
    
    /// Floor point value for pixel-aligned
    @inlinable
    func pixelFloor() -> CGFloat {
        let scale = REText.screenScale
        return floor(self * scale) / scale
    }
    
    /// Round point value for pixel-aligned
    @inlinable
    func pixelRound() -> CGFloat {
        let scale = REText.screenScale
        return Darwin.round(self * scale) / scale
    }
    
    /// Ceil point value for pixel-aligned
    @inlinable
    func pixelCeil() -> CGFloat {
        let scale = REText.screenScale
        return ceil((self - .ulpOfOne) * scale) / scale
    }
    
    /// Round point value to .5 pixel for path stroke (odd pixel line width pixel-aligned)
    @inlinable
    func pixelHalf() -> CGFloat {
        let scale = REText.screenScale
        return (floor(self * scale) + 0.5) / scale
    }
}

public extension CGPoint {
    
    /// Floor point value for pixel-aligned
    @inlinable
    func pixelFloor() -> CGPoint {
        let scale = REText.screenScale
        return CGPoint(
            x: floor(x * scale) / scale,
            y: floor(y * scale) / scale
        )
    }
    
    /// Round point value for pixel-aligned
    @inlinable
    func pixelRound() -> CGPoint {
        let scale = REText.screenScale
        return CGPoint(
            x: round(x * scale) / scale,
            y: round(y * scale) / scale
        )
    }
    
    /// Ceil point value for pixel-aligned
    @inlinable
    func pixelCeil() -> CGPoint {
        let scale = REText.screenScale
        return CGPoint(
            x: ceil(x * scale) / scale,
            y: ceil(y * scale) / scale
        )
    }
    
    /// Round point value to .5 pixel for path stroke (odd pixel line width pixel-aligned)
    @inlinable
    func pixelHalf() -> CGPoint {
        let scale = REText.screenScale
        return CGPoint(
            x: (floor(x * scale) + 0.5) / scale,
            y: (floor(y * scale) + 0.5) / scale
        )
    }
    
    @inlinable
    func distance(to point: CGPoint) -> CGFloat {
        let dx = self.x - point.x
        let dy = self.y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}

public extension CGSize {
    func fit(inRect rect: CGRect, mode: UIView.ContentMode) -> CGRect {
        var rect = rect.standardized
        var size = self
        size.width = size.width < 0 ? -size.width : size.width
        size.height = size.height < 0 ? -size.height : size.height
        let center = CGPoint(x: rect.midX, y: rect.midY)
        switch mode {
        case .scaleAspectFit, .scaleAspectFill:
            if (rect.size.width < 0.01 || rect.size.height < 0.01 || size.width < 0.01 || size.height < 0.01) {
                rect.origin = center
                rect.size = CGSize.zero
            } else {
                var scale: CGFloat = 0
                if (mode == .scaleAspectFit) {
                    if (size.width / size.height < rect.size.width / rect.size.height) {
                        scale = rect.size.height / size.height
                    } else {
                        scale = rect.size.width / size.width
                    }
                } else {
                    if (size.width / size.height < rect.size.width / rect.size.height) {
                        scale = rect.size.width / size.width
                    } else {
                        scale = rect.size.height / size.height
                    }
                }
                size.width *= scale
                size.height *= scale
                rect.size = size
                rect.origin = CGPoint.init(x: center.x - size.width * 0.5, y: center.y - size.height * 0.5)
            }
        case .center:
            rect.size = size;
            rect.origin = CGPoint.init(x: center.x - size.width * 0.5, y: center.y - size.height * 0.5)
        case .top:
            rect.origin.x = center.x - size.width * 0.5
            rect.size = size
        case .bottom:
            rect.origin.x = center.x - size.width * 0.5
            rect.origin.y += rect.size.height - size.height
            rect.size = size
        case .left:
            rect.origin.y = center.y - size.height * 0.5
            rect.size = size
        case .right:
            rect.origin.y = center.y - size.height * 0.5
            rect.origin.x += rect.size.width - size.width
            rect.size = size
        case .topLeft:
            rect.size = size
        case .topRight:
            rect.origin.x += rect.size.width - size.width
            rect.size = size
        case .bottomLeft:
            rect.origin.y += rect.size.height - size.height
            rect.size = size
        case .bottomRight:
            rect.origin.x += rect.size.width - size.width
            rect.origin.y += rect.size.height - size.height
            rect.size = size
        default:
            break
        }
        return rect
    }
}

public extension CGRect {
    
    /// Round point value for pixel-aligned
    @inlinable
    func pixelRound() -> CGRect {
        let origin = origin.pixelRound()
        let corner = CGPoint(
            x: origin.x + size.width,
            y: origin.y + size.height
        ).pixelRound()
        
        return CGRect(
            x: origin.x,
            y: origin.y,
            width: corner.x - origin.x,
            height: corner.y - origin.y
        )
    }
    
    /// Ceil point value for pixel-aligned
    @inlinable
    func pixelCeil() -> CGRect {
        let origin = origin.pixelFloor()
        let corner = CGPoint(
            x: origin.x + size.width,
            y: origin.y + size.height
        ).pixelCeil()
        
        return CGRect(
            x: origin.x,
            y: origin.y,
            width: corner.x - origin.x,
            height: corner.y - origin.y
        )
    }
    
    /// Round point value to .5 pixel for path stroke (odd pixel line width pixel-aligned)
    @inlinable
    func pixelHalf() -> CGRect {
        let origin = origin.pixelHalf()
        let corner = CGPoint(
            x: origin.x + size.width,
            y: origin.y + size.height
        ).pixelHalf()
        
        return CGRect(
            x: origin.x,
            y: origin.y,
            width: corner.x - origin.x,
            height: corner.y - origin.y
        )
    }
    
    @inlinable
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

extension UIEdgeInsets {
    @inline(__always)
    var horizontalValue: CGFloat {
        return left + right
    }
    
    @inline(__always)
    var verticalValue: CGFloat {
        return top + bottom
    }
}

extension REText {
    /// Get CGAffineTransform from two views
    ///
    /// - Parameters:
    ///   - from: Source view
    ///   - to: Destination view
    /// - Returns: Affine transformation from source view to destination view
    @MainActor
    static func affineTransformFromViews(from: UIView?, to: UIView?) -> CGAffineTransform {
        guard let from = from, let to = to else { return .identity }
        
        var before = [CGPoint](repeating: .zero, count: 3)
        var after = [CGPoint](repeating: .zero, count: 3)
        
        before[0] = CGPoint(x: 0, y: 0)
        before[1] = CGPoint(x: 0, y: 1)
        before[2] = CGPoint(x: 1, y: 0)
        
        after[0] = from.convert(point: before[0], toViewOrWindow: to)
        after[1] = from.convert(point: before[1], toViewOrWindow: to)
        after[2] = from.convert(point: before[2], toViewOrWindow: to)
        
        return affineTransformFromPoints(before: before, after: after)
    }
    
    /// Get CGAffineTransform from three point pairs
    ///
    /// - Parameters:
    ///   - before: Three points before transformation
    ///   - after: Three points after transformation
    /// - Returns: Affine transformation from before points to after points
    static func affineTransformFromPoints(before: [CGPoint], after: [CGPoint]) -> CGAffineTransform {
        if before.count < 3 || after.count < 3 { return .identity }
        
        let p1 = before[0], p2 = before[1], p3 = before[2]
        let q1 = after[0], q2 = after[1], q3 = after[2]
        
        var A = [Double](repeating: 0, count: 36)
        A[ 0] = Double(p1.x); A[ 1] = Double(p1.y); A[ 2] = 0; A[ 3] = 0; A[ 4] = 1; A[ 5] = 0
        A[ 6] = 0; A[ 7] = 0; A[ 8] = Double(p1.x); A[ 9] = Double(p1.y); A[10] = 0; A[11] = 1
        A[12] = Double(p2.x); A[13] = Double(p2.y); A[14] = 0; A[15] = 0; A[16] = 1; A[17] = 0
        A[18] = 0; A[19] = 0; A[20] = Double(p2.x); A[21] = Double(p2.y); A[22] = 0; A[23] = 1
        A[24] = Double(p3.x); A[25] = Double(p3.y); A[26] = 0; A[27] = 0; A[28] = 1; A[29] = 0
        A[30] = 0; A[31] = 0; A[32] = Double(p3.x); A[33] = Double(p3.y); A[34] = 0; A[35] = 1
        
        let error = matrixInvert(N: 6, matrix: &A)
        if error != 0 { return .identity }
        
        let B: [Double] = [
            Double(q1.x), Double(q1.y),
            Double(q2.x), Double(q2.y),
            Double(q3.x), Double(q3.y)
        ]
        
        var M = [Double](repeating: 0, count: 6)
        M[0] = A[ 0] * B[0] + A[ 1] * B[1] + A[ 2] * B[2] + A[ 3] * B[3] + A[ 4] * B[4] + A[ 5] * B[5]
        M[1] = A[ 6] * B[0] + A[ 7] * B[1] + A[ 8] * B[2] + A[ 9] * B[3] + A[10] * B[4] + A[11] * B[5]
        M[2] = A[12] * B[0] + A[13] * B[1] + A[14] * B[2] + A[15] * B[3] + A[16] * B[4] + A[17] * B[5]
        M[3] = A[18] * B[0] + A[19] * B[1] + A[20] * B[2] + A[21] * B[3] + A[22] * B[4] + A[23] * B[5]
        M[4] = A[24] * B[0] + A[25] * B[1] + A[26] * B[2] + A[27] * B[3] + A[28] * B[4] + A[29] * B[5]
        M[5] = A[30] * B[0] + A[31] * B[1] + A[32] * B[2] + A[33] * B[3] + A[34] * B[4] + A[35] * B[5]
        
        let transform = CGAffineTransform(a: CGFloat(M[0]), b: CGFloat(M[2]), c: CGFloat(M[1]), d: CGFloat(M[3]), tx: CGFloat(M[4]), ty: CGFloat(M[5]))
        return transform
    }
    
    /// Matrix inversion function
    /// - Parameters:
    ///   - N: Dimension of the matrix
    ///   - matrix: Matrix to be inverted, result is also stored in this parameter
    /// - Returns: 0 for success, non-zero for failure
    private static func matrixInvert(N: Int32, matrix: inout [Double]) -> Int32 {
        var error: Int32 = 0
        let pivot_tmp = [Int32](repeating: 0, count: Int(N * N))
        var pivot = pivot_tmp
        let workspace_tmp = [Double](repeating: 0, count: Int(N * N))
        var workspace = workspace_tmp
        
        if N > 6 {
            pivot = [Int32](repeating: 0, count: Int(N * N))
            workspace = [Double](repeating: 0, count: Int(N))
        }
        
        // Using LAPACK functions from Accelerate framework
        var n = N
        withUnsafeMutablePointer(to: &n) {
            dgetrf_($0, $0, &matrix, $0, &pivot, &error)
            if error == 0 {
                dgetri_($0, &matrix, $0, &pivot, &workspace, $0, &error)
            }
        }
        return error
    }
}
