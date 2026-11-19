(* Per-thread statistics rows, phase timers and Buf accounting (see
   thread_stats.sats). Pure ATS2 over the root cells of kernel.cats: every row
   and word index below is a static natural number bounded by the row table,
   so the macros are only reached with in-range indexes. *)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "core_runtime/performance.sats"
staload "core_runtime/kernel/thread_stats.sats"
staload "core_runtime/kernel/arena.sats"
%{^
#include "core_runtime/kernel/kernel.cats"
ANTH_KERNEL_STATS_ROOTS()
%}

(* Row layout: counters [0, PERF_COUNTER_COUNT), then live bytes, allocs, frees
   (words 29-31, written by the row's own thread only), then on the row's
   fifth cache line, alone, the bytes of this thread's blocks freed by other
   threads (the only word other threads write; kernel.cats asserts the layout).
   A thread's live bytes are WORD_LIVE - WORD_REMOTE, so the owner's hot path
   is a plain load and store: no locked instruction. *)
#define WORD_LIVE 29
#define WORD_ALLOCS 30
#define WORD_FREES 31
#define WORD_REMOTE 32
#define SHARED_SLOT 127
#define PHASE_TOTAL 0
#define PHASE_CALLS 1
#define PHASE_MAX 2

extern fun k_stats_load{s,k:nat | s < STATS_SLOTS; k < STATS_WORDS}(s: int s, k: int k): lint = "mac#anth_k_stats_load"
extern fun k_stats_store{s,k:nat | s < STATS_SLOTS; k < STATS_WORDS}(s: int s, k: int k, v: lint): void = "mac#anth_k_stats_store"
extern fun k_stats_fetch_add{s,k:nat | s < STATS_SLOTS; k < STATS_WORDS}(s: int s, k: int k, v: lint): void = "mac#anth_k_stats_fetch_add"
extern fun k_stats_claim(): int = "mac#anth_k_stats_claim"
extern fun k_stats_claimed(): int = "mac#anth_k_stats_claimed"
extern fun k_main_claim(): bool = "mac#anth_k_main_claim"
extern fun k_perf_enabled(): int = "mac#anth_k_perf_enabled"
extern fun k_perf_set_enabled(v: int): void = "mac#anth_k_perf_set_enabled"
extern fun k_sample_tag_set(v: int): void = "mac#anth_k_sample_tag_set"
extern fun k_phase_load{t,p:nat | t < 3; p < PHASE_SLOTS}(t: int t, p: int p): lint = "mac#anth_k_phase_load"
extern fun k_phase_store{t,p:nat | t < 3; p < PHASE_SLOTS}(t: int t, p: int p, v: lint): void = "mac#anth_k_phase_store"
extern fun k_tls_stats_slot(): int = "mac#anth_k_tls_stats_slot"
extern fun k_tls_stats_set_slot(v: int): void = "mac#anth_k_tls_stats_set_slot"
extern fun k_tls_is_main(): int = "mac#anth_k_tls_is_main"
extern fun k_tls_set_is_main(v: int): void = "mac#anth_k_tls_set_is_main"
extern fun k_clock_ns(): lint = "mac#anth_k_clock_ns"

fun to_ull(x: lint): ullint = if x > 0L then g0int2uint_lint_ullint(x) else g0int2uint_lint_ullint(0L)

(* ---- rows ---- *)
fun clamp_slot(i: int): stats_slot = let val i = g1ofg0(i) in
  if i >= 0 then (if i < STATS_SLOTS then i else SHARED_SLOT) else SHARED_SLOT end

(* Threads beyond the table share the last row; only that row needs atomic
   read-modify-write, every other row has a single writer. *)
fun claim_slot(): stats_slot = let
  val s = clamp_slot(k_stats_claim())
  val () = k_tls_stats_set_slot(s + 1)
  val () = arena_set_owner_slot(s + 1)
in s end

implement thread_stats_slot() = let val v = g1ofg0(k_tls_stats_slot()) in
  if v >= 1 then (if v <= STATS_SLOTS then v - 1 else claim_slot()) else claim_slot() end

implement thread_stats_claimed() = let val n = g1ofg0(k_stats_claimed()) in
  if n >= 0 then (if n <= STATS_SLOTS then n else STATS_SLOTS) else 0 end

fun row_add{k:nat | k < STATS_WORDS}(s: stats_slot, k: int k, v: lint): void =
  if s = SHARED_SLOT then k_stats_fetch_add(s, k, v)
  else k_stats_store(s, k, k_stats_load(s, k) + v)

fun sum_rows{k:nat | k < STATS_WORDS}{i,n:nat | i <= n; n <= STATS_SLOTS} .<n-i>.
  (k: int k, i: int i, n: int n, acc: lint): lint =
  if i < n then sum_rows(k, i + 1, n, acc + k_stats_load(i, k)) else acc

fun clear_row{s:nat | s < STATS_SLOTS}{k:nat | k <= WORD_LIVE} .<WORD_LIVE-k>. (s: int s, k: int k): void =
  if k < WORD_LIVE then let val () = k_stats_store(s, k, 0L) in clear_row(s, k + 1) end else ()

fun clear_rows{i,n:nat | i <= n; n <= STATS_SLOTS} .<n-i>. (i: int i, n: int n): void =
  if i < n then let val () = clear_row(i, 0) in clear_rows(i + 1, n) end else ()

(* ---- main thread ---- *)
implement thread_is_main() = let val known = k_tls_is_main() in
  if known = 1 then true else if known = 2 then false
  else let val main = k_main_claim() val () = k_tls_set_is_main(if main then 1 else 2) in main end end

(* ---- counters ---- *)
fun perf_on(): bool = k_perf_enabled() <> 0

implement performance_enable(enabled) = k_perf_set_enabled(if enabled <> 0 then 1 else 0)

implement performance_note(key, amount) = let val k = g1ofg0(key) in
  if perf_on() then if amount > 0 then if k >= 0 then
    if k < PERF_COUNTER_COUNT then if k < WORD_LIVE then row_add(thread_stats_slot(), k, g0int2int_int_lint(amount))
    else () else () else () else () else () end

implement performance_sum(key) = let val k = g1ofg0(key) in
  if k >= 0 then (if k < PERF_COUNTER_COUNT then (if k < WORD_LIVE then to_ull(sum_rows(k, 0, thread_stats_claimed(), 0L))
    else to_ull(0L)) else to_ull(0L)) else to_ull(0L) end

implement performance_value(key) = performance_sum(key)

(* ---- phases (main thread only; other threads' calls are ignored) ---- *)
fun clear_phases{p:nat | p <= PHASE_SLOTS} .<PHASE_SLOTS-p>. (p: int p): void =
  if p < PHASE_SLOTS then let
    val () = k_phase_store(PHASE_TOTAL, p, 0L) val () = k_phase_store(PHASE_CALLS, p, 0L)
    val () = k_phase_store(PHASE_MAX, p, 0L)
  in clear_phases(p + 1) end else ()

implement performance_reset() = let val () = clear_rows(0, thread_stats_claimed()) in clear_phases(0) end

implement performance_now_ns() = if perf_on() then (if thread_is_main() then k_clock_ns() else 0L) else 0L

implement performance_phase_end(phase, t0) = let val p = g1ofg0(phase) in
  if perf_on() then if t0 > 0L then if p >= 0 then if p < PERF_PHASE_COUNT then if p < PHASE_SLOTS then
    if thread_is_main() then let
      val now = k_clock_ns()
      val elapsed = if now > t0 then now - t0 else 0L
      val () = k_phase_store(PHASE_TOTAL, p, k_phase_load(PHASE_TOTAL, p) + elapsed)
      val () = k_phase_store(PHASE_CALLS, p, k_phase_load(PHASE_CALLS, p) + 1L)
    in if elapsed > k_phase_load(PHASE_MAX, p) then k_phase_store(PHASE_MAX, p, elapsed) else () end
    else () else () else () else () else () else () end

fun phase_word{t:nat | t < 3}(t: int t, phase: int): ullint = let val p = g1ofg0(phase) in
  if p >= 0 then (if p < PERF_PHASE_COUNT then (if p < PHASE_SLOTS then to_ull(k_phase_load(t, p))
    else to_ull(0L)) else to_ull(0L)) else to_ull(0L) end
implement performance_phase_total(phase) = phase_word(PHASE_TOTAL, phase)
implement performance_phase_count(phase) = phase_word(PHASE_CALLS, phase)
implement performance_phase_max(phase) = phase_word(PHASE_MAX, phase)

implement performance_set_sample_tag(tag) = k_sample_tag_set(tag)

(* ---- Buf accounting ---- *)
implement thread_stats_alloc(n) = let
  val s = thread_stats_slot()
  val () = row_add(s, WORD_ALLOCS, 1L)
  val () = row_add(s, WORD_LIVE, g0int2int_int_lint(n))
  val () = performance_note(PERF_ALLOC_CALLS, 1)
in performance_note(PERF_ALLOC_BYTES, n) end

(* The owner row is the arena's record for the block just freed (slot + 1 of
   another thread), or the calling thread's own row (tag 0: own block, or
   memory outside the arena). *)
fun owner_slot(self: stats_slot): stats_slot = let val tag = g1ofg0(arena_freed_slot()) in
  if tag >= 1 then (if tag <= STATS_SLOTS then clamp_slot(tag - 1) else self) else self end
implement thread_stats_freed(n) = let
  val s = thread_stats_slot()
  val () = row_add(s, WORD_FREES, 1L)
  val owner = owner_slot(s)
  val bytes = g0int2int_int_lint(n)
in if owner = s then row_add(s, WORD_LIVE, ~bytes) else k_stats_fetch_add(owner, WORD_REMOTE, bytes) end

fun row_live(s: stats_slot): lint = k_stats_load(s, WORD_LIVE) - k_stats_load(s, WORD_REMOTE)
implement thread_stats_live() = g0int2int_lint_int(row_live(thread_stats_slot()))
implement thread_stats_live_total() = let val n = thread_stats_claimed() in
  g0int2int_lint_llint(sum_rows(WORD_LIVE, 0, n, 0L) - sum_rows(WORD_REMOTE, 0, n, 0L)) end
