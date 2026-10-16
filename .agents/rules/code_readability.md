# Readability, source layout and verification

- Name semantic literals, including field indices, record strides, capacities,
  encoding limits, file signatures and timing/geometry policy. State the unit in
  names. Derive byte sizes from field counts; do not duplicate the formula.
- Keep clear 0/1 counting identities and explicit fixture/format data where the
  context explains them. Serialized state codes need named constants or types.
- Expand ambiguous helpers. Preserve established domain terms such as UTF8,
  AST, GSUB and GPOS. A function name must describe whether it appends or replaces.
- Prefer one responsibility and at most 20 body lines. Splitting an owner into
  private `.hats` groups preserves its representation; it does not by itself
  shorten a function or introduce independently linked modules.
- Relocations update ATS imports, C includes, CMake source groups, tools,
  compile-rejection tests and documentation together. Basenames remain unique
  because generated C files use them as identities.
- Never rename fixture text, serialized Unicode property tokens or log wire
  values while renaming code symbols. Explicit extern bindings must stay in sync.
- `check-build` builds excluded test executables; `check` then runs CTest.
  Graphical tests require a real X11/GLX display and cannot pass on its absence.
- Exhaust finite state matrices. For large input spaces combine typed contracts,
  boundary/property tests and pinned conformance data; do not claim perfection.
- Record existing behavioral bugs in `docs/olasi_hatalar.md`. Keep measured
  baselines distinct from leak-freedom proofs and target performance claims.
