#!/usr/bin/env bash
# Rewrite binaryTarget url + checksum in the repo-root Package.swift.
set -euo pipefail

APPLE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$APPLE_ROOT/.." && pwd)"
PACKAGE_SWIFT="$REPO_ROOT/Package.swift"
URL="${1:?url required}"
CHECKSUM="${2:?checksum required}"

python3 - "$PACKAGE_SWIFT" "$URL" "$CHECKSUM" <<'PY'
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
url, checksum = sys.argv[2], sys.argv[3]
text = path.read_text()
text2, n1 = re.subn(
    r'(url:\s*")[^"]+(")',
    rf'\g<1>{url}\2',
    text,
    count=1,
)
text3, n2 = re.subn(
    r'(checksum:\s*")[0-9a-fA-F]+(")',
    rf'\g<1>{checksum}\2',
    text2,
    count=1,
)
if n1 != 1 or n2 != 1:
    raise SystemExit(f"failed to patch Package.swift (url={n1}, checksum={n2})")
path.write_text(text3)
print(f"updated Package.swift\n  url: {url}\n  checksum: {checksum}")
PY
