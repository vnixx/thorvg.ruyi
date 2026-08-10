# @vnixx/thorvg

HarmonyOS native packaging of [ThorVG](https://github.com/thorvg/thorvg), trimmed for **SVG → bitmap** (CPU raster + **C API** only).

This HAR ships `libthorvg.so` (arm64-v8a) and exposes the ThorVG C API (`thorvg_capi.h`).  
It does **not** include ArkTS helpers such as `renderSvg` / PixelMap wrappers — those belong in the **Ruyi** layer.

> Not the official Lottie-oriented ThorVG packages.

## Install

```bash
ohpm install @vnixx/thorvg
```

Or in `oh-package.json5`:

```json5
"dependencies": {
  "@vnixx/thorvg": "0.0.1"
}
```

## Contents

| Item | Value |
|------|--------|
| Engine | CPU software rasterizer |
| Loader | SVG only |
| Binding | C API (`tvg_*`) |
| ABI | arm64-v8a |
| Threads | off |

Disabled: GL / WebGPU, Lottie, PNG/JPG/WebP/TTF, tools, tests.

## Usage

Depend on this HAR from a native / NAPI module (for example Ruyi), link `libthorvg`, and call the C API:

```c
#include "thorvg_capi.h"

tvg_engine_init(0);
/* tvg_picture_load_data / tvg_canvas_draw / ... */
tvg_engine_term();
```

ArkTS application code should use Ruyi (or your own NAPI bridge), not this package’s empty `Index.ets`.

## Source

Monorepo: [vnixx/thorvg.ruyi](https://github.com/vnixx/thorvg.ruyi) → `harmony/`

## License

MIT — see `LICENSE`. ThorVG retains its own upstream license.
