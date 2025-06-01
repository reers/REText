//
//  Bundle+Extensions.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/1.
//

import UIKit

extension Bundle {
    
    /**
     An array of NSNumber objects, shows the best order for path scale search.
     e.g. iPhone3GS: [1,2,3]  iPhone5: [2,3,1]  iPhone6 Plus: [3,2,1]
     */
    static var preferredScales: [CGFloat] {
        struct Static {
            static let scales: [CGFloat] = {
                let screenScale = UIScreen.main.scale
                if screenScale <= 1 {
                    return [1, 2, 3]
                } else if screenScale <= 2 {
                    return [2, 3, 1]
                } else {
                    return [3, 2, 1]
                }
            }()
        }
        return Static.scales
    }
    
    /**
     Returns the full pathname for the resource file identified by the specified
     name and extension and residing in a given bundle directory. It first search
     the file with current screen's scale (such as @2x), then search from higher
     scale to lower scale.
     
     - Parameter name: The name of a resource file contained in the directory
       specified by bundlePath.
     - Parameter ext: If extension is an empty string or nil, the extension is
       assumed not to exist and the file is the first file encountered that exactly matches name.
     - Parameter bundlePath: The path of a top-level bundle directory. This must be a
       valid path. For example, to specify the bundle directory for a Mac app, you
       might specify the path /Applications/MyApp.app.
     - Returns: The full pathname for the resource file or nil if the file could not be
       located. This method also returns nil if the bundle specified by the bundlePath
       parameter does not exist or is not a readable directory.
     */
    static func pathForScaledResource(_ name: String?, ofType ext: String?, inDirectory bundlePath: String) -> String? {
        guard let name = name, !name.isEmpty else { return nil }
        
        if name.hasSuffix("/") {
            return path(forResource: name, ofType: ext, inDirectory: bundlePath)
        }
        
        for scale in preferredScales {
            let scaledName: String
            if let ext = ext, !ext.isEmpty {
                scaledName = name.appendingNameScale(scale)
            } else {
                scaledName = name.appendingPathScale(scale)
            }
            
            if let path = path(forResource: scaledName, ofType: ext, inDirectory: bundlePath) {
                return path
            }
        }
        
        return nil
    }
    
    /**
     Returns the full pathname for the resource identified by the specified name and
     file extension. It first search the file with current screen's scale (such as @2x),
     then search from higher scale to lower scale.
     
     - Parameter name: The name of the resource file. If name is an empty string or
       nil, returns the first file encountered of the supplied type.
     - Parameter ext: If extension is an empty string or nil, the extension is
       assumed not to exist and the file is the first file encountered that exactly matches name.
     - Returns: The full pathname for the resource file or nil if the file could not be located.
     */
    func pathForScaledResource(_ name: String?, ofType ext: String?) -> String? {
        guard let name = name, !name.isEmpty else { return nil }
        
        if name.hasSuffix("/") {
            return path(forResource: name, ofType: ext)
        }
        
        for scale in Bundle.preferredScales {
            let scaledName: String
            if let ext = ext, !ext.isEmpty {
                scaledName = name.appendingNameScale(scale)
            } else {
                scaledName = name.appendingPathScale(scale)
            }
            
            if let path = path(forResource: scaledName, ofType: ext) {
                return path
            }
        }
        
        return nil
    }
    
    /**
     Returns the full pathname for the resource identified by the specified name and
     file extension and located in the specified bundle subdirectory. It first search
     the file with current screen's scale (such as @2x), then search from higher
     scale to lower scale.
     
     - Parameter name: The name of the resource file.
     - Parameter ext: If extension is an empty string or nil, all the files in
       subpath and its subdirectories are returned. If an extension is provided the
       subdirectories are not searched.
     - Parameter subpath: The name of the bundle subdirectory. Can be nil.
     - Returns: The full pathname for the resource file or nil if the file could not be located.
     */
    func pathForScaledResource(_ name: String?, ofType ext: String?, inDirectory subpath: String?) -> String? {
        guard let name = name, !name.isEmpty else { return nil }
        
        if name.hasSuffix("/") {
            return path(forResource: name, ofType: ext, inDirectory: subpath)
        }
        
        for scale in Bundle.preferredScales {
            let scaledName: String
            if let ext = ext, !ext.isEmpty {
                scaledName = name.appendingNameScale(scale)
            } else {
                scaledName = name.appendingPathScale(scale)
            }
            
            if let path = path(forResource: scaledName, ofType: ext, inDirectory: subpath) {
                return path
            }
        }
        
        return nil
    }
}
