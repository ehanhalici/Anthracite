#include "core_runtime/performance.cats"
uint64_t anth_performance_counters[PERF_COUNTER_COUNT];
uint64_t anth_perf_phase_ns[PERF_PHASE_COUNT];
uint64_t anth_perf_phase_calls[PERF_PHASE_COUNT];
uint64_t anth_perf_phase_max_ns[PERF_PHASE_COUNT];
int anth_performance_enabled;
volatile int anth_perf_sample_tag;
