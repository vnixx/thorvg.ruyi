#!/usr/bin/env bash
# Shallow-clone ThorVG into third_party/thorvg (gitignored).
# Usage: source from repo root helpers, or:
#   ./scripts/fetch_thorvg.sh
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
# shellcheck disable=SC1091
source "$SCRIPTS_DIR/config.env"

THORVG_DIR="${THORVG_DIR:-$REPO_ROOT/third_party/thorvg}"

if [[ -f "$THORVG_DIR/meson.build" ]]; then
  echo "ThorVG already present: $THORVG_DIR"
  exit 0
fi

echo "Cloning thorvg ${THORVG_TAG} (shallow) → ${THORVG_DIR}"
rm -rf "$THORVG_DIR"
mkdir -p "$(dirname "$THORVG_DIR")"
git clone --depth 1 --branch "$THORVG_TAG" "$THORVG_GIT_URL" "$THORVG_DIR"
