(* Arena allocator (see arena.sats), pure ATS2 over kernel.cats. Invariants:
   - A segment is 2 MB aligned; its header (first 64 KB page) names its kind,
     owner heap and page classes.
   - Only the owning thread touches a heap's free lists and bump offsets;
     other threads touch exactly its `remote` line.
   - Global state (reservation bump, commit lock, span cache) is touched only
     for a new 2 MB segment or a block above 32 KB.
   - Heap, class, segment, page and bucket indexes reaching a macro are static
     naturals below their table sizes; addresses read back from memory are
     validated (validate_small / seg_of) before they are trusted.
   No function here allocates: all values are flat. *)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "core_runtime/kernel/arena.sats"
%{^
#define ANTH_KERNEL_ARENA_IMPL 1
#include "core_runtime/kernel/kernel.cats"
ANTH_KERNEL_ARENA_ROOTS()
%}

#define HEAPS 128
#define NCLASS 40
#define PAGES 32
#define BUCKETS 64
#define CLASS_INDEX 2049
#define SEGS_MAX 32768
#define SEG_SIZE 2097152L
#define PAGE_SIZE 65536L
#define SMALL_MAX 32768L
#define CLASS_NONE 255
#define SEG_SMALL 1
#define SEG_LARGE 2
#define SEG_MAGIC 1095652424
#define INITIAL_COMMIT 104857600L
#define COMMIT_STEP 67108864L
#define DEFAULT_RESERVE 68719476736L
#define LOCK_COMMIT 0
#define LOCK_LARGE 1
#define LOCK_ABANDONED 2

typedef hid = natLt(HEAPS)
typedef cls = natLt(NCLASS)
typedef seg = natLt(SEGS_MAX)
typedef pg = natLt(PAGES)
typedef bucket = natLte(BUCKETS)
(* Unboxed results: ~1 is "none". *)
typedef maybe_hid = [i:int | i >= ~1; i < HEAPS] int i
typedef maybe_seg = [i:int | i >= ~1; i < SEGS_MAX] int i

