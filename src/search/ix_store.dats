#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "search/ix_store.sats"

fun iand(a: int, n: int): int = anth_iand(a, n)

fun buf_push32(b: &Buf >> _, v: int): void = let
  val len = buf_len(b)
  val idx = idiv(len, 4)
  val need = iadd(len, 4)
  val () = if buf_cap(b) < need then buf_resize(b, imax(imul(need, 2), 64)) else ()
  val () = buf_set_len(b, need)
  val () = buf_set32(b, idx, v)
in
end

implement ix_file_count(ixf) = idiv(buf_len(ixf), 32)
implement ix_file_get(ixf, fid, field) = buf_get32(ixf, iadd(imul(fid, 8), field))
implement ix_file_set(ixf, fid, field, v) = buf_set32(ixf, iadd(imul(fid, 8), field), v)

implement ix_file_add(ixf, poff, plen, sz, mt, st, dver, sfirst, scnt) = let
  val fid = ix_file_count(ixf)
  val () = buf_push32(ixf, poff)
  val () = buf_push32(ixf, plen)
  val () = buf_push32(ixf, sz)
  val () = buf_push32(ixf, mt)
  val () = buf_push32(ixf, st)
  val () = buf_push32(ixf, dver)
  val () = buf_push32(ixf, sfirst)
  val () = buf_push32(ixf, scnt)
in
  fid
end

implement ix_sym_count(ixs) = idiv(buf_len(ixs), 32)
implement ix_sym_get(ixs, sid, field) = buf_get32(ixs, iadd(imul(sid, 8), field))
implement ix_sym_set(ixs, sid, field, v) = buf_set32(ixs, iadd(imul(sid, 8), field), v)

implement ix_sym_add(ixs, fid, kind, st, en, line, toff, tlen, aux) = let
  val sid = ix_sym_count(ixs)
  val () = buf_push32(ixs, fid)
  val () = buf_push32(ixs, kind)
  val () = buf_push32(ixs, st)
  val () = buf_push32(ixs, en)
  val () = buf_push32(ixs, line)
  val () = buf_push32(ixs, toff)
  val () = buf_push32(ixs, tlen)
  val () = buf_push32(ixs, aux)
in
  sid
end

fun hash1_trigram(b0: int, b1: int, b2: int): int = let
  val h = iadd(imul(iadd(imul(b0, 31), b1), 31), b2)
  val m = imod(h, 2048)
in
  if ilt(m, 0) then iadd(m, 2048) else m
end

fun hash2_trigram(b0: int, b1: int, b2: int): int = let
  val h = iadd(imul(iadd(imul(b0, 17), b1), 37), b2)
  val m = imod(h, 2048)
in
  if ilt(m, 0) then iadd(m, 2048) else m
end

fun bit_mask8(b: int): int =
  if b = 0 then 1
  else if b = 1 then 2
  else if b = 2 then 4
  else if b = 3 then 8
  else if b = 4 then 16
  else if b = 5 then 32
  else if b = 6 then 64
  else 128

fun bloom_set_bit(ixb: !Buf, fid: int, bit_idx: int): void = let
  val byte_off = iadd(imul(fid, 256), idiv(bit_idx, 8))
  val bit_val = bit_mask8(iand(bit_idx, 7))
  val cur = buf_get(ixb, byte_off)
  val nxt = g0uint2int_uint_int(g0uint_lor(g0int2uint_int_uint(cur), g0int2uint_int_uint(bit_val)))
in
  buf_set(ixb, byte_off, nxt)
end

fun bloom_test_bit(ixb: !Buf, fid: int, bit_idx: int): bool = let
  val byte_off = iadd(imul(fid, 256), idiv(bit_idx, 8))
  val bit_val = bit_mask8(iand(bit_idx, 7))
  val cur = buf_get(ixb, byte_off)
in
  iand(cur, bit_val) != 0
end

implement ix_bloom_set_trigram(ixb, fid, b0, b1, b2) = let
  val h1 = hash1_trigram(b0, b1, b2)
  val h2 = hash2_trigram(b0, b1, b2)
  val () = bloom_set_bit(ixb, fid, h1)
  val () = bloom_set_bit(ixb, fid, h2)
in
end

implement ix_bloom_test_trigram(ixb, fid, b0, b1, b2) = let
  val h1 = hash1_trigram(b0, b1, b2)
  val h2 = hash2_trigram(b0, b1, b2)
in
  bloom_test_bit(ixb, fid, h1) andalso bloom_test_bit(ixb, fid, h2)
end

extern fun zero_pad_exh(b: &Buf >> _, cur: int, target: int): void = "mac#anth_die_void"

fun zero_pad_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: &Buf >> _, cur: int, target: int): void =
  if recfuel > 0 then (
    if ilt(cur, target) then let
      val () = buf_push(b, 0)
    in
      zero_pad_m(recfuel - 1, b, iadd(cur, 1), target)
    end else ()
  ) else zero_pad_exh(b, cur, target)

implement ix_bloom_ensure(ixb, nfiles) = let
  val target = imul(nfiles, 256)
  val cur = buf_len(ixb)
in
  if ilt(cur, target) then
    zero_pad_m(airlock_nat(MAX_REC_FUEL), ixb, cur, target)
  else ()
end
