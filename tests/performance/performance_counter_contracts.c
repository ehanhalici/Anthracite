#include "core_runtime/performance_ids.h"
/* ATS2 telemetry (core_runtime/kernel/thread_stats.dats). */
void anth_performance_enable(int enabled);
void anth_performance_reset(void);
void anth_performance_note(int key, int amount);
unsigned long long anth_performance_value(int key);
int main(void) {
  anth_performance_enable(0);
  anth_performance_reset();
  anth_performance_note(PERF_AST_PARSES, 3);
  if (anth_performance_value(PERF_AST_PARSES) != 0) return 1;
  anth_performance_enable(1);
  anth_performance_note(PERF_AST_PARSES, 3);
  anth_performance_note(PERF_AST_PARSES, 5);
  anth_performance_note(-1, 7);
  anth_performance_note(PERF_COUNTER_COUNT, 7);
  anth_performance_note(PERF_AST_PARSES, -7);
  if (anth_performance_value(PERF_AST_PARSES) != 8) return 1;
  if (anth_performance_value(-1) != 0) return 1;
  anth_performance_reset();
  return anth_performance_value(PERF_AST_PARSES) != 0;
}
