#!/usr/bin/env bash
# Cross-compile SVG-trimmed ThorVG static libraries for Android (arm64-v8a).
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ANDROID_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$ANDROID_ROOT/.." && pwd)"
cd "$ANDROID_ROOT"

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/config.env"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/meson_common.sh"

THORVG_DIR="${THORVG_DIR:-$REPO_ROOT/third_party/thorvg}"
BUILD_ROOT="build/native"
OUT_PREBUILT="thorvg/src/main/cpp/prebuilt"
OUT_INCLUDE="thorvg/src/main/cpp/include"
ANDROID_API="${ANDROID_API:-24}"

if [[ -z "${ANDROID_HOME:-}" && -z "${ANDROID_SDK_ROOT:-}" ]]; then
  if [[ -f local.properties ]]; then
    SDK_DIR="$(grep -E '^sdk\.dir=' local.properties | head -1 | cut -d= -f2- | tr -d '\r')"
    SDK_DIR="${SDK_DIR//\\/}"
    export ANDROID_HOME="$SDK_DIR"
  fi
fi
ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
[[ -n "$ANDROID_HOME" ]] || { echo -e "${RED}ANDROID_HOME / sdk.dir not set${NC}"; exit 1; }

NDK_DIR="${ANDROID_NDK_HOME:-}"
if [[ -z "$NDK_DIR" ]]; then
  if [[ -d "$ANDROID_HOME/ndk" ]]; then
    NDK_DIR="$(ls -1d "$ANDROID_HOME/ndk"/* 2>/dev/null | sort -V | tail -1 || true)"
  fi
fi
[[ -n "$NDK_DIR" && -d "$NDK_DIR" ]] || {
  echo -e "${RED}Android NDK not found under ${ANDROID_HOME}/ndk${NC}"
  echo -e "${YELLOW}Install: sdkmanager --install \"ndk;27.2.12479018\"${NC}"
  exit 1
}

HOST_TAG="$(ls -1 "$NDK_DIR/toolchains/llvm/prebuilt" | head -1)"
[[ -n "$HOST_TAG" ]] || { echo -e "${RED}NDK prebuilt toolchain missing${NC}"; exit 1; }

echo -e "${GREEN}Building SVG-trimmed ThorVG for Android${NC}"
echo -e "${GREEN}NDK: ${NDK_DIR}${NC}"
echo -e "${GREEN}Host tag: ${HOST_TAG}${NC}"
echo -e "${GREEN}API: ${ANDROID_API}${NC}"

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

ABIS=(
  "arm64-v8a|aarch64|aarch64|aarch64-linux-android"
)

write_cross_file() {
  local cpu_family=$1 cpu=$2 triple=$3 out=$4
  local clangpp="${NDK_DIR}/toolchains/llvm/prebuilt/${HOST_TAG}/bin/${triple}${ANDROID_API}-clang++"
  local binroot="${NDK_DIR}/toolchains/llvm/prebuilt/${HOST_TAG}/bin"
  local sysroot="${NDK_DIR}/toolchains/llvm/prebuilt/${HOST_TAG}/sysroot"
  [[ -x "$clangpp" ]] || { echo -e "${RED}Missing compiler: ${clangpp}${NC}"; exit 1; }

  cat > "$out" << EOF
[binaries]
cpp = '${clangpp}'
ar = '${binroot}/llvm-ar'
as = '${binroot}/llvm-as'
ranlib = '${binroot}/llvm-ranlib'
ld = '${binroot}/ld'
strip = '${binroot}/llvm-strip'

[properties]
sys_root = '${sysroot}'

[built-in options]
cpp_args = ['--sysroot=${sysroot}', '-fvisibility=default']
cpp_link_args = ['--sysroot=${sysroot}']

[host_machine]
system = 'android'
cpu_family = '${cpu_family}'
cpu = '${cpu}'
endian = 'little'
EOF
}

mkdir -p "$BUILD_ROOT" "$OUT_INCLUDE"
rm -rf "$OUT_PREBUILT" "thorvg/src/main/jniLibs"
mkdir -p "$OUT_PREBUILT"

for entry in "${ABIS[@]}"; do
  IFS='|' read -r ABI CPU_FAMILY CPU TRIPLE <<<"$entry"
  BUILD_PATH="${BUILD_ROOT}/${ABI}"
  CROSS_FILE="${BUILD_ROOT}/cross-${ABI}.txt"
  echo -e "${YELLOW}=== ${ABI} ===${NC}"
  rm -rf "$BUILD_PATH"
  write_cross_file "$CPU_FAMILY" "$CPU" "$TRIPLE" "$CROSS_FILE"

  meson setup "$BUILD_PATH" "$THORVG_DIR" \
    "${MESON_OPTS[@]}" \
    --cross-file="$CROSS_FILE"
  meson compile -C "$BUILD_PATH"

  STATIC_LIB="${BUILD_PATH}/src/libthorvg-1.a"
  [[ -f "$STATIC_LIB" ]] || { echo -e "${RED}Missing ${STATIC_LIB}${NC}"; exit 1; }

  mkdir -p "${OUT_PREBUILT}/${ABI}"
  cp "$STATIC_LIB" "${OUT_PREBUILT}/${ABI}/libthorvg.a"
  echo -e "${GREEN}→ ${OUT_PREBUILT}/${ABI}/libthorvg.a${NC}"
done

cp "$THORVG_DIR/src/bindings/capi/thorvg_capi.h" "$OUT_INCLUDE/thorvg_capi.h"

echo -e "${GREEN}Done. Prebuilt static libs + header ready for CMake/AAR.${NC}"
find "$OUT_PREBUILT" -type f -exec ls -lh {} \;
ls -lh "$OUT_INCLUDE/thorvg_capi.h"
