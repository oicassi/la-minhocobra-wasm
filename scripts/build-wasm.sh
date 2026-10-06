#!/usr/bin/env bash
# Compiles minhocobra-c (C + raylib) to WebAssembly and drops the result in static/game,
# where SvelteKit serves it as plain static files.
#
# Requires Emscripten (`brew install emscripten`). The output is committed to the repo,
# so this only needs to run when the C code or the resources change.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME="$ROOT/minhocobra-c"
BUILD="$ROOT/.wasm-build"
OUT="$ROOT/static/game"
RAYLIB_VERSION=5.5

command -v emcc >/dev/null || { echo "emcc not found. Install Emscripten first: brew install emscripten" >&2; exit 1; }

# raylib has to be built for the web too: the libraylib.a in minhocobra-c is a native macOS build
RAYLIB_LIB="$BUILD/raylib/src/libraylib.a"
if [ ! -f "$RAYLIB_LIB" ]; then
	mkdir -p "$BUILD"
	[ -d "$BUILD/raylib" ] || git clone --depth 1 --branch "$RAYLIB_VERSION" https://github.com/raysan5/raylib.git "$BUILD/raylib"
	make -C "$BUILD/raylib/src" PLATFORM=PLATFORM_WEB -B
fi

mkdir -p "$OUT"
# ASYNCIFY lets the game keep its blocking while loops; MODULARIZE/EXPORT_ES6 lets the page import() it
# STACK_SIZE: the MP3 decoder overflows Emscripten's 64 KB default (and hangs). HEAPF32: raylib's audio callback needs it on Module
emcc "$GAME/lacobra.c" "$RAYLIB_LIB" \
	-I"$BUILD/raylib/src" \
	-o "$OUT/lacobra.js" \
	-Os -DPLATFORM_WEB \
	-sUSE_GLFW=3 \
	-sASYNCIFY \
	-sALLOW_MEMORY_GROWTH \
	-sSTACK_SIZE=1048576 \
	-sEXPORTED_RUNTIME_METHODS=HEAPF32 \
	-sMODULARIZE -sEXPORT_ES6 -sENVIRONMENT=web \
	--preload-file "$GAME/resources@resources"

ls -lh "$OUT"
