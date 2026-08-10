// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ThorVG",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v7),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "ThorVG",
            targets: ["ThorVG"]
        )
    ],
    targets: [
        // SVG-focused ThorVG binary (CPU + SVG + C API).
        // URL / checksum are rewritten by apple/scripts/release.sh on each release.
        // Temporary: asset still hosted on the pre-merge thorvg.apple release.
        .binaryTarget(
            name: "ThorVG",
            url: "https://github.com/vnixx/thorvg.apple/releases/download/0.0.3/ThorVG.xcframework.zip",
            checksum: "1ba63313530a03dfe67c4f6ab6d6563c8baf84cdcccfe2fe00508ead18067722"
        )
    ]
)
