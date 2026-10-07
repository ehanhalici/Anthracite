#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

if [ "${1:-}" = "-r" ] || [ "${1:-}" = "Release" ]; then
  BUILD_TYPE="Release"
elif [ "${1:-}" = "-d" ] || [ "${1:-}" = "Debug" ]; then
  BUILD_TYPE="Debug"
else
  echo "Usage: compile.sh [-r|-d|Release|Debug] [anthracite args...]"
  echo "  -r, Release: Release build"
  echo "  -d, Debug:   Debug build"
  exit 1
fi
shift

if [ ! -d "${TMPDIR:-}" ]; then
  export TMPDIR=/tmp
fi

mkdir -p build
cmake -S . -B build \
  -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build --parallel
exec ./build/anthracite "$@"