extern fun k_seg_reset(s: seg): void = "mac#anth_k_seg_reset"
extern fun k_seg_magic(s: seg): int = "mac#anth_k_seg_magic"
extern fun k_seg_set_magic(s: seg, v: int): void = "mac#anth_k_seg_set_magic"
extern fun k_seg_kind(s: seg): int = "mac#anth_k_seg_kind"
extern fun k_seg_set_kind(s: seg, v: int): void = "mac#anth_k_seg_set_kind"
extern fun k_seg_owner(s: seg): int = "mac#anth_k_seg_owner"
extern fun k_seg_set_owner(s: seg, v: int): void = "mac#anth_k_seg_set_owner"
extern fun k_seg_next(s: seg): int = "mac#anth_k_seg_next"
extern fun k_seg_set_next(s: seg, v: int): void = "mac#anth_k_seg_set_next"
extern fun k_seg_span(s: seg): lint = "mac#anth_k_seg_span"
extern fun k_seg_set_span(s: seg, v: lint): void = "mac#anth_k_seg_set_span"
extern fun k_seg_usable(s: seg): lint = "mac#anth_k_seg_usable"
extern fun k_seg_set_usable(s: seg, v: lint): void = "mac#anth_k_seg_set_usable"
extern fun k_seg_class(s: seg, p: pg): int = "mac#anth_k_seg_class"
extern fun k_seg_set_class(s: seg, p: pg, c: int): void = "mac#anth_k_seg_set_class"
extern fun k_heap_free(h: hid, c: cls): ptr = "mac#anth_k_heap_free"
extern fun k_heap_set_free(h: hid, c: cls, p: ptr): void = "mac#anth_k_heap_set_free"
extern fun k_heap_bump(h: hid, c: cls): lint = "mac#anth_k_heap_bump"
extern fun k_heap_set_bump(h: hid, c: cls, v: lint): void = "mac#anth_k_heap_set_bump"
extern fun k_heap_bump_end(h: hid, c: cls): lint = "mac#anth_k_heap_bump_end"
extern fun k_heap_set_bump_end(h: hid, c: cls, v: lint): void = "mac#anth_k_heap_set_bump_end"
extern fun k_heap_segment(h: hid): int = "mac#anth_k_heap_segment"
extern fun k_heap_set_segment(h: hid, v: int): void = "mac#anth_k_heap_set_segment"
extern fun k_heap_next_page(h: hid): int = "mac#anth_k_heap_next_page"
extern fun k_heap_set_next_page(h: hid, v: int): void = "mac#anth_k_heap_set_next_page"
extern fun k_heap_set_index(h: hid, v: int): void = "mac#anth_k_heap_set_index"
extern fun k_heap_remote_frees(h: hid): lint = "mac#anth_k_heap_remote_frees"
extern fun k_heap_set_remote_frees(h: hid, v: lint): void = "mac#anth_k_heap_set_remote_frees"
extern fun k_heap_segments(h: hid): lint = "mac#anth_k_heap_segments"
extern fun k_heap_set_segments(h: hid, v: lint): void = "mac#anth_k_heap_set_segments"
extern fun k_heap_remote_take(h: hid): ptr = "mac#anth_k_heap_remote_take"
extern fun k_heap_remote_load(h: hid): ptr = "mac#anth_k_heap_remote_load"
extern fun k_heap_remote_cas(h: hid, seen: ptr, p: ptr): bool = "mac#anth_k_heap_remote_cas"
extern fun k_heap_owner_slot(h: hid): int = "mac#anth_k_heap_owner_slot"
extern fun k_heap_set_owner_slot(h: hid, v: int): void = "mac#anth_k_heap_set_owner_slot"
extern fun k_heap_address(h: hid): ptr = "mac#anth_k_heap_address"
extern fun k_heap_bytes(): lint = "mac#anth_k_heap_bytes"
extern fun k_block_next(p: ptr): ptr = "mac#anth_k_block_next"
extern fun k_block_set_next(p: ptr, q: ptr): void = "mac#anth_k_block_set_next"
extern fun k_ptr_off(p: ptr): lint = "mac#anth_k_ptr_off"
extern fun k_off_ptr(o: lint): ptr = "mac#anth_k_off_ptr"
extern fun k_class_size(c: cls): int = "mac#anth_k_class_size"
extern fun k_set_class_size(c: cls, v: int): void = "mac#anth_k_set_class_size"
extern fun k_class_of{i:nat | i < CLASS_INDEX}(i: int i): int = "mac#anth_k_class_of"
extern fun k_set_class_of{i:nat | i < CLASS_INDEX}(i: int i, v: int): void = "mac#anth_k_set_class_of"
extern fun k_large_free(b: bucket): int = "mac#anth_k_large_free"
extern fun k_set_large_free(b: bucket, s: int): void = "mac#anth_k_set_large_free"
extern fun k_abandoned(i: hid): int = "mac#anth_k_abandoned"
extern fun k_set_abandoned(i: hid, h: int): void = "mac#anth_k_set_abandoned"
extern fun k_abandoned_count(): int = "mac#anth_k_abandoned_count"
extern fun k_set_abandoned_count(n: int): void = "mac#anth_k_set_abandoned_count"
extern fun k_enabled(): int = "mac#anth_k_arena_enabled"
extern fun k_set_enabled(v: int): void = "mac#anth_k_arena_set_enabled"
extern fun k_reserve(): lint = "mac#anth_k_arena_reserve"
extern fun k_set_reserve(v: lint): void = "mac#anth_k_arena_set_reserve"
extern fun k_next_add(n: lint): lint = "mac#anth_k_arena_next_add"
extern fun k_committed_acquire(): lint = "mac#anth_k_committed_acquire"
extern fun k_committed_relaxed(): lint = "mac#anth_k_committed_relaxed"
extern fun k_committed_release(v: lint): void = "mac#anth_k_committed_release"
extern fun k_state(): int = "mac#anth_k_arena_state"
extern fun k_claim(): bool = "mac#anth_k_arena_claim"
extern fun k_ready(): void = "mac#anth_k_arena_ready"
extern fun k_heap_count_add(): int = "mac#anth_k_heap_count_add"
extern fun k_heap_count(): int = "mac#anth_k_heap_count"
extern fun k_libc_fallback_add(): void = "mac#anth_k_libc_fallback_add"
extern fun k_libc_fallback(): lint = "mac#anth_k_libc_fallback"
extern fun k_lock(i: natLt(3)): void = "mac#anth_k_lock"
extern fun k_unlock(i: natLt(3)): void = "mac#anth_k_unlock"
extern fun k_tls_heap(): int = "mac#anth_k_tls_heap"
extern fun k_tls_set_heap(v: int): void = "mac#anth_k_tls_set_heap"
extern fun k_tls_freed_slot(): int = "mac#anth_k_tls_freed_slot"
extern fun k_tls_set_freed_slot(v: int): void = "mac#anth_k_tls_set_freed_slot"
extern fun k_key_create(): void = "mac#anth_k_heap_key_create"
extern fun k_key_set(v: int): void = "mac#anth_k_heap_key_set"
extern fun k_key_value(p: ptr): int = "mac#anth_k_key_value"
extern fun k_phys_bytes(): lint = "mac#anth_k_phys_bytes"
extern fun k_map_reserve(n: lint): ptr = "mac#anth_k_map_reserve"
extern fun k_map_failed(p: ptr): bool = "mac#anth_k_map_failed"
extern fun k_unmap(p: ptr, n: lint): void = "mac#anth_k_unmap"
extern fun k_raw_off_aligned(p: ptr): lint = "mac#anth_k_raw_off_aligned"
extern fun k_set_base(p: ptr, off: lint): void = "mac#anth_k_set_base"
extern fun k_protect(off: lint, n: lint): int = "mac#anth_k_protect"
extern fun k_hugepage(off: lint, n: lint): void = "mac#anth_k_hugepage"
extern fun k_populate(n: lint): void = "mac#anth_k_populate"
extern fun k_populate_start(n: lint): void = "mac#anth_k_populate_start"
extern fun k_populate_bytes(p: ptr): lint = "mac#anth_k_populate_bytes"
extern fun k_libc_malloc(n: lint): ptr = "mac#anth_k_libc_malloc"
extern fun k_libc_realloc(p: ptr, n: lint): ptr = "mac#anth_k_libc_realloc"
extern fun k_libc_free(p: ptr): void = "mac#anth_k_libc_free"
extern fun k_zero(p: ptr, n: lint): void = "mac#anth_k_zero"
extern fun k_copy(d: ptr, s: ptr, n: lint): void = "mac#anth_k_copy"
extern fun k_size_lint(n: size_t): lint = "mac#anth_k_size_lint"
extern fun k_lint_size(n: lint): size_t = "mac#anth_k_lint_size"
extern fun k_size_max(): lint = "mac#anth_k_size_max"
extern fun k_die(msg: string): void = "mac#anth_k_arena_die"
extern fun k_getenv(name: string): Stropt0 = "mac#getenv"

