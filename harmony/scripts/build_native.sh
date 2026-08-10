#!/usr/bin/env bash
# Cross-compile SVG-trimmed ThorVG static libraries for OpenHarmony (arm64-v8a).
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

HARMONY_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$HARMONY_ROOT/.." && pwd)"
cd "$HARMONY_ROOT"

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/config.env"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/meson_common.sh"

THORVG_DIR="${THORVG_DIR:-$REPO_ROOT/third_party/thorvg}"
BUILD_ROOT="build/native"
OUT_PREBUILT="thorvg/src/main/cpp/prebuilt"
OUT_INCLUDE="thorvg/src/main/cpp/include"

resolve_ohos_ndk() {
  if [[ -n "${OHOS_NDK_HOME:-}" && -d "${OHOS_NDK_HOME}" ]]; then
    echo "$OHOS_NDK_HOME"
    return
  fi
  local candidates=(
    "${DEVECO_SDK_HOME:-}/default/openharmony/native"
    "${OHOS_SDK_HOME:-}/native"
    "${HOME}/Library/Huawei/Sdk/default/openharmony/native"
    "${HOME}/Ohos/Sdk/default/openharmony/native"
  )
  if [[ -f local.properties ]]; then
    local sdk
    sdk="$(grep -E '^sdk\.dir=' local.properties | head -1 | cut -d= -f2- | tr -d '\r' || true)"
    if [[ -n "$sdk" ]]; then
      candidates+=("${sdk}/default/openharmony/native" "${sdk}/native")
    fi
  fi
  for c in "${candidates[@]}"; do
    if [[ -d "$c" && -d "$c/llvm" ]]; then
      echo "$c"
      return
    fi
  done
  return 1
}

OHOS_NDK="$(resolve_ohos_ndk || true)"
if [[ -z "${OHOS_NDK}" ]]; then
  echo -e "${RED}OHOS NDK not found.${NC}"
  echo -e "${YELLOW}Install DevEco Studio / command-line-tools, then set one of:${NC}"
  echo "  export DEVECO_SDK_HOME=..."
  echo "  export OHOS_NDK_HOME=.../openharmony/native"
  echo "  or sdk.dir=... in local.properties"
  exit 1
fi

echo -e "${GREEN}Building SVG-trimmed ThorVG for OpenHarmony${NC}"
echo -e "${GREEN}NDK: ${OHOS_NDK}${NC}"

if [[ "${THORVG_FORCE:-0}" != "1" \
  && -f "${OUT_PREBUILT}/arm64-v8a/libthorvg.a" \
  && -f "${OUT_INCLUDE}/thorvg_capi.h" ]]; then
  echo -e "${YELLOW}Prebuilt libs present — skip (THORVG_FORCE=1 to rebuild).${NC}"
  exit 0
fi

command -v meson >/dev/null || { echo -e "${RED}brew install meson${NC}"; exit 1; }
command -v ninja >/dev/null || { echo -e "${RED}brew install ninja${NC}"; exit 1; }

"$REPO_ROOT/scripts/fetch_thorvg.sh"

MESON_OPTS=("${MESON_BASE[@]}" -Dsimd=false)

LLVM_BIN=""
for d in "${OHOS_NDK}/llvm/bin" "${OHOS_NDK}/native/llvm/bin"; do
  if [[ -x "${d}/aarch64-unknown-linux-ohos-clang++" ]]; then
    LLVM_BIN="$d"
    break
  fi
  if [[ -x "${d}/clang++" ]]; then
    LLVM_BIN="$d"
    break
  fi
done
[[ -n "$LLVM_BIN" ]] || { echo -e "${RED}OHOS clang++ not found under ${OHOS_NDK}${NC}"; exit 1; }

CXX="${LLVM_BIN}/aarch64-unknown-linux-ohos-clang++"
AR="${LLVM_BIN}/llvm-ar"
RANLIB="${LLVM_BIN}/llvm-ranlib"
STRIP="${LLVM_BIN}/llvm-strip"
[[ -x "$CXX" ]] || CXX="${LLVM_BIN}/clang++"
[[ -x "$AR" ]] || AR="${LLVM_BIN}/llvm-ar"

SYSROOT=""
for s in "${OHOS_NDK}/sysroot" "${OHOS_NDK}/native/sysroot" "${OHOS_NDK}/llvm/sysroot"; do
  if [[ -d "$s" ]]; then SYSROOT="$s"; break; fi
done

mkdir -p "$BUILD_ROOT" "$OUT_INCLUDE" "$OUT_PREBUILT"
ABI="arm64-v8a"
BUILD_PATH="${BUILD_ROOT}/${ABI}"
CROSS_FILE="${BUILD_ROOT}/cross-${ABI}.txt"

cat > "$CROSS_FILE" << EOF
[binaries]
cpp = '${CXX}'
ar = '${AR}'
ranlib = '${RANLIB}'
strip = '${STRIP}'

[properties]
$( [[ -n "$SYSROOT" ]] && echo "sys_root = '${SYSROOT}'" )

[built-in options]
cpp_args = [$( [[ -n "$SYSROOT" ]] && echo "'--sysroot=${SYSROOT}', " )'-fvisibility=default', '--target=aarch64-linux-ohos']
cpp_link_args = [$( [[ -n "$SYSROOT" ]] && echo "'--sysroot=${SYSROOT}', " )'--target=aarch64-linux-ohos']

[host_machine]
system = 'linux'
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'
EOF

echo -e "${YELLOW}=== ${ABI} ===${NC}"
rm -rf "$BUILD_PATH"
meson setup "$BUILD_PATH" "$THORVG_DIR" \
  "${MESON_OPTS[@]}" \
  --cross-file="$CROSS_FILE"
meson compile -C "$BUILD_PATH"

STATIC_LIB="${BUILD_PATH}/src/libthorvg-1.a"
[[ -f "$STATIC_LIB" ]] || { echo -e "${RED}Missing ${STATIC_LIB}${NC}"; exit 1; }

mkdir -p "${OUT_PREBUILT}/${ABI}"
cp "$STATIC_LIB" "${OUT_PREBUILT}/${ABI}/libthorvg.a"
cp "$THORVG_DIR/src/bindings/capi/thorvg_capi.h" "$OUT_INCLUDE/thorvg_capi.h"

echo -e "${GREEN}Done. Prebuilt static libs + header ready for CMake/HAR.${NC}"
ls -lh "${OUT_PREBUILT}/${ABI}/libthorvg.a" "$OUT_INCLUDE/thorvg_capi.h"
