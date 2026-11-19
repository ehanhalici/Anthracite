(* Worker pool (see core_runtime/workers.sats), pure ATS2 over the root cells,
   atomics and syscalls of kernel.cats. Every worker, ring, slot, CPU, register
   and buffer index reaching a macro is a static natural number below its
   table size; syscall results are checked before use (open/read failures read
   as "no data", never as data). Shared-state budget per job: one slot write
   and one release store of `tail` by the main thread, one CAS on `head` by the
   worker that claims it, one SPSC push of the result, and a futex wake only
   when the worker sleeps. Thieves read other rings only while idle. *)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "core_runtime/workers.sats"
staload "core_runtime/kernel/thread_stats.sats"
%{^
#define ANTH_KERNEL_POOL_IMPL 1
#include "core_runtime/kernel/kernel.cats"
ANTH_KERNEL_POOL_ROOTS()
%}

#define POOL_MAX 32
#define RING_SLOTS 256
#define RINGS 3
#define RING_JOBS 0
#define WSTATS 8
#define CPU_WORDS 16
#define CPU_SETS 8
#define REGS 64
#define SEARCH_CHUNKS 4096
#define MAX_CPUS 1024
#define TEXT_BYTES 262144
#define PATH_BYTES 1024
#define SPIN_ROUNDS 4000
#define LOAD_SAMPLE_NS 250000000L
#define DEFAULT_L2_BYTES 1048576
(* worker statistics words *)
#define STAT_JOBS 0
#define STAT_STEALS 1
#define STAT_BUSY_NS 2
#define STAT_SLEEPS 3
#define STAT_HW 4
(* registers: line 0 is written before any worker starts and read-only after
   (workers read it); the main thread's mutable registers start at line 1. *)
#define REG_SLOTS 0
#define REG_JITTER 1
#define REG_COUNTERS 2
#define REG_COUNT 8
#define REG_LOAD_SAMPLED_AT 9
#define REG_ACTIVE_COUNT 10
#define REG_TICK_NS 11
#define REG_WRAP_BUILD 16
#define REG_WRAP_START 17
#define REG_WRAP_CURSOR 18
#define REG_WRAP_TOTAL 19
#define REG_WRAP_DISABLED 20
#define REG_SEARCH_GENERATION 24
#define REG_SEARCH_ACTIVE 25
#define REG_SEARCH_CHUNKS 26
#define REG_SEARCH_CAPACITY 27
#define REG_SEARCH_DISPATCHED 28
#define REG_SEARCH_MERGED 29
#define REG_SEARCH_INFLIGHT 30
(* topology scratch sets *)
#define SET_ALLOWED 0
#define SET_SEEN 1
#define SET_MAIN_L3 2
#define SET_SIBLINGS 3
#define SET_TMP 4
(* /proc/stat samples *)
#define SAMPLE_PREV 0
#define SAMPLE_NOW 1
(* perf_event hardware configs: cycles, instructions, cache misses *)
#define HW_CYCLES 0
#define HW_INSTRUCTIONS 1
#define HW_CACHE_MISSES 3

typedef wid = natLt(POOL_MAX)
typedef rid = natLt(RINGS)
typedef cpu = natLt(MAX_CPUS)
typedef setid = natLt(CPU_SETS)

(* ---- adaptor macros (kernel.cats) ---- *)
extern fun k_tail_relaxed{w,r:nat | w < POOL_MAX; r < RINGS}(w: int w, r: int r): uint = "mac#anth_k_ring_tail_relaxed"
extern fun k_tail_acquire{w,r:nat | w < POOL_MAX; r < RINGS}(w: int w, r: int r): uint = "mac#anth_k_ring_tail_acquire"
extern fun k_tail_release{w,r:nat | w < POOL_MAX; r < RINGS}(w: int w, r: int r, v: uint): void = "mac#anth_k_ring_tail_release"
extern fun k_head_relaxed{w,r:nat | w < POOL_MAX; r < RINGS}(w: int w, r: int r): uint = "mac#anth_k_ring_head_relaxed"
extern fun k_head_acquire{w,r:nat | w < POOL_MAX; r < RINGS}(w: int w, r: int r): uint = "mac#anth_k_ring_head_acquire"
extern fun k_head_release{w,r:nat | w < POOL_MAX; r < RINGS}(w: int w, r: int r, v: uint): void = "mac#anth_k_ring_head_release"
extern fun k_head_cas{w,r:nat | w < POOL_MAX; r < RINGS}(w: int w, r: int r, seen: uint, next: uint): bool = "mac#anth_k_ring_head_cas"
extern fun k_head_cache{w,r:nat | w < POOL_MAX; r < RINGS}(w: int w, r: int r): uint = "mac#anth_k_ring_head_cache"
extern fun k_set_head_cache{w,r:nat | w < POOL_MAX; r < RINGS}(w: int w, r: int r, v: uint): void = "mac#anth_k_ring_set_head_cache"
extern fun k_tail_cache{w,r:nat | w < POOL_MAX; r < RINGS}(w: int w, r: int r): uint = "mac#anth_k_ring_tail_cache"
extern fun k_set_tail_cache{w,r:nat | w < POOL_MAX; r < RINGS}(w: int w, r: int r, v: uint): void = "mac#anth_k_ring_set_tail_cache"
extern fun k_slot_kind{w,r,s:nat | w < POOL_MAX; r < RINGS; s < RING_SLOTS}(w: int w, r: int r, s: int s): int = "mac#anth_k_ring_kind"
extern fun k_set_slot_kind{w,r,s:nat | w < POOL_MAX; r < RINGS; s < RING_SLOTS}(w: int w, r: int r, s: int s, v: int): void = "mac#anth_k_ring_set_kind"
extern fun k_slot_payload{w,r,s:nat | w < POOL_MAX; r < RINGS; s < RING_SLOTS}(w: int w, r: int r, s: int s): ptr = "mac#anth_k_ring_payload"
extern fun k_set_slot_payload{w,r,s:nat | w < POOL_MAX; r < RINGS; s < RING_SLOTS}(w: int w, r: int r, s: int s, p: ptr): void = "mac#anth_k_ring_set_payload"
extern fun k_wake_bump{w:nat | w < POOL_MAX}(w: int w): void = "mac#anth_k_wake_bump"
extern fun k_wake_load{w:nat | w < POOL_MAX}(w: int w): uint = "mac#anth_k_wake_load"
extern fun k_sleeping_load{w:nat | w < POOL_MAX}(w: int w): uint = "mac#anth_k_sleeping_load"
extern fun k_sleeping_store{w:nat | w < POOL_MAX}(w: int w, v: uint): void = "mac#anth_k_sleeping_store"
extern fun k_futex_wait{w:nat | w < POOL_MAX}(w: int w, seen: uint): void = "mac#anth_k_futex_wait"
extern fun k_futex_wake{w:nat | w < POOL_MAX}(w: int w): void = "mac#anth_k_futex_wake"
extern fun k_wstat{w,f:nat | w < POOL_MAX; f < WSTATS}(w: int w, f: int f): lint = "mac#anth_k_wstat"
extern fun k_wstat_store{w,f:nat | w < POOL_MAX; f < WSTATS}(w: int w, f: int f, v: lint): void = "mac#anth_k_wstat_store"
extern fun k_cpu_word{w,i:nat | w < POOL_MAX; i < CPU_WORDS}(w: int w, i: int i): ullint = "mac#anth_k_cpu_word"
extern fun k_set_cpu_word{w,i:nat | w < POOL_MAX; i < CPU_WORDS}(w: int w, i: int i, v: ullint): void = "mac#anth_k_set_cpu_word"
extern fun k_core{w:nat | w < POOL_MAX}(w: int w): int = "mac#anth_k_core"
extern fun k_set_core{w:nat | w < POOL_MAX}(w: int w, v: int): void = "mac#anth_k_set_core"
extern fun k_chunk{w:nat | w < POOL_MAX}(w: int w): int = "mac#anth_k_chunk"
extern fun k_set_chunk{w:nat | w < POOL_MAX}(w: int w, v: int): void = "mac#anth_k_set_chunk"
extern fun k_hw_fd{w,i:nat | w < POOL_MAX; i < 3}(w: int w, i: int i): int = "mac#anth_k_hw_fd"
extern fun k_set_hw_fd{w,i:nat | w < POOL_MAX; i < 3}(w: int w, i: int i, v: int): void = "mac#anth_k_set_hw_fd"
extern fun k_context{w:nat | w < POOL_MAX}(w: int w): ptr = "mac#anth_k_context"
extern fun k_set_context{w:nat | w < POOL_MAX}(w: int w, c: ptr): void = "mac#anth_k_set_context"
extern fun k_cpu_ns_seen{w:nat | w < POOL_MAX}(w: int w): lint = "mac#anth_k_cpu_ns_seen"
extern fun k_set_cpu_ns_seen{w:nat | w < POOL_MAX}(w: int w, v: lint): void = "mac#anth_k_set_cpu_ns_seen"
extern fun k_active{w:nat | w < POOL_MAX}(w: int w): int = "mac#anth_k_active"
extern fun k_set_active{w:nat | w < POOL_MAX}(w: int w, v: int): void = "mac#anth_k_set_active"
extern fun k_pool_state(): int = "mac#anth_k_pool_state"
extern fun k_pool_claim(): bool = "mac#anth_k_pool_claim"
extern fun k_pool_ready(): void = "mac#anth_k_pool_ready"
extern fun k_visual_next_build(): int = "mac#anth_k_visual_next_build"
extern fun k_reg{i:nat | i < REGS}(i: int i): lint = "mac#anth_k_reg"
extern fun k_set_reg{i:nat | i < REGS}(i: int i, v: lint): void = "mac#anth_k_set_reg"
extern fun k_wrap_document(): ptr = "mac#anth_k_wrap_document"
extern fun k_set_wrap_document(p: ptr): void = "mac#anth_k_set_wrap_document"
extern fun k_set_word{s,i:nat | s < CPU_SETS; i < CPU_WORDS}(s: int s, i: int i): ullint = "mac#anth_k_set_word"
extern fun k_set_set_word{s,i:nat | s < CPU_SETS; i < CPU_WORDS}(s: int s, i: int i, v: ullint): void = "mac#anth_k_set_set_word"
extern fun k_cpu_busy{t,c:nat | t < 2; c < MAX_CPUS}(t: int t, c: int c): lint = "mac#anth_k_cpu_busy"
extern fun k_set_cpu_busy{t,c:nat | t < 2; c < MAX_CPUS}(t: int t, c: int c, v: lint): void = "mac#anth_k_set_cpu_busy"
extern fun k_cpu_total{t,c:nat | t < 2; c < MAX_CPUS}(t: int t, c: int c): lint = "mac#anth_k_cpu_total"
extern fun k_set_cpu_total{t,c:nat | t < 2; c < MAX_CPUS}(t: int t, c: int c, v: lint): void = "mac#anth_k_set_cpu_total"
extern fun k_search_first{i:nat | i <= SEARCH_CHUNKS}(i: int i): int = "mac#anth_k_search_first"
extern fun k_set_search_first{i:nat | i <= SEARCH_CHUNKS}(i: int i, v: int): void = "mac#anth_k_set_search_first"
extern fun k_parked{i:nat | i < SEARCH_CHUNKS}(i: int i): ptr = "mac#anth_k_parked"
extern fun k_set_parked{i:nat | i < SEARCH_CHUNKS}(i: int i, p: ptr): void = "mac#anth_k_set_parked"
extern fun k_text{i:nat | i < TEXT_BYTES}(i: int i): int = "mac#anth_k_text"
extern fun k_set_path_byte{i:nat | i < PATH_BYTES}(i: int i, c: int): void = "mac#anth_k_set_path_byte"
extern fun k_path_put{o,n:nat | o + n < PATH_BYTES}(off: int o, s: string n): void = "mac#anth_k_path_put"
extern fun k_open_path(): int = "mac#anth_k_open_path"
extern fun k_read_text{o,n:nat | o + n <= TEXT_BYTES}(fd: int, off: int o, n: int n): int = "mac#anth_k_read_text"
extern fun k_close(fd: int): void = "mac#anth_k_close"
extern fun k_getaffinity{s:nat | s < CPU_SETS}(s: int s): int = "mac#anth_k_getaffinity"
extern fun k_getcpu(): int = "mac#anth_k_getcpu"
extern fun k_clk_tck(): lint = "mac#anth_k_clk_tck"
extern fun k_l2_bytes(): lint = "mac#anth_k_l2_bytes"
extern fun k_thread_start{w:nat | w < POOL_MAX}(w: int w): int = "mac#anth_k_thread_start"
extern fun k_thread_clock{w:nat | w < POOL_MAX}(w: int w): void = "mac#anth_k_thread_clock"
extern fun k_thread_cpu_ns{w:nat | w < POOL_MAX}(w: int w): lint = "mac#anth_k_thread_cpu_ns"
extern fun k_pin_self{w:nat | w < POOL_MAX}(w: int w): void = "mac#anth_k_pin_self"
extern fun k_worker_index(arg: ptr): int = "mac#anth_k_worker_index"
extern fun k_yield(): void = "mac#anth_k_yield"
extern fun k_pause(): void = "mac#anth_k_pause"
extern fun k_sleep_us(us: lint): void = "mac#anth_k_sleep_us"
extern fun k_hw_open(config: int): int = "mac#anth_k_hw_open"
extern fun k_hw_enable(fd: int): void = "mac#anth_k_hw_enable"
extern fun k_hw_disable(fd: int): void = "mac#anth_k_hw_disable"
extern fun k_hw_read(fd: int): lint = "mac#anth_k_hw_read"
extern fun k_die(msg: string): void = "mac#anth_k_die"
extern fun k_run_wrap(context: ptr, job: ptr): ptr = "mac#anth_k_run_wrap"
extern fun k_run_search(context: ptr, job: ptr): ptr = "mac#anth_k_run_search"
extern fun k_context_open(): ptr = "mac#anth_k_context_open"
extern fun k_clock_ns(): lint = "mac#anth_k_clock_ns"
extern fun k_getenv(name: string): Stropt0 = "mac#getenv"

(* ---- small helpers ---- *)
fun imax_1(i: int): int = if i > 0 then i else 1
fun int_ge(a: int, b: int): bool = a >= b
fun int_gt(a: int, b: int): bool = a > b
fun lint_of(i: int): lint = g0int2int_int_lint(i)
fun int_of(x: lint): int = g0int2int_lint_int(x)
fun uint_of(i: int): uint = g0int2uint_int_uint(i)
fun ring_index(x: uint): natLt(RING_SLOTS) = let
  val v = g1ofg0(g0uint2int_uint_int(g0uint_land_uint(x, uint_of(RING_SLOTS - 1))))
in if v >= 0 then (if v < RING_SLOTS then v else 0) else 0 end
fun ring_room(tail: uint, head: uint): bool = g0uint_sub_uint(tail, head) < uint_of(RING_SLOTS)
fun clamp_wid(i: int): wid = let val i = g1ofg0(i) in
  if i >= 0 then (if i < POOL_MAX then i else 0) else 0 end
fun result_ring(kind: int): rid = if kind = WORKER_JOB_SEARCH then 2 else 1
fun reg_int{i:nat | i < REGS}(i: int i): int = int_of(k_reg(i))
fun set_reg_int{i:nat | i < REGS}(i: int i, v: int): void = k_set_reg(i, lint_of(v))
fun reg_bump{i:nat | i < REGS}(i: int i, d: int): void = k_set_reg(i, k_reg(i) + lint_of(d))
fun pool_count(): natLte(POOL_MAX) = let val n = g1ofg0(reg_int(REG_COUNT)) in
  if n >= 0 then (if n <= POOL_MAX then n else POOL_MAX) else 0 end
fun pool_slots(): natLte(POOL_MAX) = let val n = g1ofg0(reg_int(REG_SLOTS)) in
  if n >= 0 then (if n <= POOL_MAX then n else POOL_MAX) else 0 end
(* Unboxed results: ~1 is "none", any other value is in range. *)
typedef maybe_wid = [i:int | i >= ~1; i < POOL_MAX] int i
typedef maybe_cpu = [i:int | i >= ~1; i < MAX_CPUS] int i
typedef maybe_len = [i:int | i >= ~1; i <= TEXT_BYTES] int i
typedef maybe_chunk = [i:int | i >= ~1; i < SEARCH_CHUNKS] int i
(* A worker index the main thread may address: below the started count. *)
fun started_worker(i: int): maybe_wid = let val i = g1ofg0(i) val n = pool_count() in
  if i >= 0 then (if i < n then i else ~1) else ~1 end
fun wstat_add{f:nat | f < WSTATS}(w: wid, f: int f, v: lint): void = k_wstat_store(w, f, k_wstat(w, f) + v)
fun env_first(name: string): int = let val v = k_getenv(name) in
  if stropt_is_some(v) then let val s = stropt_unsome(v) in
    if string_isnot_empty(s) then char2int0(string_head(s)) else 0 end
  else 0 end
fun env_is(name: string, c: char): bool = env_first(name) = char2int0(c)

(* ---- rings ---- *)
fun ring_push{r:nat | r < RINGS}(w: wid, r: int r, kind: int, payload: ptr): bool = let
  val tail = k_tail_relaxed(w, r)
  val room = ring_room(tail, k_head_cache(w, r)) orelse let
    val () = k_set_head_cache(w, r, k_head_acquire(w, r)) in ring_room(tail, k_head_cache(w, r)) end
in if room then let
    val s = ring_index(tail)
    val () = k_set_slot_kind(w, r, s, kind) val () = k_set_slot_payload(w, r, s, payload)
  in let val () = k_tail_release(w, r, g0uint_add_uint(tail, uint_of(1))) in true end end
  else false end

(* Claims the oldest job; owner and thieves race only on `head`. The slot is
   read before the CAS: if the CAS wins, nobody can have overwritten it,
   because the producer never reuses a slot until `head` has passed it. *)
fun job_claim_at(v: wid, head: uint): @(bool, int, ptr) = let val tail = k_tail_acquire(v, RING_JOBS) in
  if head = tail then @(false, 0, the_null_ptr) else let
    val s = ring_index(head)
    val kind = k_slot_kind(v, RING_JOBS, s) val payload = k_slot_payload(v, RING_JOBS, s)
  in if k_head_cas(v, RING_JOBS, head, g0uint_add_uint(head, uint_of(1))) then @(true, kind, payload)
     else job_claim_at(v, k_head_acquire(v, RING_JOBS)) end end
fun job_claim(v: wid): @(bool, int, ptr) = job_claim_at(v, k_head_acquire(v, RING_JOBS))
fun job_empty(v: wid): bool = k_head_acquire(v, RING_JOBS) = k_tail_acquire(v, RING_JOBS)

(* ---- worker side ---- *)
fun steal_from{k,n:nat | k <= n; n <= POOL_MAX} .<n-k>. (w: wid, k: int k, n: int n): @(bool, int, ptr) =
  if k < n then let
    val v = clamp_wid((g0ofg1(w + k) mod g0ofg1(n)))
  in if job_empty(v) then steal_from(w, k + 1, n) else let val c = job_claim(v) in
       if c.0 then c else steal_from(w, k + 1, n) end end
  else @(false, 0, the_null_ptr)

(* (claimed, kind, payload, stolen) *)
fun claim_any(w: wid): @(bool, int, ptr, bool) = let val own = job_claim(w) in
  if own.0 then @(true, own.1, own.2, false) else let val n = pool_slots() in
    if n >= 1 then let val c = steal_from(w, 1, n) in @(c.0, c.1, c.2, c.0) end
    else @(false, 0, the_null_ptr, false) end end

fun anything_queued_from{k,n:nat | k <= n; n <= POOL_MAX} .<n-k>. (w: wid, k: int k, n: int n): bool =
  if k < n then (if job_empty(clamp_wid((g0ofg1(w + k) mod g0ofg1(n)))) then anything_queued_from(w, k + 1, n) else true)
  else false

fun hw_each{i:nat | i <= 3} .<3-i>. (w: wid, i: int i, on: bool): void =
  if i < 3 then let val fd = k_hw_fd(w, i)
    val () = if fd >= 0 then (if on then k_hw_enable(fd) else k_hw_disable(fd)) else ()
  in hw_each(w, i + 1, on) end else ()
fun hw_publish{i:nat | i <= 3} .<3-i>. (w: wid, i: int i): void =
  if i < 3 then let val fd = k_hw_fd(w, i)
    val () = if fd >= 0 then k_wstat_store(w, STAT_HW + i, k_hw_read(fd)) else ()
  in hw_publish(w, i + 1) end else ()
fun hw_config(i: natLt(3)): int = if i = 0 then HW_CYCLES else if i = 1 then HW_INSTRUCTIONS else HW_CACHE_MISSES
fun hw_open{i:nat | i <= 3} .<3-i>. (w: wid, i: int i, enabled: bool): void =
  if i < 3 then let val () = k_set_hw_fd(w, i, if enabled then k_hw_open(hw_config(i)) else ~1)
  in hw_open(w, i + 1, enabled) end else ()

(* ANTHRACITE_THREAD_JITTER=1 (tests): random short delays before jobs so
   completion order varies run to run and ordering bugs cannot hide. *)
fun jitter(w: wid): void = if reg_int(REG_JITTER) = 0 then () else let
  val x = (k_clock_ns() mod 1000003L) + lint_of(w * 7919)
  val y = ((x * 1103515245L + 12345L) mod 2147483647L)
  val pick = (y mod 3L)
in if pick = 0L then k_yield() else if pick = 1L then k_sleep_us(y mod 400L) else () end

(* The main thread drains results every frame; a full ring only waits. *)
fun push_result{r:nat | r < RINGS}(w: wid, r: int r, kind: int, result: ptr): void =
  if ring_push(w, r, kind, result) then () else let val () = k_yield() in push_result(w, r, kind, result) end

fun run_one(w: wid, kind: int, payload: ptr, stolen: bool): void = let
  val () = jitter(w)
  val t0 = k_clock_ns()
  val () = hw_each(w, 0, true)
  val result = if kind = WORKER_JOB_SEARCH then k_run_search(k_context(w), payload) else k_run_wrap(k_context(w), payload)
  val () = hw_each(w, 0, false)
  val () = hw_publish(w, 0)
  val () = push_result(w, result_ring(kind), kind, result)
  val () = wstat_add(w, STAT_BUSY_NS, k_clock_ns() - t0)
  val () = wstat_add(w, STAT_JOBS, 1L)
in if stolen then wstat_add(w, STAT_STEALS, 1L) else () end

fun spin_found{n:nat} .<n>. (w: wid, n: int n): bool =
  if n = 0 then false else let val () = k_pause() in
    if anything_queued_from(w, 0, pool_slots()) then true else spin_found(w, n - 1) end

(* Dekker with the producer: it bumps `wake` (seq_cst) after publishing a job,
   then reads `sleeping`; we set `sleeping`, then re-read `wake`. Either we see
   the bump and stay awake, or it sees us asleep and wakes us (futex_wait also
   returns at once if `wake` already moved past `seen`). *)
fun sleep_once(w: wid): void = let val seen = k_wake_load(w) in
  if job_empty(w) then let
    val () = k_sleeping_store(w, uint_of(1))
    val () = if k_wake_load(w) = seen then let val () = wstat_add(w, STAT_SLEEPS, 1L) in k_futex_wait(w, seen) end else ()
  in k_sleeping_store(w, uint_of(0)) end
  else () end

fun worker_loop(w: wid): void = let val c = claim_any(w) in
  if c.0 then let val () = run_one(w, c.1, c.2, c.3) in worker_loop(w) end
  else if spin_found(w, SPIN_ROUNDS) then worker_loop(w)
  else let val () = sleep_once(w) in worker_loop(w) end end

implement worker_main(arg) = let
  val w = clamp_wid(k_worker_index(arg))
  val () = if k_core(w) >= 0 then k_pin_self(w) else ()
  val () = hw_open(w, 0, reg_int(REG_COUNTERS) <> 0)
  val () = k_set_context(w, k_context_open())
  val () = worker_loop(w)
in the_null_ptr end

(* ---- paths and reads (main thread, before or outside the workers) ---- *)
fun path_add{o:nat | o < PATH_BYTES}(off: int o, s: string): natLt(PATH_BYTES) = let
  val s1 = g1ofg0(s) val n = sz2i(string1_length(s1))
in if off + n < PATH_BYTES then let val () = k_path_put(off, s1) in off + n end else off end
fun path_digit{o:nat | o < PATH_BYTES}(off: int o, d: int): natLt(PATH_BYTES) =
  if off + 1 < PATH_BYTES then let val () = k_set_path_byte(off, 48 + d) in off + 1 end else off
fun path_add_int{o:nat | o < PATH_BYTES}(off: int o, n: int): natLt(PATH_BYTES) =
  if n >= 10 then let val o2 = path_add_int(off, n / 10) in path_digit(o2, n mod 10) end
  else path_digit(off, if n >= 0 then n else 0)
fun path_finish{o:nat | o < PATH_BYTES}(off: int o): void = k_set_path_byte(off, 0)
fun cpu_path(c: cpu, leaf: string): void = let
  val o = path_add(0, "/sys/devices/system/cpu/cpu")
  val o = path_add_int(o, c)
  val o = path_add(o, "/")
in path_finish(path_add(o, leaf)) end

fun read_loop{n:nat | n <= TEXT_BYTES} .<TEXT_BYTES-n>. (fd: int, n: int n): natLte(TEXT_BYTES) =
  if n < TEXT_BYTES then let val got = g1ofg0(k_read_text(fd, n, TEXT_BYTES - n)) in
    if got > 0 then (if got <= TEXT_BYTES - n then read_loop(fd, n + got) else n) else n end
  else n
(* Reads the file named by the path buffer into the text buffer: the byte
   count, or None for a file that cannot be opened (the error stays here). *)
fun read_path(): maybe_len = let val fd = k_open_path() in
  if fd < 0 then ~1 else let val n = read_loop(fd, 0) val () = k_close(fd) in n end end

fun text_at{n:nat | n <= TEXT_BYTES}(len: int n, i: int): int = let val i = g1ofg0(i) in
  if i >= 0 then (if i < len then k_text(i) else 0) else 0 end
fun is_digit(c: int): bool = c >= 48 andalso c <= 57
(* (value, next index): decimal digits from i (none: value 0, next = i). *)
fun parse_digits{n:nat | n <= TEXT_BYTES}{k:nat} .<k>. (len: int n, i: int, left: int k, acc: lint): @(lint, int) =
  if left = 0 then @(acc, i) else let val c = text_at(len, i) in
    if is_digit(c) then parse_digits(len, i + 1, left - 1, acc * 10L + lint_of(c - 48)) else @(acc, i) end
fun parse_number{n:nat | n <= TEXT_BYTES}(len: int n, i: int): @(lint, int) = parse_digits(len, i, 18, 0L)
fun skip_spaces{n:nat | n <= TEXT_BYTES}{k:nat} .<k>. (len: int n, i: int, left: int k): int =
  if left = 0 then i else if text_at(len, i) = 32 then skip_spaces(len, i + 1, left - 1) else i

(* ---- CPU sets ---- *)
fun cpu_word(c: cpu): natLt(CPU_WORDS) = let val q = g1ofg0(g0ofg1(c) / 64) in
  if q >= 0 then (if q < CPU_WORDS then q else 0) else 0 end
fun cpu_bit(c: cpu): ullint = g0uint_lsl_ullint(g0int2uint_int_ullint(1), c - (c / 64) * 64)
fun set_clear{i:nat | i <= CPU_WORDS} .<CPU_WORDS-i>. (s: setid, i: int i): void =
  if i < CPU_WORDS then let val () = k_set_set_word(s, i, g0int2uint_int_ullint(0)) in set_clear(s, i + 1) end else ()
fun set_add(s: setid, c: cpu): void = let val i = cpu_word(c) in
  k_set_set_word(s, i, g0uint_lor_ullint(k_set_word(s, i), cpu_bit(c))) end
fun set_has(s: setid, c: int): bool = let val c = g1ofg0(c) in
  if c >= 0 then (if c < MAX_CPUS then g0uint_land_ullint(k_set_word(s, cpu_word(c)), cpu_bit(c)) <> g0int2uint_int_ullint(0)
    else false) else false end
fun set_count{c:nat | c <= MAX_CPUS} .<MAX_CPUS-c>. (s: setid, c: int c, acc: int): int =
  if c < MAX_CPUS then set_count(s, c + 1, if set_has(s, c) then acc + 1 else acc) else acc
fun set_first{c:nat | c <= MAX_CPUS} .<MAX_CPUS-c>. (s: setid, c: int c): int =
  if c < MAX_CPUS then (if set_has(s, c) then c else set_first(s, c + 1)) else ~1
fun set_copy{i:nat | i <= CPU_WORDS} .<CPU_WORDS-i>. (dst: setid, src: setid, i: int i): void =
  if i < CPU_WORDS then let val () = k_set_set_word(dst, i, k_set_word(src, i)) in set_copy(dst, src, i + 1) end else ()
fun set_and{i:nat | i <= CPU_WORDS} .<CPU_WORDS-i>. (dst: setid, src: setid, i: int i): void =
  if i < CPU_WORDS then let
    val () = k_set_set_word(dst, i, g0uint_land_ullint(k_set_word(dst, i), k_set_word(src, i))) in set_and(dst, src, i + 1) end
  else ()
fun set_or{i:nat | i <= CPU_WORDS} .<CPU_WORDS-i>. (dst: setid, src: setid, i: int i): void =
  if i < CPU_WORDS then let
    val () = k_set_set_word(dst, i, g0uint_lor_ullint(k_set_word(dst, i), k_set_word(src, i))) in set_or(dst, src, i + 1) end
  else ()
fun set_to_worker{i:nat | i <= CPU_WORDS} .<CPU_WORDS-i>. (w: wid, src: setid, i: int i): void =
  if i < CPU_WORDS then let val () = k_set_cpu_word(w, i, k_set_word(src, i)) in set_to_worker(w, src, i + 1) end else ()
fun worker_has_cpu(w: wid, c: cpu): bool =
  g0uint_land_ullint(k_cpu_word(w, cpu_word(c)), cpu_bit(c)) <> g0int2uint_int_ullint(0)
fun worker_first_cpu{c:nat | c <= MAX_CPUS} .<MAX_CPUS-c>. (w: wid, c: int c): int =
  if c < MAX_CPUS then (if worker_has_cpu(w, c) then c else worker_first_cpu(w, c + 1)) else ~1

fun clamp_cpu(v: lint): maybe_cpu = if v < 0L then ~1 else if v >= lint_of(MAX_CPUS) then ~1 else let
  val c = g1ofg0(int_of(v)) in if c >= 0 then (if c < MAX_CPUS then c else ~1) else ~1 end
fun add_range(s: setid, a: lint, b: lint): void = if a > b then () else let val c = clamp_cpu(a) in
  if c >= 0 then let val () = set_add(s, c) in add_range(s, a + 1L, b) end else () end
fun range_end{n:nat | n <= TEXT_BYTES}(len: int n, j: int, a: lint): @(lint, int) =
  if text_at(len, j) = 45 then parse_number(len, j + 1) else @(a, j)
(* "0-5,12-17\n" into set s; the list is bounded by the text length. *)
fun parse_list{n:nat | n <= TEXT_BYTES}{k:nat} .<k>. (s: setid, len: int n, i: int, left: int k): void =
  if left = 0 then () else if not(is_digit(text_at(len, i))) then () else let
    val @(a, j) = parse_number(len, i)
    val @(b, j) = range_end(len, j, a)
    val () = add_range(s, a, if b - a > 4096L then a + 4096L else b)
  in if text_at(len, j) = 44 then parse_list(s, len, j + 1, left - 1) else () end
fun read_cpu_list(s: setid): bool = let val () = set_clear(s, 0) val len = read_path() in
  if len >= 0 then let val () = parse_list(s, len, 0, len) in true end else false end
fun cpu_list(c: cpu, leaf: string, s: setid): bool = let val () = cpu_path(c, leaf) in read_cpu_list(s) end

(* ---- topology ---- *)
fun l2_size_bytes(c: cpu): lint = let val () = cpu_path(c, "cache/index2/size") val len = read_path() in
  if len < 0 then 0L else let val @(v, j) = parse_number(len, 0) val unit = text_at(len, j) in
    if unit = 75 orelse unit = 107 then v * 1024L else if unit = 77 orelse unit = 109 then v * 1048576L else v end end
(* Bytes of L2 per worker sharing it (Intel E-core clusters share one L2). *)
fun l2_share(c: cpu): int = let
  val sized = l2_size_bytes(c)
  val bytes: lint = if sized > 0L then sized else let val v = k_l2_bytes() in if v > 0L then v else lint_of(DEFAULT_L2_BYTES) end
  val sharers: int = if cpu_list(c, "cache/index2/shared_cpu_list", SET_TMP) then set_count(SET_TMP, 0, 0) else 1
  (* SMT siblings share the core's L2 but only one of them runs a worker. *)
  val threads: int = if cpu_list(c, "topology/thread_siblings_list", SET_TMP) then set_count(SET_TMP, 0, 0) else 1
  val on_l2: int = g0int_div_int(sharers, imax_1(threads))
  val share: lint = g0int_div_lint(bytes, lint_of(imax_1(on_l2)))
in int_of(if share < 1073741824L then share else 1073741824L) end

fun copy_cgroup{n:nat | n <= TEXT_BYTES}{o:nat | o < PATH_BYTES}{k:nat} .<k>.
  (len: int n, i: int, off: int o, left: int k): natLt(PATH_BYTES) =
  if left = 0 then off else let val c = text_at(len, i) in
    if c = 0 orelse c = 10 then off else if off + 1 < PATH_BYTES then let val () = k_set_path_byte(off, c) in
      copy_cgroup(len, i + 1, off + 1, left - 1) end else off end
(* CPUs the cgroup quota allows (cgroup v2 cpu.max "quota period"), or 0 = no limit. *)
fun cpu_quota(): int = let val qlen = read_path() in
  if qlen < 0 then 0 else if text_at(qlen, 0) = 109 then 0 else let
    val @(q, j) = parse_number(qlen, 0)
    val @(period, _) = parse_number(qlen, skip_spaces(qlen, j, 8))
  in if q > 0L andalso period > 0L then int_of((q + period - 1L) / period) else 0 end end
fun cgroup_cpus(): int = let val () = path_finish(path_add(0, "/proc/self/cgroup")) val len = read_path() in
  if len < 0 then 0
  else if text_at(len, 0) = 48 andalso text_at(len, 1) = 58 andalso text_at(len, 2) = 58 then let
    val o = path_add(0, "/sys/fs/cgroup")
    val o = copy_cgroup(len, 3, o, len)
    val () = path_finish(path_add(o, "/cpu.max"))
  in cpu_quota() end
  else 0 end

(* Physical cores in the affinity mask except the main thread's, cores in the
   main thread's L3 domain first; core n's CPUs go to worker n. *)
fun scan_cores{c:nat | c <= MAX_CPUS} .<MAX_CPUS-c>. (c: int c, pass: int, self: int, n: natLte(POOL_MAX)): natLte(POOL_MAX) =
  if c >= MAX_CPUS then n else if n >= POOL_MAX then n
  else if not(set_has(SET_ALLOWED, c)) orelse set_has(SET_SEEN, c) then scan_cores(c + 1, pass, self, n)
  else if (pass = 0) <> set_has(SET_MAIN_L3, c) then scan_cores(c + 1, pass, self, n)
  else let
    val () = if cpu_list(c, "topology/thread_siblings_list", SET_SIBLINGS) then () else let
      val () = set_clear(SET_SIBLINGS, 0) in set_add(SET_SIBLINGS, c) end
    val () = set_and(SET_SIBLINGS, SET_ALLOWED, 0)
    val () = set_or(SET_SEEN, SET_SIBLINGS, 0)
  in if set_has(SET_SIBLINGS, self) then scan_cores(c + 1, pass, self, n)
     else let val () = set_to_worker(n, SET_SIBLINGS, 0) in scan_cores(c + 1, pass, self, n + 1) end end

fun list_cores(): natLte(POOL_MAX) = let
  val () = set_clear(SET_ALLOWED, 0)
  val _ = k_getaffinity(SET_ALLOWED)
  val () = set_clear(SET_SEEN, 0)
  val got = k_getcpu()
  val self: int = if got >= 0 then got else set_first(SET_ALLOWED, 0)
  val c = clamp_cpu(lint_of(self))
  val () = if c >= 0 then (if cpu_list(c, "cache/index3/shared_cpu_list", SET_MAIN_L3) then ()
    else set_copy(SET_MAIN_L3, SET_ALLOWED, 0)) else set_copy(SET_MAIN_L3, SET_ALLOWED, 0)
  val n = scan_cores(0, 0, self, 0)
in scan_cores(0, 1, self, n) end

(* atoi: leading decimal integer of the value ("-1" is -1). *)
fun env_digits{n:nat}(s: string n, i: int, negative: bool, acc: int): int = let val i = g1ofg0(i) in
  if i >= 0 then (if i < sz2i(string1_length(s)) then let val c = char2int0(string_get_at(s, i2sz(i))) in
      if i = 0 andalso c = 45 then env_digits(s, 1, true, 0)
      else if is_digit(c) andalso acc < 100000 then env_digits(s, i + 1, negative, acc * 10 + (c - 48))
      else if negative then ~acc else acc end
    else if negative then ~acc else acc) else acc end
fun parse_env_int(name: string): int = let val v = k_getenv(name) in
  if stropt_is_some(v) then let val s = stropt_unsome(v) in env_digits(s, 0, false, 0) end else 0 end
fun env_present(name: string): bool = stropt_is_some(k_getenv(name))

fun setup_worker{i:nat | i <= POOL_MAX} .<POOL_MAX-i>. (i: int i, wanted: int, cores: int): void =
  if i < POOL_MAX then (if i < wanted then let
      (* More workers than free cores (forced by env): unassigned extras. *)
      val core: int = if i < cores then worker_first_cpu(i, 0) else ~1
      val () = if i < cores then () else let val () = set_clear(SET_TMP, 0) in set_to_worker(i, SET_TMP, 0) end
      val () = k_set_core(i, core)
      val c = clamp_cpu(lint_of(if int_ge(core, 0) then core else 0))
      val () = if c >= 0 then k_set_chunk(i, l2_share(c) / 2) else k_set_chunk(i, DEFAULT_L2_BYTES / 2)
      val () = k_set_context(i, the_null_ptr)
    in setup_worker(i + 1, wanted, cores) end else ())
  else ()

fun start_workers{i:nat | i <= POOL_MAX} .<POOL_MAX-i>. (i: int i, wanted: int): int =
  if i < POOL_MAX then (if i < wanted then
      (if k_thread_start(i) = 0 then let val () = k_thread_clock(i) in start_workers(i + 1, wanted) end else i)
    else i)
  else i

fun pool_start(): void = let
  val () = set_reg_int(REG_JITTER, if env_is("ANTHRACITE_THREAD_JITTER", '1') then 1 else 0)
  val () = set_reg_int(REG_COUNTERS, if env_is("ANTHRACITE_WORKER_COUNTERS", '1') then 1 else 0)
  val cores = list_cores()
  val quota = cgroup_cpus()
  val n: int = if quota > 0 andalso cores > quota - 1 then (if quota - 1 > 0 then quota - 1 else 0) else cores
  val wanted0: int = if env_present("ANTHRACITE_WORKERS") then parse_env_int("ANTHRACITE_WORKERS") else n
  val wanted: int = if int_gt(wanted0, POOL_MAX) then POOL_MAX else wanted0
  val tick = k_clk_tck()
  val () = k_set_reg(REG_TICK_NS, if tick > 0L then 1000000000L / tick else 10000000L)
in if int_gt(1, wanted) then () else let
    val () = set_reg_int(REG_SLOTS, wanted)
    val () = setup_worker(0, wanted, cores)
    (* The main thread is claimed before any worker can ask. *)
    val _ = thread_is_main()
  in set_reg_int(REG_COUNT, start_workers(0, wanted)) end end

fun await_pool(): void = if k_pool_state() = 2 then () else let val () = k_yield() in await_pool() end
implement workers_ensure() =
  if k_pool_state() = 2 then pool_count()
  else if k_pool_claim() then let val () = pool_start() val () = k_pool_ready() in pool_count() end
  else let val () = await_pool() in pool_count() end
implement workers_count() = pool_count()

(* ---- availability (main thread) ---- *)
fun clear_sample{c:nat | c <= MAX_CPUS} .<MAX_CPUS-c>. (c: int c): void =
  if c < MAX_CPUS then let val () = k_set_cpu_busy(SAMPLE_NOW, c, 0L) val () = k_set_cpu_total(SAMPLE_NOW, c, 0L)
  in clear_sample(c + 1) end else ()
fun keep_sample{c:nat | c <= MAX_CPUS} .<MAX_CPUS-c>. (c: int c): void =
  if c < MAX_CPUS then let
    val () = k_set_cpu_busy(SAMPLE_PREV, c, k_cpu_busy(SAMPLE_NOW, c))
    val () = k_set_cpu_total(SAMPLE_PREV, c, k_cpu_total(SAMPLE_NOW, c))
  in keep_sample(c + 1) end else ()
(* Eight tick fields after "cpuN": user nice system idle iowait irq softirq steal. *)
fun parse_ticks{n:nat | n <= TEXT_BYTES}{k:nat} .<k>. (len: int n, i: int, left: int k, busy: lint, total: lint, field: int): @(int, lint, lint, int) =
  if left = 0 then @(field, busy, total, i) else let
    val j = skip_spaces(len, i, 64)
  in if not(is_digit(text_at(len, j))) then @(field, busy, total, j) else let
      val @(v, next) = parse_number(len, j)
      val counted = field <> 3 andalso field <> 4
    in parse_ticks(len, next, left - 1, if counted then busy + v else busy, total + v, field + 1) end end
fun skip_line{n:nat | n <= TEXT_BYTES}{k:nat} .<k>. (len: int n, i: int, left: int k): int =
  if left = 0 then i else if i >= len then i else if text_at(len, i) = 10 then i + 1 else skip_line(len, i + 1, left - 1)
fun parse_stat{n:nat | n <= TEXT_BYTES}{k:nat} .<k>. (len: int n, i: int, left: int k): void =
  if left = 0 then () else if i >= len then () else let
    val is_cpu = text_at(len, i) = 99 andalso text_at(len, i + 1) = 112 andalso text_at(len, i + 2) = 117
      andalso is_digit(text_at(len, i + 3))
    val () = if is_cpu then let
        val @(id, j) = parse_number(len, i + 3)
        val @(fields, busy, total, _) = parse_ticks(len, j, 8, 0L, 0L, 0)
        val c = clamp_cpu(id)
      in if fields = 8 then (if c >= 0 then let val () = k_set_cpu_busy(SAMPLE_NOW, c, busy) in
          k_set_cpu_total(SAMPLE_NOW, c, total) end else ()) else () end
      else ()
  in parse_stat(len, skip_line(len, i, len), left - 1) end
fun read_proc_stat(): bool = let val () = clear_sample(0) val () = path_finish(path_add(0, "/proc/stat")) val len = read_path() in
  if len >= 0 then let val () = parse_stat(len, 0, len) in true end else false end

fun core_ticks{c:nat | c <= MAX_CPUS} .<MAX_CPUS-c>. (w: wid, c: int c, busy: lint, span: lint): @(lint, lint) =
  if c < MAX_CPUS then (if worker_has_cpu(w, c) then core_ticks(w, c + 1,
      busy + (k_cpu_busy(SAMPLE_NOW, c) - k_cpu_busy(SAMPLE_PREV, c)),
      span + (k_cpu_total(SAMPLE_NOW, c) - k_cpu_total(SAMPLE_PREV, c)))
    else core_ticks(w, c + 1, busy, span))
  else @(busy, span)
fun measure_core(w: wid, measured: bool): @(lint, lint) = if measured then core_ticks(w, 0, 0L, 0L) else @(0L, 0L)
(* A core is free for us when other programs used less than half of it since
   the last sample; our own worker's time on that core does not count. *)
fun judge_workers{i:nat | i <= POOL_MAX} .<POOL_MAX-i>. (i: int i, n: natLte(POOL_MAX), ok: bool, sampled: lint, active: int): int =
  if i < n then let
    val mine = k_thread_cpu_ns(i)
    val tick = k_reg(REG_TICK_NS)
    val measured = ok andalso sampled <> 0L andalso k_core(i) >= 0
    val @(busy, span) = measure_core(i, measured)
    val foreign = busy * tick - (mine - k_cpu_ns_seen(i))
    val free = span <= 0L orelse foreign * 2L < span * tick
    val () = k_set_active(i, if free then 1 else 0)
    val () = k_set_cpu_ns_seen(i, mine)
  in judge_workers(i + 1, n, ok, sampled, if free then active + 1 else active) end
  else active
fun refresh_load(): void = let
  val now = k_clock_ns()
  val sampled = k_reg(REG_LOAD_SAMPLED_AT)
in if sampled <> 0L andalso now - sampled < LOAD_SAMPLE_NS then () else let
    val ok = read_proc_stat()
    val n = pool_count()
    val active = judge_workers(0, n, ok, sampled, 0)
    val active: int = if active = 0 andalso n > 0 then let val () = k_set_active(0, 1) in 1 end else active
    val () = set_reg_int(REG_ACTIVE_COUNT, active)
    val () = keep_sample(0)
  in k_set_reg(REG_LOAD_SAMPLED_AT, now) end end

implement workers_active() = if workers_ensure() = 0 then 0 else let val () = refresh_load() in reg_int(REG_ACTIVE_COUNT) end
implement workers_is_active(worker) = let val w = started_worker(worker) in
  if w >= 0 then let val () = refresh_load() in k_active(w) <> 0 end else false end

fun min_chunk{i:nat | i <= POOL_MAX} .<POOL_MAX-i>. (i: int i, n: natLte(POOL_MAX), best: int): int =
  if i < n then let val c = k_chunk(i) in min_chunk(i + 1, n, if c > 0 andalso c < best then c else best) end else best
implement workers_chunk_bytes() = min_chunk(0, pool_count(), DEFAULT_L2_BYTES / 2)

(* ---- main-thread submit / take ---- *)
implement workers_has_room(worker) = let val w = started_worker(worker) in
  if w < 0 then false else let val tail = k_tail_relaxed(w, RING_JOBS) in
    if ring_room(tail, k_head_cache(w, RING_JOBS)) then true else let
      val () = k_set_head_cache(w, RING_JOBS, k_head_acquire(w, RING_JOBS)) in ring_room(tail, k_head_cache(w, RING_JOBS)) end end end

implement workers_queued(worker) = let val w = started_worker(worker) in
  if w < 0 then 0 else g0uint2int_uint_int(g0uint_sub_uint(k_tail_relaxed(w, RING_JOBS), k_head_acquire(w, RING_JOBS))) end

fun valid_kind(kind: int): bool = kind = WORKER_JOB_WRAP orelse kind = WORKER_JOB_SEARCH

implement workers_submit(worker, kind, job) = let val w = started_worker(worker) in
  if w < 0 then k_die("submit target")
  else if not(valid_kind(kind)) then k_die("submit kind")
  else if not(ring_push(w, RING_JOBS, kind, job)) then k_die("submit without room")
  else let val () = k_wake_bump(w) in if k_sleeping_load(w) <> uint_of(0) then k_futex_wake(w) else () end end

implement workers_has_result(worker, kind) = let val w = started_worker(worker) in
  if w < 0 then false else if not(valid_kind(kind)) then false else let
    val r = result_ring(kind) val head = k_head_relaxed(w, r)
  in if head <> k_tail_cache(w, r) then true else let
      val () = k_set_tail_cache(w, r, k_tail_acquire(w, r)) in head <> k_tail_cache(w, r) end end end

implement workers_take(worker, kind) = let val w = started_worker(worker) in
  if w < 0 then let val () = k_die("take target") in the_null_ptr end
  else if not(valid_kind(kind)) then let val () = k_die("take kind") in the_null_ptr end
  else if not(workers_has_result(w, kind)) then let val () = k_die("take without result") in the_null_ptr end
  else let
    val r = result_ring(kind) val head = k_head_relaxed(w, r)
    val payload = k_slot_payload(w, r, ring_index(head))
    val () = k_head_release(w, r, g0uint_add_uint(head, uint_of(1)))
  in payload end end

(* Sums over the pool, for tests and benchmarks. *)
fun total_field(field: int): natLt(WSTATS) =
  if field = WORKER_TOTAL_JOBS then STAT_JOBS else if field = WORKER_TOTAL_STEALS then STAT_STEALS
  else if field = WORKER_TOTAL_BUSY_NS then STAT_BUSY_NS else if field = WORKER_TOTAL_CYCLES then STAT_HW
  else if field = WORKER_TOTAL_INSTRUCTIONS then STAT_HW + 1 else STAT_HW + 2
fun sum_field{i:nat | i <= POOL_MAX}{f:nat | f < WSTATS} .<POOL_MAX-i>. (i: int i, n: natLte(POOL_MAX), f: int f, acc: lint): lint =
  if i < n then sum_field(i + 1, n, f, acc + k_wstat(i, f)) else acc
implement workers_total(field) = g0int2int_lint_llint(sum_field(0, pool_count(), total_field(field), 0L))

implement visual_next_build() = k_visual_next_build()

(* ---- main-thread dispatch record for background line shaping ---- *)
implement wrap_plan(document, build, start) = let
  val fresh = not(k_wrap_document() = document) orelse reg_int(REG_WRAP_BUILD) <> build
  val () = if fresh then let
      val () = k_set_wrap_document(document) val () = set_reg_int(REG_WRAP_BUILD, build)
      val () = set_reg_int(REG_WRAP_START, start)
    in set_reg_int(REG_WRAP_CURSOR, 0) end else ()
in reg_int(REG_WRAP_CURSOR) end
implement wrap_set_cursor(cursor) = set_reg_int(REG_WRAP_CURSOR, cursor)
implement wrap_start() = reg_int(REG_WRAP_START)
fun pick{i:nat | i <= POOL_MAX} .<POOL_MAX-i>. (i: int i, n: natLte(POOL_MAX), cap: int, best: int, depth: int): int =
  if i < n then (if workers_is_active(i) andalso workers_has_room(i) then let val q = workers_queued(i) in
      if q < cap andalso (best < 0 orelse q < depth) then pick(i + 1, n, cap, i, q) else pick(i + 1, n, cap, best, depth) end
    else pick(i + 1, n, cap, best, depth))
  else best
implement wrap_pick_worker(cap) = pick(0, pool_count(), cap, ~1, 0)
implement workers_pick(cap) = wrap_pick_worker(cap)
implement wrap_sent(worker) = reg_bump(REG_WRAP_TOTAL, 1)
implement wrap_received(worker) = reg_bump(REG_WRAP_TOTAL, ~1)
implement wrap_outstanding() = reg_int(REG_WRAP_TOTAL)
implement wrap_disable() = set_reg_int(REG_WRAP_DISABLED, 1)
implement wrap_enabled() =
  reg_int(REG_WRAP_DISABLED) = 0 andalso not(env_is("ANTHRACITE_PARALLEL_WRAP", '0')) andalso workers_ensure() > 0

(* ---- main-thread plan for parallel literal search ----
   One search runs at a time. Its files are split into chunks (first file of
   each chunk); finished chunk results that arrive ahead of their turn are
   parked until every earlier chunk has been merged. *)
fun search_chunk_count(): natLte(SEARCH_CHUNKS) = let val n = g1ofg0(reg_int(REG_SEARCH_CHUNKS)) in
  if n >= 0 then (if n <= SEARCH_CHUNKS then n else SEARCH_CHUNKS) else 0 end
fun planned_chunk(chunk: int): maybe_chunk = let
  val c = g1ofg0(chunk) val n = search_chunk_count()
in if c >= 0 then (if c < n then c else ~1) else ~1 end
fun clear_parked{i:nat | i <= SEARCH_CHUNKS} .<SEARCH_CHUNKS-i>. (i: int i): void =
  if i < SEARCH_CHUNKS then let val () = k_set_parked(i, the_null_ptr) in clear_parked(i + 1) end else ()

implement search_begin(capacity) = let
  val () = reg_bump(REG_SEARCH_GENERATION, 1)
  val () = set_reg_int(REG_SEARCH_ACTIVE, 1)
  val () = set_reg_int(REG_SEARCH_CHUNKS, 0)
  val () = set_reg_int(REG_SEARCH_DISPATCHED, 0)
  val () = set_reg_int(REG_SEARCH_MERGED, 0)
  val () = set_reg_int(REG_SEARCH_CAPACITY, if capacity < 1 then 1 else if capacity > SEARCH_CHUNKS then SEARCH_CHUNKS else capacity)
  val () = clear_parked(0)
in reg_int(REG_SEARCH_GENERATION) end
implement search_plan_push(first_file) = let val n = search_chunk_count() in
  if n < reg_int(REG_SEARCH_CAPACITY) then (if n < SEARCH_CHUNKS then let
      val () = k_set_search_first(n, first_file) in set_reg_int(REG_SEARCH_CHUNKS, n + 1) end else ())
  else () end
implement search_plan_close(files) = k_set_search_first(search_chunk_count(), files)
implement search_generation() = reg_int(REG_SEARCH_GENERATION)
implement search_active() = reg_int(REG_SEARCH_ACTIVE) <> 0
implement search_finish() = set_reg_int(REG_SEARCH_ACTIVE, 0)
implement search_chunks() = search_chunk_count()
implement search_first(chunk) = let val c = g1ofg0(chunk) val n = search_chunk_count() in
  if c >= 0 then (if c <= n then k_search_first(c) else 0) else 0 end
implement search_dispatched() = reg_int(REG_SEARCH_DISPATCHED)
implement search_set_dispatched(n) = set_reg_int(REG_SEARCH_DISPATCHED, n)
implement search_merged() = reg_int(REG_SEARCH_MERGED)
implement search_set_merged(n) = set_reg_int(REG_SEARCH_MERGED, n)
implement search_has_parked(chunk) = let val c = planned_chunk(chunk) in
  if c >= 0 then ptr_isnot_null(k_parked(c)) else false end
implement search_park_raw(chunk, result) = let val c = planned_chunk(chunk) in
  if c < 0 then k_die("search park slot")
  else if ptr_isnot_null(k_parked(c)) then k_die("search park slot taken") else k_set_parked(c, result) end
implement search_unpark_raw(chunk) = let val c = planned_chunk(chunk) in
  if c < 0 then let val () = k_die("search unpark slot") in the_null_ptr end
  else let val p = k_parked(c) in
    if ptr_is_null(p) then let val () = k_die("search unpark empty slot") in the_null_ptr end
    else let val () = k_set_parked(c, the_null_ptr) in p end end end
implement search_sent() = reg_bump(REG_SEARCH_INFLIGHT, 1)
implement search_got() = reg_bump(REG_SEARCH_INFLIGHT, ~1)
implement search_inflight() = reg_int(REG_SEARCH_INFLIGHT)
implement search_parallel_enabled() = not(env_is("ANTHRACITE_PARALLEL_SEARCH", '0')) andalso workers_ensure() > 0
