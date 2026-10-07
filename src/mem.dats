#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "mem.sats"

extern fun c_memcpy(dst: ptr, src: ptr, n: size_t): void = "mac#memcpy"
extern fun c_memset(dst: ptr, src: int, n: size_t): void = "mac#memset"

extern fun mem_note_alloc(n: int): void = "mac#anth_mem_alloc"
extern fun mem_note_free(n: int): void = "mac#anth_mem_free"

datavtype Buf_ =
  | {l:agz}{n:nat} BUF of (b0ytes(n) @ l, mfree_gc_v(l) | ptr(l), int, int)
assume Buf = Buf_

local

fun make_pos{n:pos}(n: int(n)): Buf = let
  val (pf, pfgc | p) = malloc_gc(i2sz(n))
  val () = c_memset(p, 0, anth_i2sz(n))
  val () = mem_note_alloc(n)
in
  BUF(pf, pfgc | p, n, 0)
end

fun resize_pos{n:pos}(b: &Buf >> _, n: int(n)): void = let
  val+~BUF(pf, pfgc | p, cap, len) = b
  val (pf2, pfgc2 | p2) = malloc_gc(i2sz(n))
  val () = mem_note_alloc(n)
  val ncopy = (if cap < n then cap else n): int
  val () = c_memcpy(p2, p, anth_i2sz(ncopy))
  val () =
    if n > ncopy then
      c_memset(mem_ptr_at(p2, n, ncopy), 0, anth_i2sz(n - ncopy))
    else ()
  val () = mfree_gc(pf, pfgc | p)
  val () = mem_note_free(cap)
  val len2 = (if len < n then len else n): int
in
  b := BUF(pf2, pfgc2 | p2, n, len2)
end

in

implement buf_make(n0) = let
  val n = g1ofg0(n0)
in
  if n >= 1 then make_pos(n) else make_pos(1)
end

implement buf_free(b) = let
  val+~BUF(pf, pfgc | p, cap, len) = b
  val () = mem_note_free(cap)
in
  mfree_gc(pf, pfgc | p)
end

implement buf_cap(b) =
  case+ b of
  | @BUF(pf, pfgc | p, cap, len) => let
      val c = cap
    in
      fold@(b); c
    end

implement buf_len(b) =
  case+ b of
  | @BUF(pf, pfgc | p, cap, len) => let
      val k = len
    in
      fold@(b); k
    end

implement buf_set_len(b, n) =
  case+ b of
  | @BUF(pf, pfgc | p, cap, len) => let
      val () = len := n
    in
      fold@(b)
    end

implement buf_get(b, i) =
  case+ b of
  | @BUF(pf, pfgc | p, cap, len) => let
      val c = mem_byte(p, cap, i)
    in
      fold@(b); c
    end

implement buf_set(b, i, v) =
  case+ b of
  | @BUF(pf, pfgc | p, cap, len) => let
      val () = mem_set_byte(p, cap, i, v)
    in
      fold@(b)
    end

implement buf_get32(b, i) =
  case+ b of
  | @BUF(pf, pfgc | p, cap, len) => let
      val c = mem_i32(p, cap, i)
    in
      fold@(b); c
    end

implement buf_set32(b, i, v) =
  case+ b of
  | @BUF(pf, pfgc | p, cap, len) => let
      val () = mem_set_i32(p, cap, i, v)
    in
      fold@(b)
    end

implement buf_ptr(b) =
  case+ b of
  | @BUF(pf, pfgc | p, cap, len) => let
      val q = p
    in
      fold@(b); q
    end

implement buf_resize(b, n0) = let
  val n = g1ofg0(n0)
in
  if n >= 1 then resize_pos(b, n) else ()
end

implement buf_ensure(b, n) = let
  val cap = buf_cap(b)
in
  if cap >= n then ()
  else let
    val n2 = (if cap * 2 > n then cap * 2 else n): int
  in
    buf_resize(b, n2)
  end
end

implement buf_set_bytes(b, p, n) = let
  val () = buf_ensure(b, n + 1)
  val () =
    if n > 0 then let
      val () = c_memcpy(buf_ptr(b), p, anth_i2sz(n))
    in
      buf_set(b, n, 0)
    end else buf_set(b, 0, 0)
  val () = buf_set_len(b, n)
in
end

implement buf_append(b, p, n) = let
  val len = buf_len(b)
  val () = buf_ensure(b, len + n + 1)
  val cap = buf_cap(b)
  val () =
    if n > 0 then
      c_memcpy(mem_ptr_at(buf_ptr(b), cap, len), p, anth_i2sz(n))
    else ()
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

implement buf_zero(b) = let
  val cap = buf_cap(b)
  val () = c_memset(buf_ptr(b), 0, anth_i2sz(cap))
  val () = buf_set_len(b, 0)
in
end

end

extern fun anth_mem_allocs(): int = "mac#"
extern fun anth_mem_frees(): int = "mac#"
extern fun anth_mem_live(): int = "mac#"

implement mem_allocs() = anth_mem_allocs()
implement mem_frees() = anth_mem_frees()
implement mem_live() = anth_mem_live()