fun lint_of(i: int): lint = g0int2int_int_lint(i)
fun int_of(x: lint): int = g0int2int_lint_int(x)
fun int_ge(a: int, b: int): bool = a >= b
fun lmin(a: lint, b: lint): lint = if a < b then a else b

fun clamp_hid(i: int): maybe_hid = let val i = g1ofg0(i) in
  if i >= 0 then (if i < HEAPS then i else ~1) else ~1 end
fun clamp_seg(i: int): maybe_seg = let val i = g1ofg0(i) in
  if i >= 0 then (if i < SEGS_MAX then i else ~1) else ~1 end
fun clamp_cls(i: int): cls = let val i = g1ofg0(i) in
  if i >= 0 then (if i < NCLASS then i else NCLASS - 1) else 0 end
fun clamp_page(i: int): pg = let val i = g1ofg0(i) in
  if i >= 0 then (if i < PAGES then i else 0) else 0 end
fun seg_offset(s: seg): lint = lint_of(s) * SEG_SIZE

(* ---- size classes: 16..128 step 16, then four per doubling up to 32 KB ---- *)
fun fill_linear{c:nat | c <= 8} .<8-c>. (c: int c): void =
  if c < 8 then let val () = k_set_class_size(c, (c + 1) * 16) in fill_linear(c + 1) end else ()
