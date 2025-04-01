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
import os.lock

// MARK: - Linked Map Node
fileprivate final class LinkedListNode<Key: Hashable, Value>: @unchecked Sendable {
    unowned var prev: LinkedListNode?
    unowned var next: LinkedListNode?
    let key: Key
    var value: Value
    var cost: Int = 0
    var time: TimeInterval = 0
    
    init(key: Key, value: Value) {
        self.key = key
        self.value = value
    }
}

// MARK: - Linked Map
fileprivate final class LinkedList<Key: Hashable, Value> {
    private(set) var head: LinkedListNode<Key, Value>?
    private(set) var tail: LinkedListNode<Key, Value>?
    var nodeMap: [Key: LinkedListNode<Key, Value>] = [:]
    
    var totalCost: Int = 0
    var totalCount: Int = 0
    var releaseOnMainThread: Bool = false
    var releaseAsynchronously: Bool = true
    
    func insertAtHead(_ node: LinkedListNode<Key, Value>) {
        nodeMap[node.key] = node
        totalCost += node.cost
        totalCount += 1
        
        guard let head = head else {
            self.head = node
            self.tail = node
            return
        }
        
        node.next = head
        head.prev = node
        self.head = node
    }
    
    func bringToHead(_ node: LinkedListNode<Key, Value>) {
        guard node !== head else { return }
        
        if node === tail {
            tail = node.prev
            tail?.next = nil
        } else {
            node.next?.prev = node.prev
            node.prev?.next = node.next
        }
        
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
    }
    
    func remove(_ node: LinkedListNode<Key, Value>) {
        nodeMap.removeValue(forKey: node.key)
        totalCost -= node.cost
        totalCount -= 1
        
        if let next = node.next {
            next.prev = node.prev
        }
        if let prev = node.prev {
            prev.next = node.next
        }
        if node === head {
            head = node.next
        }
        if node === tail {
            tail = node.prev
        }
    }
    
    @discardableResult
    func removeTail() -> LinkedListNode<Key, Value>? {
        guard let tail = tail else { return nil }
        
        nodeMap.removeValue(forKey: tail.key)
        totalCost -= tail.cost
        totalCount -= 1
        
        if head === tail {
            head = nil
            self.tail = nil
        } else {
            self.tail = tail.prev
            self.tail?.next = nil
        }
        
        return tail
    }
    
    func removeAll() {
        let holder = Array(nodeMap.values)
        nodeMap = [:]
        totalCost = 0
        totalCount = 0
        head = nil
        tail = nil
        
        if releaseAsynchronously {
            let queue: DispatchQueue = releaseOnMainThread ? .main : .global(qos: .background)
            queue.async { [holder] in
                _ = holder
            }
        } else if releaseOnMainThread && pthread_main_np() == 0 {
            DispatchQueue.main.async { [holder] in
                _ = holder
            }
        }
    }
}


// MARK: - MemoryCache
public final class MemoryCache<Key: Hashable, Value>: @unchecked Sendable {
    // MARK: - Properties
    
    /// The name of the cache. Default is nil.
    public var name: String?
    
    /// The number of objects in the cache (read-only)
    public var totalCount: Int {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return linkedList.totalCount
    }
    
    /// The total cost of objects in the cache (read-only).
    public var totalCost: Int {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return linkedList.totalCost
    }
    
    // MARK: - Limits
    
    /// The maximum number of objects the cache should hold.
    /// The default value is UInt.max, which means no limit.
    public var countLimit: Int = Int.max
    
    /// The maximum total cost that the cache can hold before it starts evicting objects.
    /// The default value is UInt.max, which means no limit.
    public var costLimit: Int = Int.max
    
    /// The maximum expiry time of objects in cache.
    /// The default value is DBL_MAX, which means no limit.
    public var ageLimit: TimeInterval = .greatestFiniteMagnitude
    
    /// The auto trim check time interval in seconds. Default is 5.0.
    public var autoTrimInterval: TimeInterval = 5.0
    
    /// If `true`, the cache will remove all objects when the app receives a memory warning.
    /// The default value is `true`.
    public var shouldRemoveAllObjectsOnMemoryWarning: Bool = true
    
    /// If `true`, The cache will remove all objects when the app enter background.
    /// The default value is `true`.
    public var shouldRemoveAllObjectsWhenEnteringBackground: Bool = true
    
    /// A block to be executed when the app receives a memory warning.
    /// The default value is nil.
    public var didReceiveMemoryWarningBlock: ((MemoryCache) -> Void)?
    
