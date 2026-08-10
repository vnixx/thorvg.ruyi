#!/usr/bin/env bash
# Shared Meson options for the SVG/CPU/C-API trim.
# Source this file; it defines MESON_BASE (array).
#
# Platform extras:
#   Apple macOS:  MESON_BASE + -Dsimd=true
#   Others:       MESON_BASE + -Dsimd=false

if [[ -n "${MESON_BASE+x}" ]]; then
  return 0 2>/dev/null || exit 0
fi

MESON_BASE=(
  -Ddefault_library=static
  -Dstatic=true
  -Dloaders=svg
  -Dsavers=
  -Dengines=cpu
  -Dbindings=capi
  -Dtests=false
  -Dtools=
  -Dextra=
  -Dlog=false
  -Dpartial=false
  -Dfile=true
  -Dthreads=false
  -Dbuildtype=release
  -Dstrip=true
)
