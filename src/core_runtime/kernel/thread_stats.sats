(* Per-thread statistics rows (ATS2; the storage and atomics are the macros of
   kernel.cats). Each thread writes only its own row: a cache-line-aligned
   block of 64-bit words, so counting never touches another core's line.
   Reads sum every claimed row. Exported for the C ABI (Buf accounting in
   mem.dats, the developer-only sampler). *)
%{#
#include "core_runtime/kernel/kernel.cats"
%}
#define STATS_SLOTS 128
#define STATS_WORDS 40
#define PHASE_SLOTS 64
typedef stats_slot = natLt(STATS_SLOTS)
(* Row of the calling thread; claimed on first use. *)
fun thread_stats_slot(): stats_slot = "ext#anth_thread_stats_slot"
fun thread_stats_claimed(): natLte(STATS_SLOTS)
(* The thread that asks first is the main thread (the process starts on it;
   the worker pool claims it before starting any worker). *)
fun thread_is_main(): bool = "ext#anth_thread_is_main"
fun performance_sum(key: int): ullint = "ext#anth_performance_sum"
(* Buf accounting: bytes are charged to the allocating thread; a free lowers
   the owner's live bytes, whichever thread frees. thread_stats_freed is called
   right after the block went back to the arena, on the freeing thread: the
   owner is the one arena_freed_slot recorded for that free. mem_live is the
   calling thread's own live bytes. *)
fun thread_stats_alloc(n: int): void = "ext#anth_mem_alloc"
fun thread_stats_freed(n: int): void = "ext#anth_mem_freed"
fun thread_stats_live(): int = "ext#anth_mem_live"
fun thread_stats_live_total(): llint = "ext#anth_stats_live_bytes"
