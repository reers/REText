//
//  TextEmoticonViewController.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/19.
//

import UIKit
import REText

@objc(TextEmoticonViewController)
class TextEmoticonViewController: UIViewController {
    private var label: RELabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        ExampleHelper.addDebugOption(to: self)

        setupLabel()
    }

    private func setupLabel() {
        let parser = SimpleEmoticonParser()
        parser.emoticonMapper = createEmoticonMapper()

        label = RELabel()
        label.textParser = parser
        label.font = .systemFont(ofSize: 22)
        label.numberOfLines = 0
        label.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        let text = "Hahahah:smile:, it's emoticons::cool::arrow::cry::wink:\n\nYou can input \":\" + \"smile\" + \":\" to display smile emoticon, or you can copy and paste these emoticons."
        label.text = text
        
        view.addSubview(label)
        
        label.frame = view.bounds
    }
    

    private func createEmoticonMapper() -> [String: YYImage] {
        var mapper: [String: YYImage] = [:]
        
        mapper[":smile:"] = imageWithName("002")
        mapper[":cool:"] = imageWithName("013")
        mapper[":biggrin:"] = imageWithName("047")
        mapper[":arrow:"] = imageWithName("007")
        mapper[":confused:"] = imageWithName("041")
        mapper[":cry:"] = imageWithName("010")
        mapper[":wink:"] = imageWithName("085")
        
        return mapper.compactMapValues { $0 }
    }

    func imageWithName(_ name: String) -> YYImage? {
        guard let path = Bundle.main.pathForScaledResource(name, ofType: "gif", inDirectory: "EmoticonQQ.bundle") else {
            print("Warning: Could not find path for \(name).gif")
            return nil
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            print("Warning: Could not load data for \(name).gif")
            return nil
        }

        guard let image = YYImage(data: data, scale: 2.0) else {
            print("Warning: YYImage could not decode data for \(name).gif")
            return nil
        }
        
        image.preloadAllAnimatedImageFrames = true
        return image
    }
}
