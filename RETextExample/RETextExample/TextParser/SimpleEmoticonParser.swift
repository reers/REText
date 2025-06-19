//
//  SimpleEmoticonParser.swift
//  RETextExample
//
//  Created by phoenix on 2025/6/19.
//

import REText
import UIKit

/// 一个简单的表情符号解析器，遵循 TextParser 协议。
///
/// 使用此解析器可以将指定的字符串片段映射为图片表情。
/// 例如: "你好 :smile:" -> "你好 😀"
///
/// 它也可以用于扩展 Unicode 本身不支持的“自定义表情”。
public class SimpleEmoticonParser: TextParser {

    /// 自定义表情的映射字典。
    /// Key 是一个特定的普通字符串，例如 `":smile:"`。
    /// Value 是一个 UIImage，它将替换文本中对应的普通字符串。
    public var emoticonMapper: [String: UIImage]? {
        get {
            // 使用同步队列确保线程安全读取
            return queue.sync { _mapper }
        }
        set {
            // 使用同步队列确保线程安全写入
            queue.sync {
                _mapper = newValue
                
                // 如果映射为空，则清空正则表达式
                guard let mapper = _mapper, !mapper.isEmpty else {
                    _regex = nil
                    return
                }

                // 从所有 key 创建正则表达式的模式。
                // NSRegularExpression.escapedPattern(for:) 会自动处理需要转义的特殊字符，
                // 例如 . ? [ ] ( ) 等，这比手动检查更安全、更高效。
                let pattern = mapper.keys
                    .map { NSRegularExpression.escapedPattern(for: $0) }
                    .joined(separator: "|")
                
                // 将所有模式包裹在一个捕获组中 `()`，以便匹配整个表情文本
                let fullPattern = "(\(pattern))"
                
                do {
                    _regex = try NSRegularExpression(pattern: fullPattern, options: [])
                } catch {
                    // 在实践中，处理或记录这个错误是很重要的
                    print("SimpleEmoticonParser: 创建正则表达式失败，pattern: '\(fullPattern)', 错误: \(error)")
                    _regex = nil
                }
            }
        }
    }

    // 用于保护内部属性的私有队列
    private let queue = DispatchQueue(label: "com.relabel.simpleemoticonparser.lock")
    private var _regex: NSRegularExpression?
    private var _mapper: [String: UIImage]?
    
    public init() {}

    /// `TextParser` 协议的核心实现方法。
    /// - Parameters:
    ///   - text: 需要被解析的可变富文本字符串。
    ///   - selectedRange: 指向当前选中范围的指针，解析器可能会在修改文本后更新它。
    /// - Returns: 如果文本被修改则返回 `true`，否则返回 `false`。
    public func parseText(_ text: NSMutableAttributedString?, selectedRange: UnsafeMutablePointer<NSRange>?) -> Bool {
        guard let text, !text.string.isEmpty else { return false }

        // 从线程安全的队列中获取当前的映射和正则表达式
        let (mapper, regex) = queue.sync { (_mapper, _regex) }

        guard let currentMapper = mapper, let currentRegex = regex, !currentMapper.isEmpty else {
            return false
        }

        // 查找所有匹配项
        let matches = currentRegex.matches(in: text.string, options: [], range: text.rangeOfAll)
        if matches.isEmpty { return false }

        var hasChanges = false
        var currentSelectedRange = selectedRange?.pointee ?? NSRange(location: 0, length: 0)
        let hasSelection = selectedRange != nil

        // 从后向前遍历匹配项进行替换。
        // 这是至关重要的，因为从后向前替换不会影响前面未处理的匹配项的 range.location。
        for match in matches.reversed() {
            let matchRange = match.range
            
            // 获取匹配到的表情文本，例如 ":smile:"
            let matchedString = (text.string as NSString).substring(with: matchRange)
            
            // 从映射中查找对应的图片
            guard let image = currentMapper[matchedString] else { continue }

            // 获取匹配位置的字体大小，以便表情图片可以自适应。
            // 如果没有指定字体，则使用一个合理的默认值。
            var font: UIFont
            if let aFont = text.attribute(.font, at: matchRange.location, effectiveRange: nil) as? UIFont {
                font = aFont
            } else {
                font = UIFont.systemFont(ofSize: 12) // CoreText 的默认字体大小
            }
            
            // 创建一个包含图片附件的富文本字符串
            let attachmentString = NSAttributedString.attachmentString(with: image, font: font)
            
            // 替换文本
            text.replaceCharacters(in: matchRange, with: attachmentString)
            
            // 如果外部传入了 selectedRange，我们需要在文本修改后对其进行校正
            if hasSelection {
                currentSelectedRange = self.updatedSelectedRange(
                    for: matchRange,
                    withLength: attachmentString.length,
                    currentSelectedRange: currentSelectedRange
                )
            }
            
            hasChanges = true
        }

        // 如果有选中范围，将更新后的值写回指针
        if hasSelection {
            selectedRange?.pointee = currentSelectedRange
        }

        return hasChanges
    }

