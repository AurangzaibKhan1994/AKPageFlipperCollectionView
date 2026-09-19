# AKPageFlipperCollectionView

[![Version](https://img.shields.io/cocoapods/v/AKPageFlipperCollectionView.svg?style=flat)](https://cocoapods.org/pods/AKPageFlipperCollectionView)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](https://github.com/AurangzaibKhan1994/AKPageFlipperCollectionView/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%2015.6%2B-blue.svg?style=flat)](https://cocoapods.org/pods/AKPageFlipperCollectionView)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat)](https://developer.apple.com/swift/)

`AKPageFlipperCollectionView` is a high-performance, plug-and-play `UICollectionView` subclass for iOS that delivers realistic 3D page-folding and page-flipping transition effects in both vertical and horizontal orientations.

## Features

- 📖 **Dual Orientation Support**: Flip pages vertically (top/bottom fold) or horizontally (left/right book fold).
- 🎨 **Dynamic Depth Shadows**: Realistic 3D crease and lighting shadows that dynamically update during user interaction.
- ⚡ **120Hz ProMotion CADisplayLink**: Butter-smooth inertial physics easing curves.
- 🚀 **Plug & Play**: Works with standard `UICollectionView` cells with zero custom cell subclassing required.
- 🖼️ **Optional Delegate Protocol**: High-speed image provision protocol (`AKPageFlippingDelegate`) for 60+ FPS performance without view snapshotting overhead.

## Requirements

- iOS 15.6+
- Swift 5.0+
- Xcode 14+


## Demo

| Vertical Flip | Horizontal Book Flip | Both Flips |
| :---: | :---: | :---: |
| <img width="250" height="500" alt="AKPageFlipperCollectionView5" src="https://github.com/user-attachments/assets/31f5e763-91f8-4bf4-a5f2-5befb06a680b" /> | <img width="250" height="500" alt="AKPageFlipperCollectionView6" src="https://github.com/user-attachments/assets/df1b3149-00fa-498c-8df2-ec85b19d2a23" /> | <img width="250" height="500" alt="AKPageFlipperCollectionView7" src="https://github.com/user-attachments/assets/4efd4a06-ebbe-4917-be45-33ac591e6f48" /> |


## Installation

### CocoaPods

Add `AKPageFlipperCollectionView` to your `Podfile`:

```ruby
pod 'AKPageFlipperCollectionView', '~> 0.1.0'
```

Then run:

```bash
pod install
```

## Quick Start

1. **Initialize `AKPageFlipperCollectionView`**:

```swift
import AKPageFlipperCollectionView

let collectionView = AKPageFlipperCollectionView(frame: view.bounds)
collectionView.flipOrientation = .vertical // Or .horizontal
view.addSubview(collectionView)
```

2. **Set Orientation & Shadow Options**:

```swift
// Choose between vertical (top/bottom fold) or horizontal (left/right book fold)
collectionView.flipOrientation = .horizontal

// Enable depth crease shadow overlays
collectionView.isShadowEnabled = true
```

3. **(Optional) Direct Image Provisioning**:

```swift
collectionView.flippingDelegate = self

extension ViewController: AKPageFlippingDelegate {
    func pageFlippingCollectionView(_ collectionView: AKPageFlipperCollectionView, imageForPageAt index: Int) -> UIImage? {
        return UIImage(named: "page_\(index)")
    }
}
```

## Author

Aurangzaib Khan ([@AurangzaibKhan1994](https://github.com/AurangzaibKhan1994)) — aurangzaibasadkhan1994@gmail.com

## License

`AKPageFlipperCollectionView` is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
