# Anthracite

Anthracite is a native Markdown editor written in ATS2/Postiats 0.4.2, using
X11/GLX and OpenGL directly. It does not use a browser runtime or a GUI toolkit.
System libraries and a bundled JPEG fallback remain part of its trusted boundary;
ATS proofs cover the contracts actually represented in its types.

## Build and verify

Run inside `nix-shell` (or an equivalent environment providing ATS2, Clang,
CMake, X11, OpenGL and `PATSHOME`):

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel
./build/anthracite
```

`./compile.sh -r` and `./compile.sh -d` configure, build and start the app.
The primary font under `fonts/` is required and its hash is checked by CMake;
the pinned Arabic font is in `vendor/fonts/`.

```sh
cmake --build build --target check-build --parallel
ctest --test-dir build --output-on-failure -LE graphics
# Requires a working X11/GLX display, for example a separate Xvfb instance:
DISPLAY=:1 ctest --test-dir build --output-on-failure -L graphics
```

With a display available, `cmake --build build --target check` builds all test
executables, including those excluded from the default build, and runs CTest.
Use a separate build directory for Debug verification. Optional real-font cases
are enabled by `ANTHRACITE_OT_LATIN_TTF`, `ANTHRACITE_OT_ARABIC_TTF` and
`ANTHRACITE_OT_KERN_TTF`; record these paths when comparing test runs.

## Architecture

`src/data_text` contains Unicode analysis; `src/data_font` contains font parsing,
shaping, rasterization and atlas ownership. `src/data_ast` owns documents,
parsing, editing, folding and layout. `src/ui_workspace` implements workspace
interaction and painting. Platform, renderer, runtime, image, search, configuration
and OS services remain separate subsystems.

Sources and tests are grouped by subject. A large owner can include private
`.hats` implementation groups so its linear representation stays private without
adding unsafe casts or new opaque pointer types. CMake indexes nested ATS modules
by unique basename and shares compiled host/text-engine objects between consumers.

See the [Turkish architecture index](docs/README.md), [development rules](docs/skill.md),
[refactoring record](docs/refactoring_durumu.md) and [known issues](docs/olasi_hatalar.md).
Generated C, Unicode binaries and build outputs are not edited by hand.

The new boundary/equivalence tests expose two pre-existing issues (BUG-008 and
BUG-011). They retain their correct expectations and carry the `known_issue`
label; the full suite currently reports those failures. Details and reproduction
commands are in the known-issues document. They are not skipped by `check`.

## Verification limits

Dependent and linear types, compile-rejection tests, conformance datasets, finite
state matrices and runtime ownership checks complement one another. Passing tests
does not prove correctness for every possible document, font or image. Performance
figures require a recorded environment and workload; a fixed live-byte reading is
not a universal leak-freedom guarantee.
