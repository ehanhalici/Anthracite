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
- Production builds use `ATS_MEMALLOC_LIBC`. Payload-bearing nonlinear
  `datatype`/`Option` constructors can allocate boxes without automatic release.
- Prefer flat temporary records or consumed `Option_vt` results; borrow indexed
  `!option_vt(T,b)` when a result is inspected repeatedly, then dispose it once.
- `mem_live` tracks buffer payload, not every ATS constructor or GPU allocation.
  Keep LeakSanitizer findings distinct from balanced tracked-buffer tests (BUG-032).
