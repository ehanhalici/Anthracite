%{#
#include "mem.cats"
%}

(* Owned byte buffers. The linear Buf is the free-proof; the
   payload is released with mfree_gc exactly once. *)

absviewtype Buf = ptr

fun mem_live(): int
fun buf_make(n: int): Buf
fun buf_free(b: Buf): void
fun buf_cap(b: !Buf): int
fun buf_len(b: !Buf): int
fun seen_buf(b: !Buf): void
fun seen_int(x: int): void
fun seen_uint(x: uint): void
fun buf_set_len(b: !Buf, n: int): void
fun buf_get(b: !Buf, i: int): int
fun buf_set(b: !Buf, i: int, v: int): void
fun buf_get32(b: !Buf, i: int): int
fun buf_set32(b: !Buf, i: int, v: int): void
(* C ABI exit. Byte access goes through buf_get / buf_set / buf_cstr.
   Call buf_ptr only when a C function needs an address. *)
fun buf_ptr(b: !Buf): ptr
fun buf_cstr(b: !Buf): string
fun buf_ensure(b: &Buf >> _, n: int): void
fun buf_resize(b: &Buf >> _, n: int): void
fun buf_append(b: &Buf >> _, p: ptr, n: int): void
fun buf_push(b: &Buf >> _, v: int): void
fun buf_zero(b: !Buf): void
fun buf_set_f32(b: !Buf, i: int, v: float): void
fun buf_append_at(dst: &Buf >> _, src: !Buf, st: int, n: int): void
fun fs_read_buf(fd: int, b: !Buf, n: int): int
fun fs_write_buf(path: string, b: !Buf, n: int): int
fun dir_next_buf(d: ptr, name: !Buf, namemax: int, isdir: &int >> _): int
fun fs_vfs_buf(path: string, dst: !Buf, dstmax: int): void
fun c_cwd_buf(dst: !Buf, n: int): int
fun c_fc_font_buf(dst: !Buf, n: int): int
fun c_fc_arabic_font_buf(dst: !Buf, n: int): int

fun mem_byte(p: ptr, n: int, i: int): int = "mac#anth_mem_byte"
fun mem_set_byte(p: ptr, n: int, i: int, v: int): void = "mac#anth_mem_set_byte"
fun mem_i32(p: ptr, n: int, i: int): int = "mac#anth_mem_i32"
fun mem_set_i32(p: ptr, n: int, i: int, v: int): void = "mac#anth_mem_set_i32"
fun mem_set_f32(p: ptr, n: int, i: int, v: float): void = "mac#anth_mem_set_f32"
fun mem_ptr_at(p: ptr, n: int, i: int): ptr = "mac#anth_ptr_at"
fun ptr_string(p: ptr): string = "mac#anth_ptr_string"
fun u_zero(): uint
fun u_of(n: int): uint
fun anth_iand(a: int, n: int): int
fun anth_bit(a: int, m: int): int
fun anth_u32(hi: int, lo: int): int
fun anth_ms(a: lint, b: lint): int
fun anth_i2lint(n: int): lint
fun anth_i2sz(n: int): size_t
fun anth_d2f(d: double): float
fun anth_u2i(v: uint): int