    /// A block to be executed when the app enter background.
    /// The default value is nil.
    public var didEnterBackgroundBlock: ((MemoryCache) -> Void)?
    
    /// If `true`, the key-value pair will be released on main thread, otherwise on
    /// background thread. Default is false.
    public var releaseOnMainThread: Bool {
        get {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            return linkedList.releaseOnMainThread
        }
        set {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            linkedList.releaseOnMainThread = newValue
        }
    }
    
    /// If `true`, the key-value pair will be released asynchronously to avoid blocking
    /// the access methods, otherwise it will be released in the access method.
    /// Default is true.
    public var releaseAsynchronously: Bool {
        get {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            return linkedList.releaseAsynchronously
        }
        set {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            linkedList.releaseAsynchronously = newValue
        }
    }
    
    // MARK: - Private properties
    private var lock = os_unfair_lock()
    private let linkedList = LinkedList<Key, Value>()
    private let queue: DispatchQueue
    
    // MARK: - Initialization
    
    public init() {
        queue = DispatchQueue(label: "com.retext.cache.memory")
        
        // Add notification observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidReceiveMemoryWarningNotification),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackgroundNotification),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        trimRecursively()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        removeAllObjects()
    }
    
    
    // MARK: - Access Methods
    
    /// Returns a Boolean value that indicates whether a given key is in cache.
    public func containsObject(forKey key: Key) -> Bool {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return linkedList.nodeMap[key] != nil
    }
    
    /// Returns the value associated with a given key.
    public func object(forKey key: Key) -> Value? {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        
        if let node = linkedList.nodeMap[key] {
            node.time = CACurrentMediaTime()
            linkedList.bringToHead(node)
            return node.value
        }
        return nil
    }
    
    /// Sets the value of the specified key in the cache, with the specified cost.
    public func setObject(_ object: Value?, forKey key: Key, cost: Int = 0) {
        guard let object = object else {
            removeObject(forKey: key)
            return
        }
        
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        
        let now = CACurrentMediaTime()
        
        if let node = linkedList.nodeMap[key] {
            linkedList.totalCost -= node.cost
            linkedList.totalCost += cost
            node.cost = cost
            node.time = now
            node.value = object
            linkedList.bringToHead(node)
        } else {
            let node = LinkedListNode(key: key, value: object)
            node.cost = cost
            node.time = now
            linkedList.insertAtHead(node)
        }
        
        if linkedList.totalCost > costLimit {
            queue.async { [weak self] in
                guard let self else { return }
                trimToCost(costLimit)
            }
        }
        
        if linkedList.totalCount > countLimit {
            if let node = linkedList.removeTail() {
                if linkedList.releaseAsynchronously {
                    let releaseQueue: DispatchQueue = linkedList.releaseOnMainThread ? .main : .global(qos: .background)
                    releaseQueue.async {
                        _ = node
                    }
                } else if linkedList.releaseOnMainThread && pthread_main_np() == 0 {
                    DispatchQueue.main.async {
                        _ = node // Hold and release in queue
                    }
                }
            }
        }
        
    }
    