fun fill_doublings{c:nat | c <= NCLASS} .<NCLASS-c>. (c: int c, p: int): void =
  if c + 4 <= NCLASS then let
    val () = k_set_class_size(c, p + p / 4) val () = k_set_class_size(c + 1, p + p / 2)
    val () = k_set_class_size(c + 2, p + 3 * p / 4) val () = k_set_class_size(c + 3, p * 2)
  in fill_doublings(c + 4, p * 2) end else ()
fun smallest_fit{c:nat | c < NCLASS} .<NCLASS-c>. (c: int c, size: int): cls =
  if c < NCLASS - 1 then (if k_class_size(c) < size then smallest_fit(c + 1, size) else c) else c
fun fill_class_of{i:nat | i <= CLASS_INDEX} .<CLASS_INDEX-i>. (i: int i, c: cls): void =
  if i < CLASS_INDEX then let val c = smallest_fit(c, i * 16) val () = k_set_class_of(i, c) in fill_class_of(i + 1, c) end
  else ()
fun build_classes(): void = let val () = fill_linear(0) val () = fill_doublings(8, 128) in fill_class_of(0, 0) end
fun class_for(size: lint): cls = let val i = g1ofg0(int_of((size + 15L) / 16L)) in
  if i >= 0 then (if i < CLASS_INDEX then clamp_cls(k_class_of(i)) else NCLASS - 1) else 0 end

(* ---- reservation ---- *)
fun env_first(name: string): int = let val v = k_getenv(name) in
  if stropt_is_some(v) then let val s = stropt_unsome(v) in
    if string_isnot_empty(s) then char2int0(string_head(s)) else 0 end else 0 end
fun env_digits{n:nat}(s: string n, i: int, acc: lint): lint = let val i = g1ofg0(i) in
  if i >= 0 then (if i < sz2i(string1_length(s)) then let val c = char2int0(string_get_at(s, i2sz(i))) in
      if c >= 48 andalso c <= 57 andalso acc < 100000000000000L then env_digits(s, i + 1, acc * 10L + lint_of(c - 48)) else acc end
    else acc) else acc end
fun env_bytes(name: string): lint = let val v = k_getenv(name) in
  if stropt_is_some(v) then env_digits(stropt_unsome(v), 0, 0L) else 0L end

fun reserve_bytes(): lint = let
  val phys = k_phys_bytes()
  val base = lmin(if phys > 0L then phys / 4L else 2147483648L, DEFAULT_RESERVE)
  val asked = env_bytes("ANTHRACITE_ARENA_MAX")
  val chosen = if asked >= INITIAL_COMMIT then lmin(asked, DEFAULT_RESERVE) else base
in chosen - (chosen mod SEG_SIZE) end

fun arena_init(): void = let
  val () = build_classes()
  val () = k_key_create()
in if env_first("ANTHRACITE_ARENA") = 48 then () else let val reserve = reserve_bytes() in
  if reserve < INITIAL_COMMIT then () else let
    (* Over-reserve one segment so the base can be 2 MB aligned. *)
    val raw = k_map_reserve(reserve + SEG_SIZE)
  in if k_map_failed(raw) then () else let
      val () = k_set_base(raw, k_raw_off_aligned(raw))
    in if k_protect(0L, INITIAL_COMMIT) <> 0 then k_unmap(raw, reserve + SEG_SIZE) else let
        val () = k_hugepage(0L, INITIAL_COMMIT)
        val () = k_set_reserve(reserve)
        val () = k_committed_release(INITIAL_COMMIT)
        val () = k_set_enabled(1)
      (* Prefault without blocking startup; MADV_POPULATE_WRITE keeps contents. *)
      in if env_first("ANTHRACITE_ARENA_NO_PREFAULT") <> 0 then () else k_populate_start(INITIAL_COMMIT) end end end end end

implement arena_populate(bytes) = let val () = k_populate(k_populate_bytes(bytes)) in the_null_ptr end

fun await_init(): void = if k_state() = 2 then () else await_init()
implement arena_start_init() = if k_claim() then let val () = arena_init() in k_ready() end else await_init()
fun ensure_init(): void = if k_state() = 2 then () else arena_start_init()

