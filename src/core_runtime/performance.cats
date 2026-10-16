#ifndef ANTH_PERFORMANCE_CATS
#define ANTH_PERFORMANCE_CATS
#include <stdint.h>
#include "core_runtime/performance_ids.h"
// Optional main-thread telemetry. No ownership or algorithmic decisions here.
extern uint64_t anth_performance_counters[PERF_COUNTER_COUNT];
extern int anth_performance_enabled;
static inline void anth_performance_enable(int enabled) {
  anth_performance_enabled = enabled != 0;
}
static inline void anth_performance_reset(void) {
  for (int i = 0; i < PERF_COUNTER_COUNT; ++i) anth_performance_counters[i] = 0;
}
static inline void anth_performance_note(int key, int amount) {
  if (anth_performance_enabled && key >= 0 && key < PERF_COUNTER_COUNT && amount > 0)
    anth_performance_counters[key] += (uint64_t)amount;
}
static inline unsigned long long anth_performance_value(int key) {
  return key >= 0 && key < PERF_COUNTER_COUNT ? anth_performance_counters[key] : 0;
}
#endif
