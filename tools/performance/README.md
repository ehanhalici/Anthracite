# Performance tooling

| File | Purpose |
|---|---|
| `gen_fixture.py` | Deterministic synthetic note (`heavy.md`, ~87 KB / ~1300 lines) and 50-note vault. |
| `run_matrix.sh` | read/edit × jump/wheel/page × N fresh processes, plus search; writes JSON summaries. |
| `summarize.py` | Median / nearest-rank p95 / max per frame label for wall time, `cpu_ms`, sub-phases and counters. `--json`, `--compare BASE.json`. |
| `map_c_to_ats.py` | Maps `ANTHRACITE_PERF_PROFILE` samples to C symbols and ATS2 sources. `--tag first|scroll|...` keeps one benchmark phase. |
| `tests/performance/perf_budget.py` | CTest `performance_budgets`: counter budgets (no wall time), Xvfb fallback, skip code 77. |

## Benchmarks

```
document_performance VAULT FILE [read|edit] [jump|wheel|page]
search_performance VAULT QUERY [REPEAT]
```

Scroll scenarios:

- `jump`: 30 positions spread over the whole document, pre-visited once (scrollbar drag).
  Each frame shows an entirely new viewport, so the 128-slot `VisualPlans` cache misses
  by construction.
- `wheel`: the app's 48 px wheel step, 60 frames down then 60 up from mid-document.
  This is what normal reading looks like.
- `page`: one viewport per frame from the top (PageDown).

Frame labels: `first` (one frame, viewport band only), `background` (frames that
drain deferred wrapping at 6 ms CPU each, before the idle frames), `warm_idle`,
`warm_scroll_<scenario>`. Profile tags: `first`, `background`, `idle`, `scroll`, `prewarm`.

Frame lines carry `elapsed_ns` (wall), `cpu_ns` (draw + `rend_flush` submission),
`gpu_wait_ns` (`glFinish`) and `swap_ns`. With VSync on (NVIDIA, the default),
`glFinish` absorbs the VBlank wait, so `elapsed` sits at ~16.6 ms whatever the CPU cost.
Compare `cpu_ms`, or run with `__GL_SYNC_TO_VBLANK=0` / `vblank_mode=0`.

## Profiling

```
ANTHRACITE_PERF_PROFILE=prof.txt build/document_performance VAULT FILE read wheel
python3 tools/performance/map_c_to_ats.py --tag scroll build/document_performance prof.txt
```

The sampler uses a main-thread CPU-time timer (1 kHz, `CLOCK_THREAD_CPUTIME_ID`), so
driver worker threads add no samples. Stacks go up to 64 frames deep and are tagged with
the benchmark phase. Profile a Release build with frame pointers: Debug `-Og` puts
call overhead into ATS prelude wrappers (`atspre_g0int_add_int`, `buf_get`) that the
shipped binary inlines.

```
echo 'add_compile_options(-g -fno-omit-frame-pointer)' > /tmp/fp.cmake
cmake -S . -B /tmp/anth-rel -DCMAKE_BUILD_TYPE=Release -DCMAKE_PROJECT_INCLUDE=/tmp/fp.cmake
cmake --build /tmp/anth-rel --target document_performance search_performance
```