fun enabled(): bool = k_enabled() <> 0
(* The reservation size stays 0 unless the arena came up, so this is false while it is off. *)
fun in_arena(p: ptr): bool = let val off = k_ptr_off(p) in off >= 0L andalso off < k_reserve() end
(* The segment holding arena offset `off`, or ~1 outside the reservation. *)
fun seg_of(off: lint): maybe_seg = if off < 0L then ~1 else if off >= k_reserve() then ~1 else clamp_seg(int_of(off / SEG_SIZE))
fun page_of(off: lint): pg = clamp_page(int_of((off mod SEG_SIZE) / PAGE_SIZE))

(* ---- commit ---- *)
fun commit_steps{k:nat} .<k>. (done: lint, target: lint, left: int k): @(lint, bool) =
  if done >= target then @(done, true) else if left = 0 then @(done, false) else let
    val step = lmin(COMMIT_STEP, k_reserve() - done)
  in if step <= 0L then @(done, false) else if k_protect(done, step) <> 0 then @(done, false)
     else let val () = k_hugepage(done, step) in commit_steps(done + step, target, left - 1) end end
fun commit_to(target: lint): bool =
  if k_committed_acquire() >= target then true else let
    val () = k_lock(LOCK_COMMIT)
    val @(done, ok) = commit_steps(k_committed_relaxed(), target, 2048)
    val () = k_committed_release(done)
    val () = k_unlock(LOCK_COMMIT)
  in ok end

(* ---- span cache (large blocks and fresh segments), under LOCK_LARGE ---- *)
(* Span-cache links are segment + 1, so the zeroed root table reads as empty. *)
fun list_seg(v: int): maybe_seg = if v = 0 then ~1 else let val s = clamp_seg(v - 1) in
  if s >= 0 then (if k_seg_magic(s) = SEG_MAGIC then s else let val () = k_die("cached span header") in ~1 end)
  else let val () = k_die("cached span link") in ~1 end end
(* (best, its predecessor) among spans of at least `want` bytes. *)
fun span_of(s: int): lint = let val s = clamp_seg(s) in if s >= 0 then k_seg_span(s) else 0L end
fun best_span{k:nat} .<k>. (cur: maybe_seg, prev: int, want: lint, best: int, best_prev: int, left: int k): @(int, int) =
  if left = 0 then @(best, best_prev) else if cur < 0 then @(best, best_prev) else let
    val span = k_seg_span(cur)
    val better = span >= want andalso (best < 0 orelse span < span_of(best))
  in best_span(list_seg(k_seg_next(cur)), cur, want, if better then g0ofg1(cur) else best, if better then prev else best_prev, left - 1) end
fun pop_span(b: bucket, want: lint): int = let
  val @(best, prev) = best_span(list_seg(k_large_free(b)), ~1, want, ~1, ~1, SEGS_MAX)
  val found = clamp_seg(best)
in if found < 0 then ~1 else let
    val rest = k_seg_next(found)
    val p = clamp_seg(prev)
    val () = if p >= 0 then k_seg_set_next(p, rest) else k_set_large_free(b, rest)
  in found end end
fun pop_bigger{b:nat | b <= BUCKETS + 1} .<BUCKETS+1-b>. (b: int b, want: lint): int =
  if b <= BUCKETS then let val s = pop_span(b, want) in if s >= 0 then s else pop_bigger(b + 1, want) end else ~1
fun exact_bucket(segments: lint): int = if segments <= lint_of(BUCKETS) then int_of(segments) else 0
fun as_bucket(i: int): bucket = let val i = g1ofg0(i) in if i >= 0 then (if i <= BUCKETS then i else 0) else 0 end

(* Reuse a cached span first: exact size, else (for large blocks) the
   smallest bigger one, keeping its full span so it returns to its own bucket
   later; otherwise bump the reservation. (segment, span bytes), segment ~1 on failure. *)
fun span_take(segments: lint, exact: bool): @(int, lint) = let
  val want = segments * SEG_SIZE
  val () = k_lock(LOCK_LARGE)
  val first = if segments <= lint_of(BUCKETS) then pop_span(as_bucket(exact_bucket(segments)), want) else ~1
  val more = if int_ge(first, 0) orelse exact then first
    else if segments < lint_of(BUCKETS) then pop_bigger(as_bucket(int_of(segments) + 1), want) else ~1
  val found = if int_ge(more, 0) orelse exact then more else pop_span(0, want)
  val () = k_unlock(LOCK_LARGE)
  val s = clamp_seg(found)
