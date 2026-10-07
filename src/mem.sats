%{#
#include "mem.cats"
%}

(* Owned byte buffers. The linear Buf is the free-proof; the
   payload is released with mfree_gc exactly once. *)

absviewtype Buf = ptr

fun mem_live(): int = "mac#anth_mem_live"
fun buf_make(n: int): Buf
fun buf_free(b: Buf): void
fun buf_cap(b: !Buf): int
fun buf_len(b: !Buf): int
fun buf_set_len(b: !Buf, n: int): void
fun buf_get(b: !Buf, i: int): int
fun buf_set(b: !Buf, i: int, v: int): void
fun buf_get32(b: !Buf, i: int): int
fun buf_set32(b: !Buf, i: int, v: int): void
fun buf_ptr(b: !Buf): ptr
fun buf_ensure(b: &Buf >> _, n: int): void
fun buf_resize(b: &Buf >> _, n: int): void
fun buf_set_bytes(b: &Buf >> _, p: ptr, n: int): void
fun buf_append(b: &Buf >> _, p: ptr, n: int): void
fun buf_push(b: &Buf >> _, v: int): void
fun buf_zero(b: !Buf): void

fun mem_byte(p: ptr, n: int, i: int): int = "mac#anth_mem_byte"
fun mem_set_byte(p: ptr, n: int, i: int, v: int): void = "mac#anth_mem_set_byte"
fun mem_i32(p: ptr, n: int, i: int): int = "mac#anth_mem_i32"
fun mem_set_i32(p: ptr, n: int, i: int, v: int): void = "mac#anth_mem_set_i32"
fun mem_set_f32(p: ptr, n: int, i: int, v: float): void = "mac#anth_mem_set_f32"
fun mem_ptr_at(p: ptr, n: int, i: int): ptr = "mac#anth_ptr_at"
fun ptr_string(p: ptr): string = "mac#anth_ptr_string"
fun u_zero(): uint = "mac#anth_u_zero"
fun u_of(n: int): uint = "mac#anth_u_of"
fun anth_iand(a: int, n: int): int = "mac#anth_iand"
fun anth_bit(a: int, m: int): int = "mac#anth_bit"
fun anth_u32(hi: int, lo: int): int = "mac#anth_u32"
fun anth_ms(a: lint, b: lint): int = "mac#anth_ms"
fun anth_i2lint(n: int): lint = "mac#anth_i2lint"
fun anth_i2sz(n: int): size_t = "mac#anth_i2sz"
fun anth_d2f(d: double): float = "mac#anth_d2f"
fun anth_u2i(v: uint): int = "mac#anth_u2i"

fun mem_allocs(): int
fun mem_frees(): int
fun mem_live(): int
