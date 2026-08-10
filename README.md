# thorvg.ruyi

Unified native packaging for [ThorVG](https://github.com/thorvg/thorvg), trimmed for **SVG → bitmap** (CPU raster + **C API** only).

Higher-level wrappers (`renderSvg`, Bitmap/PixelMap helpers, etc.) belong in the **Ruyi** layer — not in this repo.

> Not the official Lottie-oriented packages (`thorvg/thorvg.swift`, `thorvg/thorvg.android`, …).

## Layout

```text
scripts/          Shared THORVG_TAG + Meson trim + fetch
third_party/      thorvg/ cloned at build time (gitignored)
apple/            XCFramework build + SPM release scripts
android/          Prefab AAR (C API .so, no Kotlin/JNI bridge)
harmony/          Native HAR (C API .so, no NAPI/ArkTS bridge)
Package.swift     Apple SPM binaryTarget (repo root)
```

## Trim

| Option | Value |
|--------|--------|
| engines | `cpu` |
| loaders | `svg` |
| bindings | `capi` |
| threads | `false` |
| extra | _(empty — no Lottie / OpenMP)_ |

Disabled: GL / WebGPU, Lottie, PNG/JPG/WebP/TTF, tools, tests.

Bump ThorVG via `THORVG_TAG` (default `v1.1.0` in `scripts/config.env`).

## Apple

```bash
brew install meson ninja
./apple/scripts/build_frameworks.sh
# → apple/ThorVG.xcframework

./apple/scripts/release.sh 0.0.1 --dry-run
```

SPM:

```swift
dependencies: [
    .package(url: "https://github.com/vnixx/thorvg.ruyi.git", from: "0.0.3")
]
```

```swift
import ThorVG
// C API from thorvg_capi.h — link C++ (`-lc++`)
```

## Android

```bash
cd android
cp local.properties.example local.properties   # set sdk.dir
./gradlew :thorvg:assembleRelease
# → thorvg/build/outputs/aar/thorvg-release.aar
```

Prefab module `thorvg` exposes `thorvg_capi.h` + `libthorvg.so` (`arm64-v8a`).  
Maven publish: see `android/PUBLISHING.md`.

## HarmonyOS

```bash
cd harmony
cp local.properties.example local.properties   # set sdk.dir / OHOS NDK
./scripts/build_native.sh
# Then build the `thorvg` HAR in DevEco (native lib only)
```

## License

MIT — see `LICENSE`. ThorVG retains its own license under `third_party/thorvg/`.
