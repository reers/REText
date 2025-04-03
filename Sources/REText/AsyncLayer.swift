//
//  Copyright © 2014 ibireme.
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
import QuartzCore

// MARK: - AsyncLayerDisplayTask

public class AsyncLayerDisplayTask: @unchecked Sendable {
    /// Whether the render code is executed in background. Default is true.
    public var displaysAsynchronously: Bool = true
    
    /// This block will be called before the asynchronous drawing begins.
    /// It will be called on the main thread.
    public var willDisplay: ((CALayer) -> Void)?
    
    /// This block is called to draw the layer's contents.
    /// This block may be called on main thread or background thread,
    /// so it should be thread-safe.
    ///
    /// block param context:      A new bitmap content created by layer.
    /// block param size:         The content size (typically same as layer's bound size).
    /// block param isCancelled:  If this block returns `true`, the method should cancel the
    /// drawing process and return as quickly as possible.
    public var display: ((CGContext, CGSize, @escaping () -> Bool) -> Void)?
    
    /// This block will be called after the asynchronous drawing finished.
    /// It will be called on the main thread.
    ///
    /// block param layer:  The layer.
    /// block param finished:  If the draw process is cancelled, it's `false`, otherwise it's `true`
    public var didDisplay: ((CALayer, Bool) -> Void)?
}

// MARK: - AsyncLayerDelegate Protocol

public protocol AsyncLayerDelegate: AnyObject {
    /// This method is called to return a new display task when the layer's contents need update.
    func newAsyncDisplayTask() -> AsyncLayerDisplayTask
}

// MARK: - AsyncLayer

public class AsyncLayer: CALayer, @unchecked Sendable {
    private var sentinel: Sentinel = Sentinel()
    
    private static var releaseQueue: DispatchQueue {
        return .global(qos: .utility)
    }
    
    // MARK: - Override Methods
    public override init() {
        super.init()
        contentsScale = REText.screenScale
    }
    
    public override init(layer: Any) {
        super.init(layer: layer)
        contentsScale = REText.screenScale
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        contentsScale = REText.screenScale
    }
    
    deinit {
        sentinel.increase()
    }
    
    public override func setNeedsDisplay() {
        _cancelAsyncDisplay()
        super.setNeedsDisplay()
    }
    
    public override func display() {
        super.contents = super.contents
        _display()
    }
    
    // MARK: - Private Methods
    
    private func _display() {
        guard let delegate = delegate as? AsyncLayerDelegate else { return }
        let task = delegate.newAsyncDisplayTask()
        let async = task.displaysAsynchronously
        
        if task.display == nil {
            task.willDisplay?(self)
            self.contents = nil
            task.didDisplay?(self, true)
            return
        }
        
        let opaque = isOpaque
        let scale = contentsScale
        let size = bounds.size
        
        if size.width < REText.onePixel || size.height < REText.onePixel {
            task.willDisplay?(self)
            
            if let image = maybeCast(contents, to: CGImage.self) {
                contents = nil
                Self.releaseQueue.async {
                    _ = image
                }
            }
            task.didDisplay?(self, true)
            return
        }
        
        if async {
            task.willDisplay?(self)
            let sentinel = self.sentinel
            let value = sentinel.value
            let isCancelled: @Sendable () -> Bool = { value != sentinel.value }
            let backgroundColor = (opaque && self.backgroundColor != nil) ? self.backgroundColor : nil
            
            RenderQueuePool.next().async {
                if isCancelled() {
                    _ = backgroundColor
                    return
                }
                
                let format = UIGraphicsImageRendererFormat()
                format.opaque = opaque
                format.scale = scale
                let renderer = UIGraphicsImageRenderer(size: size, format: format)
                
                let image = renderer.image { rendererContext in
                    let context = rendererContext.cgContext
                    
                    if opaque {
                        context.saveGState()
                        if let backgroundColor {
                            context.setFillColor(backgroundColor)
                        } else {
                            context.setFillColor(UIColor.white.cgColor)
                        }
                        context.addRect(.init(origin: .zero, size: size))
                        context.fillPath()
                        context.restoreGState()
                    }
                    
                    task.display?(context, size, isCancelled)
                }
                _ = backgroundColor
                
                if isCancelled() {
                    DispatchQueue.main.async {
                        task.didDisplay?(self, false)
                    }
                    return
                }
                DispatchQueue.main.async {
                    if isCancelled() {
                        task.didDisplay?(self, false)
                    } else {
                        self.contents = image.cgImage
                        task.didDisplay?(self, true)
                    }
                }
            }
        } else {
            sentinel.increase()
            task.willDisplay?(self)
            
            let format = UIGraphicsImageRendererFormat()
            format.opaque = opaque
            format.scale = scale
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            
            let image = renderer.image { rendererContext in
                let context = rendererContext.cgContext
                
                if opaque {
                    context.saveGState()
                    if let backgroundColor = self.backgroundColor {
                        context.setFillColor(backgroundColor)
                    } else {
                        context.setFillColor(UIColor.white.cgColor)
                    }
                    context.addRect(.init(origin: .zero, size: size))
                    context.fillPath()
                    context.restoreGState()
                }
                
                task.display?(context, size, { return false })
            }
            
            self.contents = image.cgImage
            task.didDisplay?(self, true)
        }
    }
    
    private func _cancelAsyncDisplay() {
        sentinel.increase()
    }
}

/// Manages a pool of serial dispatch queues for asynchronous rendering tasks
enum RenderQueuePool {

    private static let maxQueueCount = 8

    /// Actual number of queues based on available processors
    private static let queueCount: Int = {
        let processors = ProcessInfo.processInfo.activeProcessorCount
        return max(1, min(processors, maxQueueCount))
    }()

    /// Pool of serial dispatch queues for rendering tasks.
    private static let queues: [DispatchQueue] = {
        var createdQueues: [DispatchQueue] = []
        createdQueues.reserveCapacity(queueCount)

        for i in 0..<queueCount {
            // Create a serial queue with userInitiated QoS.
            let queue = DispatchQueue(
                label: "com.retext.asynclayer.render.\(i)",
                qos: .userInitiated
            )
            createdQueues.append(queue)
        }
        return createdQueues
    }()

    // The atomic counter using Sentinel class.
    private static let counter = Sentinel()

    /// Returns a serial dispatch queue from a pool, intended for display/rendering tasks.
    /// Distributes work round-robin across the available queues.
    static func next() -> DispatchQueue {
        let currentCounterValue = counter.increase()
        let index = Int(currentCounterValue % Int64(queueCount))
        return queues[index]
    }
}
