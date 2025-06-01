//
//  ExampleLink.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/2.
//


import UIKit
import REText

public enum ExampleLinkType: Int, CustomDebugStringConvertible {
    case unknown
    case url
    case hashtag
    case mention
    
    public var debugDescription: String {
        get {
            switch self {
                case .unknown:
                    return "unknown"
                case .url:
                    return "url"
                case .hashtag:
                    return "hashtag"
                case .mention:
                    return "mention"
            }
        }
    }
}

public class ExampleLink: TextLink {
     
    var linkType: ExampleLinkType
    
    init() {
        self.linkType = .unknown
        super.init()
    }
    
    public override var hash: Int {
        var hasher = Hasher.init()
        hasher.combine(super.hash)
        hasher.combine(self.linkType)
        return hasher.finalize()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        if !super.isEqual(object) {
            return false
        }

        guard let other = object as? ExampleLink else {
            return false
        }

        return self.linkType == other.linkType
    }
    
}