in if s >= 0 then @(s, k_seg_span(s)) else let val offset = k_next_add(want) in
    if offset + want > k_reserve() then @(~1, 0L)
    else if not(commit_to(offset + want)) then @(~1, 0L)
    else @(int_of(offset / SEG_SIZE), want) end end

fun large_release(s: seg): void = let
  val b = as_bucket(exact_bucket(k_seg_span(s) / SEG_SIZE))
  val () = k_lock(LOCK_LARGE)
  val () = k_seg_set_next(s, k_large_free(b))
  val () = k_set_large_free(b, s + 1)
in k_unlock(LOCK_LARGE) end

(* ---- heaps ---- *)
fun adopt_abandoned(): int = let
  val () = k_lock(LOCK_ABANDONED)
  val n = k_abandoned_count()
  val i = clamp_hid(n - 1)
  val h = if i >= 0 then let val () = k_set_abandoned_count(i) in k_abandoned(i) end else ~1
  val () = k_unlock(LOCK_ABANDONED)
in h end

(* A finished thread leaves its heap (free lists, segments, pending remote
   frees) to the next thread that starts. *)
implement arena_heap_abandon(value) = let val h = clamp_hid(k_key_value(value) - 1) in
  if h < 0 then () else let
    val () = k_lock(LOCK_ABANDONED)
    val n = clamp_hid(k_abandoned_count())
    val () = if n >= 0 then let val () = k_set_abandoned(n, h) in k_set_abandoned_count(n + 1) end else ()
  in k_unlock(LOCK_ABANDONED) end end

fun fresh_heap(): maybe_hid = let val fresh = clamp_hid(k_heap_count_add()) in
  if fresh >= 0 then let
    val () = k_heap_set_index(fresh, fresh) val () = k_heap_set_next_page(fresh, PAGES)
    val () = k_heap_set_segment(fresh, ~1)
  in fresh end else ~1 end
fun heap_source(adopted: maybe_hid): maybe_hid = if adopted >= 0 then adopted else fresh_heap()
fun heap_create(): maybe_hid = let
  val h = heap_source(clamp_hid(adopt_abandoned()))
  val () = if h >= 0 then k_key_set(h + 1) else ()
in h end

fun current_heap(): maybe_hid = clamp_hid(k_tls_heap() - 1)
implement arena_first_heap() = let val created = heap_create() val () = k_tls_set_heap(created + 1) in created end
fun heap(): maybe_hid = let val h = current_heap() in if h >= 0 then h else clamp_hid(arena_first_heap()) end

(* A small block's class, after checking that `p` lies in a small segment
   page with a class: anything else is a corrupted free list. *)
fun page_class(s: seg, off: lint): cls = let val c = k_seg_class(s, page_of(off)) in
  if c >= NCLASS then let val () = k_die("small block in an unclassed page") in 0 end else clamp_cls(c) end
fun validate_small(p: ptr): @(int, cls) = let val off = k_ptr_off(p) val s = seg_of(off) in
  if s < 0 then let val () = k_die("small block outside the arena") in @(~1, 0) end
  else if k_seg_kind(s) <> SEG_SMALL then let val () = k_die("small block in a non-small segment") in @(~1, 0) end
  else @(s, page_class(s, off)) end

fun push_free(h: hid, c: cls, p: ptr): void = let
  val () = k_block_set_next(p, k_heap_free(h, c)) in k_heap_set_free(h, c, p) end

fun drain_list(h: hid, p: ptr): void = if ptr_is_null(p) then () else let
  val next = k_block_next(p)
  val @(_, c) = validate_small(p)
  val () = push_free(h, c, p)
in drain_list(h, next) end
fun drain_remote(h: hid): void = drain_list(h, k_heap_remote_take(h))

fun pop_free(h: hid, c: cls): ptr = let val p = k_heap_free(h, c) in
  if ptr_is_null(p) then p else let
    val next = k_block_next(p)
    val () = if ptr_is_null(next) then () else if seg_of(k_ptr_off(next)) < 0 then k_die("free list link outside the arena") else ()
    val () = k_heap_set_free(h, c, next)
  in p end end

