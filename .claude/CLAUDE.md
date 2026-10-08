# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

"La Minhocobra del Arco-Iro" is a snake-like university game written in C with raylib. This repo ports it to the browser: the C code is compiled to WebAssembly with Emscripten, and a single-page SvelteKit site hosts the canvas. Deployed at https://laminhocobra.plup.dev.

There are two independent halves:

- `minhocobra-c/` — the game itself (`lacobra.c`, one file, plus `resources/` with textures and audio).
- `src/` — the SvelteKit shell that loads and displays the compiled game.

They meet only at `static/game/`, which holds the Emscripten output (`lacobra.js`, `lacobra.wasm`, `lacobra.data`). That output is **generated but committed**; never edit it by hand.

## Commands

```sh
npm run dev          # Vite dev server
npm run build        # production build (does NOT rebuild the wasm)
npm run preview      # serve the production build
npm run check        # svelte-kit sync + svelte-check (type checking)
npm run lint         # prettier --check + eslint
npm run format       # prettier --write
npm run build:wasm   # recompile minhocobra-c -> static/game (needs emcc)
```

There is no test suite.

`.npmrc` sets `engine-strict=true`.

## Rebuilding the game (WASM)

Run `npm run build:wasm` after any change to `minhocobra-c/lacobra.c` or `minhocobra-c/resources/`, and commit the regenerated `static/game/` files along with the source change.

`scripts/build-wasm.sh` requires Emscripten (`brew install emscripten`). On first run it clones raylib 5.5 into `.wasm-build/` (gitignored) and builds it for `PLATFORM_WEB`; later runs reuse that `libraylib.a`. Delete `.wasm-build/` to force a raylib rebuild.

The emcc flags are load-bearing — each one fixes a specific failure:

- `-sASYNCIFY` — the game uses blocking `while` loops (intro, menu, game, game over) rather than a per-frame callback; Asyncify lets them yield to the browser.
- `-sSTACK_SIZE=1048576` — the MP3 decoder overflows Emscripten's 64 KB default stack and hangs.
- `-sEXPORTED_RUNTIME_METHODS=HEAPF32` — raylib's audio callback needs `HEAPF32` on the Module.
- `-sMODULARIZE -sEXPORT_ES6` — lets the page `import()` the script and call its default export as a factory.
- `--preload-file .../resources@resources` — packs assets into `lacobra.data` at the virtual path `resources/`, matching the relative paths the C code loads from.

## The C game (`minhocobra-c/lacobra.c`)

Identifiers and comments are in Portuguese; keep that style when editing.

The snake is a circular queue over a fixed array (`cobra[TAMANHOMAX]`, tracked by `inicio`/`fim`/`tam`), which was the point of the original assignment. Eating food enqueues a segment (`insertFila`); eating food matching the head's color dequeues one (`removeFila`). The game ends when the snake hits itself or a `?` block, or its length reaches 0.

`main` runs the phases sequentially, each with its own draw loop: `gameIntro` → `gameMenu` (mouse-driven difficulty buttons) → main loop → `gameOver`, repeating while the player presses Enter.

Web portability goes through three shims defined at the top under `#if defined(PLATFORM_WEB)`:

- `setFPS(fps)` instead of `SetTargetFPS`
- `fimFrame()` instead of `EndDrawing` — on web it also calls `emscripten_sleep` to pace the frame and hand control back to the browser
- `deveFechar()` instead of `WindowShouldClose` — always `false` on web

Any new draw loop must end its frame with `fimFrame()`, not `EndDrawing()`, or the browser tab will freeze. The native build still works through the `#else` branch.

`minhocobra-c/raylib.h` is a vendored old header from the original project; the WASM build uses the raylib 5.5 headers from `.wasm-build/raylib/src` instead (`-I` flag), so check API usage against 5.5.

## The SvelteKit shell (`src/`)

Stack: SvelteKit 3, Svelte 5 (runes mode forced project-wide), Vite 8, Tailwind CSS 4, TypeScript, Paraglide for i18n, `adapter-auto`.

- **No `svelte.config.js`** — SvelteKit options (adapter, compiler options) are passed to the `sveltekit()` plugin in `vite.config.ts`.
- **Imports from `src/lib` use `#lib/...`** (Node subpath imports declared in `package.json`), not `$lib`.
- `src/routes/+page.svelte` is the whole app. It keeps a `status` state (`idle | loading | running | error`) and only loads the game when the Play button is clicked — browsers block audio before a user gesture, and it avoids a ~10 MB download for visitors who don't play. The game script is fetched with a runtime `import(/* @vite-ignore */ ...)` because it lives in `static/` and must not be bundled; `locateFile` points Emscripten at the sibling `.wasm`/`.data` files.
- The canvas must keep `id="canvas"`: raylib looks it up by that id.
- `src/lib/components/seo/Seo.svelte` holds the head/meta tags and is rendered from `+layout.svelte`.

### i18n

Locales are `en` (base) and `pt`. Strings live in `messages/{locale}.json` and are used as `m.some_key()` from `#lib/paraglide/messages.js`. Add every new key to both files.

`src/lib/paraglide/` is generated by the Paraglide Vite plugin and gitignored — don't edit it; it is regenerated on `dev`/`build`. Locale routing is wired through `src/hooks.ts` (`reroute`) and `src/hooks.server.ts` (middleware that also fills `%paraglide.lang%`/`%paraglide.dir%` in `src/app.html`).

Note that the in-canvas text drawn by the C code is Portuguese only and is not covered by Paraglide.

## Code style

Prettier: tabs, single quotes, no trailing commas, 100-column width, with the Svelte and Tailwind plugins (class order is auto-sorted). Prettier and ESLint both skip `static/`, `.wasm-build/`, and (Prettier only) `minhocobra-c/`.
