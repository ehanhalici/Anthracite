# ATS Memory Buffer Invariant: Addressing & Structure Definition

## 1. 32-bit Word Addressing
When using 32-bit word operations on `Buf` in Anthracite:
- `buf_get32(b, i)` and `buf_set32(b, i, v)` accept **word indices** ($i$ maps to byte offset $4 \times i$), NOT byte offsets.
- Byte-level operations (`buf_get`, `buf_set`, `buf_len`, `buf_ensure`, `buf_set_len`) use byte counts.
- For structures with $K$ 32-bit words per element (e.g., $K=4$ words = 16 bytes):
  - Element $N$ starts at word index `imul(N, K)`.
  - Field $F$ ($0 \le F < K$) is accessed at word index `iadd(imul(N, K), F)`.
  - Never pass `imul(N, 16)` or `iadd(len, 4)` to `buf_get32`/`buf_set32`.

## 2. No Magic Numbers for Buffer-Backed Records
- NEVER hardcode byte sizes (such as `16`), word strides (such as `4`), or raw field indices directly in procedural code.
- Declare named constants using `macdef` for dynamic expressions. Representation
  constants also needed in static constraints may use `#define`, as in
  `src/foundation/units.hats`:
  - `macdef BYTES_PER_WORD = 4`
  - `macdef SIZEOF_<STRUCT> = <bytes>`
  - `macdef <STRUCT>_WORDS = <word_count>`
  - `macdef <STRUCT>_FLD_<NAME> = <offset>`
- Provide self-descriptive helper functions (`*_is_empty`, `*_count`, `*_base_word`) rather than repeating ad-hoc offset calculations.
- Derive record byte sizes from word counts. Keep imported constants and code
  generation bindings synchronized when moving a storage module.

## 3. Temporary boxed results without GC
- Every executable is built with `ATS_MEMALLOC_USER`: all ATS allocations go
  through the ATS2 arena in `src/core_runtime/kernel/arena.dats` (`ANTHRACITE_ARENA=0` falls
  back to libc). Payload-bearing nonlinear `datatype`/`Option` constructors
  can allocate boxes without automatic release.
- Never free ATS-allocated memory with libc `free`, and never let ATS free
  memory from libc `malloc`: object libraries must use the same allocator flag
  as the executables (`cmake/ATSGenerated.cmake` rewrites it for both).
- Prefer flat temporary records or consumed `Option_vt` results; borrow indexed
  `!option_vt(T,b)` when a result is inspected repeatedly, then dispose it once.
- `mem_live` tracks buffer payload, not every ATS constructor or GPU allocation.
  It is the calling thread's own live bytes: a Buf is charged to the thread that
  allocated it, whichever thread frees it (arena owner tag), so worker caches
  never appear as main-thread leaks.
  Keep LeakSanitizer findings distinct from balanced tracked-buffer tests (BUG-032).

## 4. Boundary Airlock & Recursion Fuel Discipline
- `recursion_fuel_available` calls `abort()` at zero and is reserved **strictly**
  for synthetic `MAX_REC_FUEL` ($2^{28}$) safety budgets. Natural loop counts,
  binary search bounds, and per-frame batch caps (such as `EVENT_DRAIN_BATCH_LIMIT`)
  MUST terminate normally on `left = 0` without calling `recursion_fuel_available`.
- Always guard preconditions before crossing `airlock_*`:
  - Guard `airlock_nat(x)` with `imax(0, x)` whenever `x` comes from subtraction or
    unproven dynamic state.
  - Guard `airlock_below(i, n)` with `0 <= i && i < n` (and `n > 0`).
  - Guard `airlock_span(lo, hi)` with `lo <= hi`.
- Recoverable layout/text-shaping rejections (`FontSpanRejected`,
  `NativeAnalysisRejected`) must never call `anth_die_*`; dispose linear inputs
  and degrade safely.