fun mark_pages{i:nat | i <= PAGES} .<PAGES-i>. (s: seg, i: int i): void =
  if i < PAGES then let val () = k_seg_set_class(s, i, CLASS_NONE) in mark_pages(s, i + 1) end else ()

fun fresh_segment(h: hid): bool = let val @(found, _) = span_take(1L, true) val s = clamp_seg(found) in
  if s < 0 then false else let
    val () = k_seg_reset(s) val () = k_seg_set_magic(s, SEG_MAGIC) val () = k_seg_set_kind(s, SEG_SMALL)
    val () = k_seg_set_owner(s, h) val () = k_seg_set_span(s, SEG_SIZE) val () = k_seg_set_next(s, 0)
    val () = mark_pages(s, 0)
    val () = k_heap_set_segment(h, s)
    val () = k_heap_set_next_page(h, 1) (* page 0 holds the header *)
    val () = k_heap_set_segments(h, k_heap_segments(h) + 1L)
  in true end end

fun new_page(h: hid, c: cls): bool =
  if k_heap_next_page(h) >= PAGES andalso not(fresh_segment(h)) then false else let
    val s = clamp_seg(k_heap_segment(h))
    val page = g1ofg0(k_heap_next_page(h))
  in if s < 0 then false else if page < 1 then false else if page >= PAGES then false else let
      val () = k_heap_set_next_page(h, page + 1)
      val () = k_seg_set_class(s, page, c)
      val start = seg_offset(s) + lint_of(page) * PAGE_SIZE
      val size = lint_of(k_class_size(c))
      val () = k_heap_set_bump(h, c, start)
    in let val () = k_heap_set_bump_end(h, c, start + (PAGE_SIZE / size) * size) in true end end end

fun bump_take(h: hid, c: cls): ptr = let val b = k_heap_bump(h, c) in
  if b < k_heap_bump_end(h, c) then let val () = k_heap_set_bump(h, c, b + lint_of(k_class_size(c))) in k_off_ptr(b) end
  else the_null_ptr end

fun small_alloc(h: hid, c: cls): ptr = let val p = pop_free(h, c) in
  if ptr_isnot_null(p) then p else let val p = bump_take(h, c) in
    if ptr_isnot_null(p) then p else let val () = drain_remote(h) val p = pop_free(h, c) in
      if ptr_isnot_null(p) then p else if new_page(h, c) then bump_take(h, c) else the_null_ptr end end end

fun large_alloc(h: maybe_hid, size: lint): ptr = let
  val segments = (PAGE_SIZE + size + SEG_SIZE - 1L) / SEG_SIZE
  val @(found, span) = span_take(segments, false)
  val s = clamp_seg(found)
in if s < 0 then the_null_ptr else let
    val () = k_seg_set_magic(s, SEG_MAGIC) val () = k_seg_set_kind(s, SEG_LARGE) val () = k_seg_set_owner(s, h)
    val () = k_seg_set_span(s, span) val () = k_seg_set_usable(s, span - PAGE_SIZE) val () = k_seg_set_next(s, 0)
    val () = if h >= 0 then k_heap_set_segments(h, k_heap_segments(h) + 1L) else ()
  in k_off_ptr(seg_offset(s) + PAGE_SIZE) end end

fun libc_fallback(size: lint): ptr = let val () = k_libc_fallback_add() in k_libc_malloc(if size > 0L then size else 1L) end

fun alloc_in(h: maybe_hid, size: lint): ptr =
  if size <= SMALL_MAX then (if h >= 0 then small_alloc(h, class_for(size)) else large_alloc(h, size)) else large_alloc(h, size)
fun alloc(size: lint): ptr = let val () = ensure_init() in
  if not(enabled()) then libc_fallback(size) else let
    val h = heap()
    val p = alloc_in(h, size)
  in if ptr_isnot_null(p) then p else libc_fallback(size) end end

fun usable(p: ptr): lint = if ptr_is_null(p) then 0L else if not(in_arena(p)) then 0L else let
  val off = k_ptr_off(p) val s = seg_of(off) in
  if s < 0 then 0L else if k_seg_kind(s) = SEG_LARGE then k_seg_usable(s)
  else let val @(_, c) = validate_small(p) in lint_of(k_class_size(c)) end end

