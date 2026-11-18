# Threads, Shared State and Cache-Line Layout

1. **One pool, created once.** `src/core_runtime/kernel/workers.dats` starts at text
   engine startup and lives until exit. Never create or join threads per task.
   Workers sit one per physical core (SMT siblings are not cores), main thread's
   L3 domain first; the main (event loop / GL) thread is never pinned.
2. **Workers never touch shared mutable state.** A worker owns its `Font`,
   `FontTextSession`, shape-plan cache, compiled search pattern, file cache,
   arena heap and counter block (`ui_workspace/workers/worker_context.dats`).
   Jobs carry everything they need (text copies, face paths, styles); results
   carry everything back. Workers never see a `Doc`, `Tabs`, `Cache` or `Rend`.
3. **GL and layout stay on the main thread.** Only the main thread splices
   results (`visual_wrap_apply`), runs `doc_layout_mode`, paints and merges
   search output in catalog order.
4. **Ownership moves with the payload.** Jobs and results are ATS boxes passed
   through the typed `*_submit` / `*_take` wrappers (kernel.cats box macros over
   `workers_submit` / `workers_take`); check `workers_has_room` /
   `workers_has_result` first. Results are
   stamped (document identity + `VisualKey.build`, search generation) and a
   stale result is disposed, never applied.
5. **No two threads write the same cache line.** Per-thread hot structures are
   root cells in `core_runtime/kernel/kernel.cats`, `alignas(64)` and filling
   whole lines (`_Static_assert`); producer and consumer
   indices sit on different lines; counters are per thread and summed on read.
   A field other threads must write (arena `remote`, ring `head`) gets its own
   line. Process-wide counters that any thread may bump must not exist.
6. **No new C.** Runtime logic is ATS2 (`src/core_runtime/kernel/*.dats`); the
   only C beneath it is `kernel.cats`: root-cell storage and one-line, loop-free,
   branch-free macros (atomics, futex, syscalls). Root cells touched by more than
   one thread are atomic, `_Thread_local`, set once before threads start, or
   behind a mutex on a cold path. Every index reaching a macro carries a static
   bound in its ATS declaration; every syscall result is checked in ATS; the
   kernel never allocates (unboxed results, `~1` = none).
7. **Parallel output must equal sequential output.** Every parallel path keeps
   a sequential switch (`ANTHRACITE_PARALLEL_WRAP=0`, `ANTHRACITE_PARALLEL_SEARCH=0`)
   and a contract that compares both byte for byte across worker counts with
   timing jitter (`parallel_wrap_contracts`, `parallel_search_contracts`).
   Threading changes also pass the `tsan` label in a `-DANTHRACITE_TSAN=ON` build
   and the `perf` scaling checks (`arena_scaling_contracts`, `pool_scaling_contracts`).
8. **Work size.** A job's working set fits half a worker's L2 share
   (`workers_chunk_bytes`); files are never split across jobs. Prefer
   several small jobs per worker over one large one so stealing can balance.
