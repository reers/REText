# REText

一个现代化的 Swift 文本框架，为 iOS/macOS 平台提供增强的文本渲染和编辑功能。

## 概述

REText 是一个高性能的文本框架，完全基于 Swift 构建，基于 [MPITextKit](https://github.com/meitu/MPITextKit) 完整实现。它提供了先进的文本布局、渲染和交互式编辑功能，并计划整合 [YYText](https://github.com/ibireme/YYText) 和其他领先文本框架的更多特性。

## 系统要求

- iOS 13.0+
- Xcode 16.0+

## 安装

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/reers/REText.git", from: "0.1.0")
]
```

### CocoaPods

```ruby
pod 'REText', '~> 0.1.0'
```

## 快速开始

```swift
import REText

let label = RELabel()
label.numberOfLines = 0
label.textVerticalAlignment = .top
label.font = UIFont.preferredFont(forTextStyle: .body)
label.text = text
label.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
label.isSelectable = true
```

## 路线图

### 阶段一：MPITextKit 完整实现 ✅
### 阶段二：YYText 功能集成 🚧
### 阶段三：YYText 错误修复 📋

## 许可证

REText 基于 MIT 许可证。详情请查看 LICENSE 文件。

## 致谢

- 灵感来源于 [MPITextKit](https://github.com/meitu/MPITextKit)
- 计划集成 [YYText](https://github.com/ibireme/YYText) 的功能

---

**注意**：REText 正在积极开发中，早期版本的 API 可能会发生变化。更新版本前请查看更新日志。
