[简体中文](README_CN.md)

# REText

A modern Swift implementation of MPITextKit with enhanced text rendering and editing capabilities for iOS platforms.

## Overview

REText is a high-performance text framework built from the ground up in Swift, implemented based on [MPITextKit](https://github.com/meitu/MPITextKit). It provides advanced text layout, rendering, and interactive editing features with plans to incorporate additional capabilities from [YYText](https://github.com/ibireme/YYText) and other leading text frameworks.

## Requirements

- iOS 13.0+
- Xcode 16.0+

## Installation

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

## Quick Start

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

## Roadmap

### Phase 1: MPITextKit totally Implementation ✅
### Phase 2: YYText Feature Integration 🚧
### Phase 3: YYText Bug Fixes 📋

## License

REText is available under the MIT license. See the LICENSE file for more info.

## Credits

- Inspired by [MPITextKit](https://github.com/meitu/MPITextKit)
- Planning to integrate features from [YYText](https://github.com/ibireme/YYText)

---

**Note**: REText is actively developed and APIs may change during early releases. Please check the changelog before updating versions.
