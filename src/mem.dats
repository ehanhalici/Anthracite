#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "mem.sats"
staload "airlock.sats"

extern fun c_memcpy(dst: ptr, src: ptr, n: size_t): void = "mac#memcpy"
extern fun c_memset(dst: ptr, src: int, n: size_t): void = "mac#memset"

extern fun mem_note_alloc(n: int): void = "mac#anth_mem_alloc"
extern fun mem_note_free(n: int): void = "mac#anth_mem_free"

(* The buffer owns an arrayptr: the byte view and the free-proof travel
   together. The static size n is shared by the arrayptr and the cap,
   so every index check below is discharged by the type checker. *)
datavtype Buf_ =
  | {l:addr}{n:nat} BUF of (arrayptr(byte, l, n), int(n), int)
(* skill.md 1. kural istisnasi: ATS2 soyut tip gerceklemesi (sats'taki absviewtype). Kanit disi cast veya ham C yoktur. *)
assume Buf = Buf_

(* ---- bounds-checked byte access ---- *)

fun byte_get{l:addr}{n:nat}(
  A: !arrayptr(byte, l, n), cap: int(n), i: int
) : int =
  if i >= 0 then
    (if i < cap then byte2int0(arrayptr_get_at(A, g1int2uint_int_size(airlock_below(i, cap)))) else 0)
  else 0

fun byte_put{l:addr}{n:nat}(
  A: !arrayptr(byte, l, n), cap: int(n), i: int, v: int
) : void =
  if i >= 0 then
    (if i < cap then arrayptr_set_at(A, g1int2uint_int_size(airlock_below(i, cap)), int2byte0(v)) else ())
  else ()

(* little-endian 32-bit word at byte offset 4*i (x86 native layout) *)

fun word_get_at{l:addr}{n:nat}{i:nat | 4*i+4 <= n}(
  A: !arrayptr(byte, l, n), i: int(i)
) : int = let
  val b0 = g0int2uint_int_uint(byte2int0(arrayptr_get_at(A, g1int2uint_int_size(4*i))))
  val b1 = g0int2uint_int_uint(byte2int0(arrayptr_get_at(A, g1int2uint_int_size(4*i+1))))
  val b2 = g0int2uint_int_uint(byte2int0(arrayptr_get_at(A, g1int2uint_int_size(4*i+2))))
  val b3 = g0int2uint_int_uint(byte2int0(arrayptr_get_at(A, g1int2uint_int_size(4*i+3))))
  val w = g0uint_lor(g0uint_lor(b0, g0uint_lsl(b1, 8)), g0uint_lor(g0uint_lsl(b2, 16), g0uint_lsl(b3, 24)))
in
  g0uint2int_uint_int(w)
end

fun word_put_at{l:addr}{n:nat}{i:nat | 4*i+4 <= n}(
  A: !arrayptr(byte, l, n), i: int(i), v: int
) : void = let
  val u = g0int2uint_int_uint(v)
  val () = arrayptr_set_at(A, g1int2uint_int_size(4*i), uint2byte0(u))
  val () = arrayptr_set_at(A, g1int2uint_int_size(4*i+1), uint2byte0(g0uint_lsr(u, 8)))
  val () = arrayptr_set_at(A, g1int2uint_int_size(4*i+2), uint2byte0(g0uint_lsr(u, 16)))
  val () = arrayptr_set_at(A, g1int2uint_int_size(4*i+3), uint2byte0(g0uint_lsr(u, 24)))
in
end

fun word_get{l:addr}{n:nat}(
  A: !arrayptr(byte, l, n), cap: int(n), i: int
) : int =
  if i >= 0 then
    (if 4*i+4 <= cap then word_get_at(A, airlock_word(i, cap)) else 0)
  else 0

fun word_put{l:addr}{n:nat}(
  A: !arrayptr(byte, l, n), cap: int(n), i: int, v: int
) : void =
  if i >= 0 then
    (if 4*i+4 <= cap then word_put_at(A, airlock_word(i, cap), v) else ())
  else ()

(* ---- construction / destruction ---- *)

fun make_pos{n:pos}(n: int(n)): Buf = let
  val (pf, pfgc | p) = malloc_gc(i2sz(n))
  val () = c_memset(p, 0, g1int2uint_int_size(n))
  val () = mem_note_alloc(n)
  val A = arrayptr_encode(b0ytes2bytes_v(pf), pfgc | p)
in
  BUF(A, n, 0)
end

fun resize_pos{n:pos}(b: &Buf >> _, n: int(n)): void = let
  val+~BUF(A, cap, len) = b
  val (pf, pfgc | p) = malloc_gc(i2sz(n))
  val () = c_memset(p, 0, g1int2uint_int_size(n))
  val ncopy: int = (if cap < n then cap else n): int
  val () = c_memcpy(p, arrayptr2ptr(A), g0int2uint_int_size(ncopy))
  val () = arrayptr_free(A)
  val () = mem_note_free(cap)
  val () = mem_note_alloc(n)
  val len2: int = (if len < n then len else n): int
  val A2 = arrayptr_encode(b0ytes2bytes_v(pf), pfgc | p)
in
  b := BUF(A2, n, len2)
end

(* ---- public API ---- *)

implement buf_make(n0) =
  if n0 >= 1 then make_pos(airlock_pos(n0)) else make_pos(1)

implement buf_free(b) = let
  val+~BUF(A, cap, len) = b
  val () = mem_note_free(cap)
in
  arrayptr_free(A)
end

implement buf_cap(b) =
  case+ b of
  | @BUF(A, cap, len) => let
      val c = cap
    in
      fold@(b); c
    end

implement buf_len(b) =
  case+ b of
  | @BUF(A, cap, len) => let
      val k = len
    in
      fold@(b); k
    end

implement seen_int(x) =
  if x >= 0 then () else ()

implement seen_uint(x) =
  seen_int(anth_u2i(x))

implement seen_buf(b) =
  seen_int(buf_len(b))

implement buf_set_len(b, n) =
  case+ b of
  | @BUF(A, cap, len) => let
      val () = len := n
    in
      fold@(b)
    end

implement buf_get(b, i) =
  case+ b of
  | @BUF(A, cap, len) => let
      val c = byte_get(A, cap, i)
    in
      fold@(b); c
    end

implement buf_set(b, i, v) =
  case+ b of
  | @BUF(A, cap, len) => let
      val () = byte_put(A, cap, i, v)
    in
      fold@(b)
    end

implement buf_get32(b, i) =
  case+ b of
  | @BUF(A, cap, len) => let
      val c = word_get(A, cap, i)
    in
      fold@(b); c
    end

implement buf_set32(b, i, v) =
  case+ b of
  | @BUF(A, cap, len) => let
      val () = word_put(A, cap, i, v)
    in
      fold@(b)
    end

implement buf_ptr(b) =
  case+ b of
  | @BUF(A, cap, len) => let
      val q = arrayptr2ptr(A)
    in
      fold@(b); q
    end

implement buf_cstr(b) =
  case+ b of
  | @BUF(A, cap, len) => let
      val s = ptr_string(arrayptr2ptr(A))
    in
      fold@(b); s
    end

implement buf_resize(b, n0) =
  if n0 >= 1 then resize_pos(b, airlock_pos(n0)) else ()

implement buf_ensure(b, n) = let
  val cap = buf_cap(b)
in
  if cap >= n then ()
  else let
    val n2: int = (if cap * 2 > n then cap * 2 else n): int
  in
    buf_resize(b, n2)
  end
end

implement buf_append(b, p, n) = let
  val len = buf_len(b)
  val () = buf_ensure(b, len + n + 1)
  val () =
    if n > 0 then let
      val+@BUF(A, cap, ln) = b
      val () = c_memcpy(ptr_add<byte>(arrayptr2ptr(A), len), p, g0int2uint_int_size(n))
    in
      fold@(b)
    end else ()
  val () = buf_set_len(b, len + n)
  val () = buf_set(b, len + n, 0)
in
end

implement buf_push(b, v) = let
  val len = buf_len(b)
  val () = buf_ensure(b, len + 2)
  val () = buf_set(b, len, v)
  val () = buf_set_len(b, len + 1)
in
end

implement buf_zero(b) =
  case+ b of
  | @BUF(A, cap, len) => let
      val () = c_memset(arrayptr2ptr(A), 0, g0int2uint_int_size(cap))
      val () = len := 0
    in
      fold@(b)
    end

implement buf_set_f32(b, i, v) =
  case+ b of
  | @BUF(A, cap, len) => let
      val () = mem_set_f32(arrayptr2ptr(A), cap, i, v)
    in
      fold@(b)
    end

implement buf_append_at(dst, src, st, n) =
  if n > 0 then let
    val cap = buf_cap(src)
    val p = mem_ptr_at(buf_ptr(src), cap, st)
  in
    buf_append(dst, p, n)
  end else ()

extern fun mem_live_c(): int = "mac#anth_mem_live"
implement mem_live() = mem_live_c()

implement u_zero() = g0int2uint_int_uint(0)

implement u_of(n) = if n < 0 then g0int2uint_int_uint(0) else g0int2uint_int_uint(n)

implement anth_iand(a, n) = g0uint2int_uint_int(g0uint_land(g0int2uint_int_uint(a), g0int2uint_int_uint(n)))

implement anth_bit(a, m) = if g0uint2int_uint_int(g0uint_land(g0int2uint_int_uint(a), g0int2uint_int_uint(m))) <> 0 then 1 else 0

implement anth_u32(hi, lo) = let
  val hi16 = g0uint_land(g0int2uint_int_uint(hi), 65535u)
  val lo16 = g0uint_land(g0int2uint_int_uint(lo), 65535u)
  val v = g0uint_lor(g0uint_lsl(hi16, 16), lo16)
in
  if v > 2147483647u then 0 else g0uint2int_uint_int(v)
end

implement anth_ms(a, b) = let
  val d0 = b - a
  val d = if d0 < 0L then 0L else d0 / 1000000L
  val cap = g0int2int_int_lint(2147483647)
in
  if d > cap then 2147483647 else g0int2int_lint_int(d)
end

implement anth_i2lint(n) = g0int2int_int_lint(n)

implement anth_i2sz(n) = if n < 0 then g0int2uint_int_size(0) else g0int2uint_int_size(n)

implement anth_d2f(d) = g0float2float_double_float(d)

implement anth_u2i(v) = if v > 2147483647u then 0 else g0uint2int_uint_int(v)