    /// Removes the value of the specified key in the cache.
    public func removeObject(forKey key: Key) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        
        if let node = linkedList.nodeMap[key] {
            linkedList.remove(node)
            
            if linkedList.releaseAsynchronously {
                let releaseQueue: DispatchQueue = linkedList.releaseOnMainThread ? .main : .global(qos: .background)
                releaseQueue.async {
                    _ = node
                }
            } else if linkedList.releaseOnMainThread && pthread_main_np() == 0 {
                DispatchQueue.main.async {
                    _ = node
                }
            }
        }
    }
    
    /// Empties the cache immediately.
    public func removeAllObjects() {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        linkedList.removeAll()
    }
    
    // MARK: - Public Trim Methods
    
    /// Removes objects from the cache with LRU, until the count is below or equal to the specified value.
    public func trimToCount(_ count: Int) {
        if count == 0 {
            removeAllObjects()
            return
        }
        _trimToCount(count)
    }
    
    /// Removes objects from the cache with LRU, until the cost is below or equal to the specified value.
    public func trimToCost(_ cost: Int) {
        _trimToCost(cost)
    }
    
    /// Removes objects from the cache with LRU, until all expired objects are removed.
    public func trimToAge(_ age: TimeInterval) {
        _trimToAge(age)
    }
    
    // MARK: - Notification Handlers
    
    @objc
    private func appDidReceiveMemoryWarningNotification() {
        if let didReceiveMemoryWarningBlock = didReceiveMemoryWarningBlock {
            didReceiveMemoryWarningBlock(self)
        }
        
        if shouldRemoveAllObjectsOnMemoryWarning {
            removeAllObjects()
        }
    }
    
    @objc
    private func appDidEnterBackgroundNotification() {
        if let didEnterBackgroundBlock = didEnterBackgroundBlock {
            didEnterBackgroundBlock(self)
        }
        
        if shouldRemoveAllObjectsWhenEnteringBackground {
            removeAllObjects()
        }
    }
    
    // MARK: - Trimming
    
    private func trimRecursively() {
        DispatchQueue
            .global(qos: .background)
            .asyncAfter(deadline: .now() + autoTrimInterval) { [weak self] in
                guard let self else { return }
                trimInBackground()
                trimRecursively()
            }
    }
    
    private func trimInBackground() {
        queue.async { [weak self] in
            guard let self else { return }
            trimToCost(costLimit)
            trimToCount(countLimit)
            trimToAge(ageLimit)
        }
    }
    
    private func _trimToCost(_ costLimit: Int) {
        var finished = false
        os_unfair_lock_lock(&lock)
        if costLimit == 0 {
            linkedList.removeAll()
            finished = true
        } else if linkedList.totalCost <= costLimit {
            finished = true
        }
        os_unfair_lock_unlock(&lock)
        if finished { return }
        
        var holder: [LinkedListNode<Key, Value>] = []
        while !finished {
            if os_unfair_lock_trylock(&lock) {
                if linkedList.totalCost > costLimit {
                    if let node = linkedList.removeTail() {
                        holder.append(node)
                    }
                } else {
                    finished = true
                }
                os_unfair_lock_unlock(&lock)
            } else {
                usleep(10 * 1000) // 10 ms
            }
        }
        
        if !holder.isEmpty {
            let releaseQueue: DispatchQueue = linkedList.releaseOnMainThread ? .main : .global(qos: .background)
            let holderCopy = holder
            releaseQueue.async {
                _ = holderCopy.count
            }
        }
    }
    
    private func _trimToCount(_ countLimit: Int) {
        var finished = false
        os_unfair_lock_lock(&lock)
        if countLimit == 0 {
            linkedList.removeAll()
            finished = true
        } else if linkedList.totalCount <= countLimit {
            finished = true
        }
        os_unfair_lock_unlock(&lock)
        if finished { return }
        
        var holder: [LinkedListNode<Key, Value>] = []
        while !finished {
            if os_unfair_lock_trylock(&lock) {
                if linkedList.totalCount > countLimit {
                    if let node = linkedList.removeTail() {
                        holder.append(node)
                    }
                } else {
                    finished = true
                }
                os_unfair_lock_unlock(&lock)
            } else {
                usleep(10 * 1000) // 10 ms
            }
        }
        
        if !holder.isEmpty {
            let releaseQueue: DispatchQueue = linkedList.releaseOnMainThread ? .main : .global(qos: .background)
            let holderCopy = holder
            releaseQueue.async {
                _ = holderCopy.count
            }
        }
    }
    
    private func _trimToAge(_ ageLimit: TimeInterval) {
        var finished = false
        let now = CACurrentMediaTime()
        os_unfair_lock_lock(&lock)
        if ageLimit <= 0 {
            linkedList.removeAll()
            finished = true
        } else if linkedList.tail == nil || (now - linkedList.tail!.time) <= ageLimit {
            finished = true
        }
        os_unfair_lock_unlock(&lock)
        if finished { return }
        
        var holder: [LinkedListNode<Key, Value>] = []
        while !finished {
            if os_unfair_lock_trylock(&lock) {
                if let tail = linkedList.tail, (now - tail.time) > ageLimit {
                    if let node = linkedList.removeTail() {
                        holder.append(node)
                    }
                } else {
                    finished = true
                }
                os_unfair_lock_unlock(&lock)
            } else {
                usleep(10 * 1000) // 10 ms
            }
        }
        
        if !holder.isEmpty {
            let releaseQueue: DispatchQueue = linkedList.releaseOnMainThread ? .main : .global(qos: .background)
            let holderCopy = holder
            releaseQueue.async {
                _ = holderCopy.count
            }
        }
    }
}

extension MemoryCache: CustomStringConvertible {
    public var description: String {
        if let name = name {
            return "<\(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque())> (\(name))"
        } else {
            return "<\(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque())>"
        }
    }
}
