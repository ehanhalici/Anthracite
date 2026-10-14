staload "mem.sats"
staload "data_text/bidi_types.sats"
staload "data_text/bidi_sequence.sats"

datavtype BidiRuns = BidiRuns of (Buf, Buf, Buf, Buf, Buf, Buf, Buf, Buf, Buf)
typedef RunCounts = @{active=int, runs=int}
fun bidi_runs_make(capacity: int): BidiRuns
fun bidi_runs_dispose(runs: BidiRuns): void
fun bidi_runs_build(runs: !BidiRuns, work: !BidiWork): RunCounts
fun bidi_runs_link(runs: !BidiRuns, work: !BidiWork, counts: RunCounts, base: int): void
fun bidi_runs_sequence(runs: !BidiRuns, work: !BidiWork, root: int, capacity: int): BidiSequence
fun bidi_run_active(runs: !BidiRuns, i: int): int
fun bidi_run_set_active(runs: !BidiRuns, i: int, cp: int): void
fun bidi_run_map(runs: !BidiRuns, cp: int): int
fun bidi_run_set_map(runs: !BidiRuns, cp: int, run: int): void
fun bidi_run_start(runs: !BidiRuns, i: int): int
fun bidi_run_set_start(runs: !BidiRuns, i: int, start: int): void
fun bidi_run_end(runs: !BidiRuns, i: int): int
fun bidi_run_set_end(runs: !BidiRuns, i: int, endpos: int): void
fun bidi_run_next(runs: !BidiRuns, i: int): int
fun bidi_run_set_next(runs: !BidiRuns, i: int, next: int): void
fun bidi_run_incoming(runs: !BidiRuns, i: int): bool
fun bidi_run_set_incoming(runs: !BidiRuns, i: int): void
fun bidi_run_before(runs: !BidiRuns, i: int): int
fun bidi_run_set_before(runs: !BidiRuns, i: int, level: int): void
fun bidi_run_after(runs: !BidiRuns, i: int): int
fun bidi_run_set_after(runs: !BidiRuns, i: int, level: int): void
fun bidi_run_level(runs: !BidiRuns, i: int): int
fun bidi_run_set_level(runs: !BidiRuns, i: int, level: int): void

