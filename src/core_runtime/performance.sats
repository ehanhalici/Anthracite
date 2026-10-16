#include "core_runtime/performance_ids.h"
%{#
#include "core_runtime/performance.cats"
%}
fun performance_enable(enabled: int): void = "mac#anth_performance_enable"
fun performance_reset(): void = "mac#anth_performance_reset"
fun performance_note(key: int, amount: int): void = "mac#anth_performance_note"
fun performance_value(key: int): ullint = "mac#anth_performance_value"
