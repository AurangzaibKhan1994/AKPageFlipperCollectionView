// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AKPageFlipperCollectionView",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "AKPageFlipperCollectionView",
            targets: ["AKPageFlipperCollectionView"]
        ),
    ],
    targets: [
        .target(
            name: "AKPageFlipperCollectionView",
            path: "AKPageFlipperCollectionView/AKPageFlipperCollectionView/Classes"
        ),
    ]
)
