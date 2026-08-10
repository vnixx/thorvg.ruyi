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
            url: "https://github.com/vnixx/thorvg.ruyi/releases/download/1.1.0/ThorVG.xcframework.zip",
            checksum: "be12509b5acd00ebe3d529c205ad6ad60237e73c36ddb838150a0081c8c3e1d6"
        )
    ]
)
