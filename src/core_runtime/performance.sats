#include "core_runtime/performance_ids.h"
%{#
#include "core_runtime/kernel/kernel.cats"
%}
(* Optional telemetry, implemented in ATS2 by core_runtime/kernel/thread_stats.dats.
   No ownership or algorithmic decisions depend on it. *)
fun performance_enable(enabled: int): void = "ext#anth_performance_enable"
fun performance_reset(): void = "ext#anth_performance_reset"
fun performance_note(key: int, amount: int): void = "ext#anth_performance_note"
fun performance_value(key: int): ullint = "ext#anth_performance_value"
fun performance_now_ns(): lint = "ext#anth_perf_now_ns"
fun performance_phase_end(phase: int, t0: lint): void = "ext#anth_perf_phase_end"
fun performance_phase_total(phase: int): ullint = "ext#anth_perf_phase_total"
fun performance_phase_count(phase: int): ullint = "ext#anth_perf_phase_count"
fun performance_phase_max(phase: int): ullint = "ext#anth_perf_phase_max"
fun performance_runtime_init(): void = "mac#anth_perf_runtime_init"
fun performance_runtime_dump(tag: string): void = "mac#anth_perf_runtime_dump"
fun performance_set_sample_tag(tag: int): void = "ext#anth_perf_set_sample_tag"
