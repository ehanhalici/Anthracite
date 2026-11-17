#ifndef ANTH_PERFORMANCE_CATS
#define ANTH_PERFORMANCE_CATS
#include <stdint.h>
#include <time.h>
#include "core_runtime/performance_ids.h"
// Optional main-thread telemetry. No ownership or algorithmic decisions here.
extern uint64_t anth_performance_counters[PERF_COUNTER_COUNT];
extern uint64_t anth_perf_phase_ns[PERF_PHASE_COUNT];
extern uint64_t anth_perf_phase_calls[PERF_PHASE_COUNT];
extern uint64_t anth_perf_phase_max_ns[PERF_PHASE_COUNT];
extern int anth_performance_enabled;
// Benchmark-owned label copied into every profiler sample (0 = untagged).
extern volatile int anth_perf_sample_tag;

static inline long int anth_perf_clock_ns(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (long int)((uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec);
}

static inline void anth_performance_enable(int enabled) {
  anth_performance_enabled = enabled != 0;
}

static inline void anth_performance_reset(void) {
  for (int i = 0; i < PERF_COUNTER_COUNT; ++i) anth_performance_counters[i] = 0;
  for (int i = 0; i < PERF_PHASE_COUNT; ++i) {
    anth_perf_phase_ns[i] = 0;
    anth_perf_phase_calls[i] = 0;
    anth_perf_phase_max_ns[i] = 0;
  }
}

static inline void anth_performance_note(int key, int amount) {
  if (anth_performance_enabled && key >= 0 && key < PERF_COUNTER_COUNT && amount > 0)
    anth_performance_counters[key] += (uint64_t)amount;
}

static inline unsigned long long anth_performance_value(int key) {
  return key >= 0 && key < PERF_COUNTER_COUNT ? anth_performance_counters[key] : 0;
}

static inline long int anth_perf_now_ns(void) {
  return anth_performance_enabled ? anth_perf_clock_ns() : 0L;
}

static inline void anth_perf_phase_end(int phase, long int t0) {
  if (!anth_performance_enabled || t0 <= 0L || phase < 0 || phase >= PERF_PHASE_COUNT) return;
  long int now = anth_perf_clock_ns();
  uint64_t elapsed = now > t0 ? (uint64_t)(now - t0) : 0ULL;
  anth_perf_phase_ns[phase] += elapsed;
  anth_perf_phase_calls[phase] += 1ULL;
  if (elapsed > anth_perf_phase_max_ns[phase]) anth_perf_phase_max_ns[phase] = elapsed;
}

static inline unsigned long long anth_perf_phase_total(int phase) {
  return (phase >= 0 && phase < PERF_PHASE_COUNT) ? (unsigned long long)anth_perf_phase_ns[phase] : 0ULL;
}

static inline unsigned long long anth_perf_phase_count(int phase) {
  return (phase >= 0 && phase < PERF_PHASE_COUNT) ? (unsigned long long)anth_perf_phase_calls[phase] : 0ULL;
}

static inline unsigned long long anth_perf_phase_max(int phase) {
  return (phase >= 0 && phase < PERF_PHASE_COUNT) ? (unsigned long long)anth_perf_phase_max_ns[phase] : 0ULL;
}

static inline void anth_perf_set_sample_tag(int tag) { anth_perf_sample_tag = tag; }

void anth_perf_runtime_init(void);
void anth_perf_runtime_dump(const char *tag);
#endif