    /// 在文本替换期间修正 selectedRange。
    /// 这是对 YYText 中 `_replaceTextInRange:withLength:selectedRange:` 方法的 Swift 实现。
    private func updatedSelectedRange(for textReplacementInRange: NSRange, withLength: Int, currentSelectedRange: NSRange) -> NSRange {
        var newRange = currentSelectedRange
        let replacementLength = withLength
        let originalLength = textReplacementInRange.length
        let delta = replacementLength - originalLength

        // 情况 1: 替换发生在选中区域的右侧，选中区域不受影响
        if textReplacementInRange.location >= newRange.location + newRange.length {
            return newRange
        }

        // 情况 2: 替换发生在选中区域的左侧，选中区域需要整体平移
        if newRange.location >= textReplacementInRange.location + originalLength {
            newRange.location += delta
            return newRange
        }

        // 情况 3: 替换区域与选中区域有交集或包含关系
        if textReplacementInRange.location == newRange.location {
            // 替换的起始位置与选中区域相同
            if originalLength >= newRange.length {
                // 替换区域完全覆盖了选中区域
                newRange.length = 0
                newRange.location += replacementLength
            } else {
                // 替换区域是选中区域的前缀部分
                newRange.length += delta
            }
        } else if textReplacementInRange.location > newRange.location {
            // 替换区域在选中区域内部
            if textReplacementInRange.location + originalLength < newRange.location + newRange.length {
                // 替换区域被选中区域完全包含
                newRange.length += delta
            } else {
                // 替换区域是选中区域的后缀部分
                newRange.length = textReplacementInRange.location - newRange.location
            }
        } else { // textReplacementInRange.location < newRange.location
            // 选中区域在替换区域内部
            newRange.location += delta
            if textReplacementInRange.location + originalLength < newRange.location + newRange.length {
                newRange.length += delta
            } else {
                newRange.length = 0
            }
        }

        return newRange
    }
}


// MARK: - NSAttributedString 辅助扩展

fileprivate extension NSAttributedString {
    
    /// 创建一个包含图片附件的富文本字符串，使其大小与字体匹配。
    static func attachmentString(with image: UIImage, font: UIFont) -> NSAttributedString {
        let imageView = YYAnimatedImageView(image: image)
        let attachment = TextAttachment()
        attachment.content = .view(imageView)
        
        // 计算图片的 bounds 以便垂直对齐。
        // font.descender 是基线以下的部分，通常为负值。
        // 将 y 设置为 descender 可以让图片的底部与文本的基线对齐。
        let fontHeight = font.ascender - font.descender
        let imageSize = image.size
        
        // 如果图片高度为0，则无法缩放
        guard imageSize.height > 0 else {
            return NSAttributedString(attachment: attachment)
        }
        
        let scale = fontHeight / imageSize.height
        attachment.bounds = CGRect(x: 0,
                                  y: font.descender,
                                  width: imageSize.width * scale,
                                  height: fontHeight)
        
        return NSAttributedString(attachment: attachment)
    }
}