fun remote_push(owner: hid, p: ptr): void = let val seen = k_heap_remote_load(owner) val () = k_block_set_next(p, seen) in
  if k_heap_remote_cas(owner, seen, p) then () else remote_push(owner, p) end

(* Statistics tag of a freed block for arena_freed_slot: the owner thread's
   slot + 1 when another thread owns the heap, else 0. *)
fun foreign_slot(owner: maybe_hid, self: maybe_hid): int =
  if owner < 0 then 0 else if owner = self then 0 else k_heap_owner_slot(owner)

fun release(p: ptr): void = if ptr_is_null(p) then k_tls_set_freed_slot(0)
  else if not(in_arena(p)) then let val () = k_tls_set_freed_slot(0) in k_libc_free(p) end else let
  val off = k_ptr_off(p) val s = seg_of(off) in
  if s < 0 then k_die("free outside the arena")
  else if k_seg_magic(s) <> SEG_MAGIC then k_die("free of a block without a segment header")
  else if k_seg_kind(s) = SEG_LARGE then let
    val () = k_tls_set_freed_slot(foreign_slot(clamp_hid(k_seg_owner(s)), current_heap()))
  in large_release(s) end
  else if k_seg_kind(s) <> SEG_SMALL then k_die("free of a block in a segment of unknown kind")
  else let
    val c = page_class(s, off)
    val owner = clamp_hid(k_seg_owner(s))
    val self = current_heap()
    val () = k_tls_set_freed_slot(foreign_slot(owner, self))
  in if owner < 0 then k_die("small segment without an owner heap")
     else if owner = self then push_free(owner, c, p)
     else let val () = remote_push(owner, p) in
       if self >= 0 then k_heap_set_remote_frees(self, k_heap_remote_frees(self) + 1L) else () end end end

fun resize(p: ptr, size: lint): ptr =
  if ptr_is_null(p) then alloc(size) else if not(in_arena(p)) then k_libc_realloc(p, size) else let
    val have = usable(p)
  in if size <= have andalso size > have / 2L then p else let val next = alloc(size) in
      if ptr_is_null(next) then next else let val () = k_copy(next, p, lmin(have, size)) val () = release(p) in next end end end

(* ---- exported API ---- *)
implement arena_malloc(size) = alloc(k_size_lint(size))
implement arena_calloc(count, size) = let val n = k_size_lint(count) val each = k_size_lint(size) in
  if each > 0L andalso n > k_size_max() / each then the_null_ptr else let val p = alloc(n * each) in
    if ptr_isnot_null(p) then let val () = k_zero(p, n * each) in p end else p end end
implement arena_realloc(p, size) = resize(p, k_size_lint(size))
implement arena_free(p) = release(p)
implement arena_usable(p) = k_lint_size(usable(p))
implement arena_hook_malloc(size) = arena_malloc(size)
implement arena_hook_calloc(count, size) = arena_calloc(count, size)
implement arena_hook_realloc(p, size) = arena_realloc(p, size)
implement arena_hook_free(p) = arena_free(p)

implement arena_set_owner_slot(slot) = let val () = ensure_init() val h = heap() in
  if h >= 0 then k_heap_set_owner_slot(h, slot) else () end
implement arena_freed_slot() = k_tls_freed_slot()

fun heap_sum{i:nat | i <= HEAPS} .<HEAPS-i>. (i: int i, n: int, remote: bool, acc: lint): lint =
  if i < HEAPS then (if i < n then heap_sum(i + 1, n, remote, acc + (if remote then k_heap_remote_frees(i) else k_heap_segments(i)))
    else acc) else acc
fun heaps_used(): int = let val n = k_heap_count() in if n > HEAPS then HEAPS else n end
implement arena_stat(field) = let val () = ensure_init() in
  if field = 0 then k_reserve() else if field = 1 then k_committed_acquire()
  else if field = 2 then heap_sum(0, heaps_used(), false, 0L) else if field = 3 then lint_of(heaps_used())
  else if field = 4 then heap_sum(0, heaps_used(), true, 0L) else if field = 5 then k_libc_fallback()
  else lint_of(k_enabled()) end
implement arena_heap_address(heap) = let val h = clamp_hid(heap) in if h >= 0 then k_heap_address(h) else the_null_ptr end
implement arena_heap_size() = k_heap_bytes()
