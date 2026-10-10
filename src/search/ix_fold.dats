#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "data_ast/doc.sats"
staload "search/ix_fold.sats"

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

fun decode_utf8_2(b0: int, b1: int): int =
  iadd(imul(iand(b0, 31), 64), iand(b1, 63))

fun fold_cp_2(cp: int): int =
  if ieq(cp, 0x0130) orelse ieq(cp, 0x0131) then 105
  else if ige(cp, 0x00C0) andalso ile(cp, 0x00DE) andalso ine(cp, 0x00D7) then iadd(cp, 32)
  else if ige(cp, 0x0100) andalso ile(cp, 0x012E) andalso ieq(iand(cp, 1), 0) then iadd(cp, 1)
  else if ige(cp, 0x0132) andalso ile(cp, 0x0136) andalso ieq(iand(cp, 1), 0) then iadd(cp, 1)
  else if ige(cp, 0x0139) andalso ile(cp, 0x0147) andalso ieq(iand(cp, 1), 1) then iadd(cp, 1)
  else if ige(cp, 0x014A) andalso ile(cp, 0x0176) andalso ieq(iand(cp, 1), 0) then iadd(cp, 1)
  else if ige(cp, 0x015E) andalso ile(cp, 0x0160) andalso ieq(iand(cp, 1), 0) then iadd(cp, 1)
  else if ige(cp, 0x0391) andalso ile(cp, 0x03A9) then iadd(cp, 32)
  else if ige(cp, 0x0410) andalso ile(cp, 0x042F) then iadd(cp, 32)
  else if ige(cp, 0x0400) andalso ile(cp, 0x040F) then iadd(cp, 80)
  else cp

fun push_cp(dst: &Buf >> _, omap: &Buf >> _, orig: int, cp: int): void =
  if ilt(cp, 128) then let
    val () = buf_push(dst, cp)
    val () = buf_push32(omap, orig)
  in
  end else if ilt(cp, 2048) then let
    val b0 = iadd(192, idiv(cp, 64))
    val b1 = iadd(128, iand(cp, 63))
    val () = buf_push(dst, b0)
    val () = buf_push32(omap, orig)
    val () = buf_push(dst, b1)
    val () = buf_push32(omap, orig)
  in
  end else ()

fun push_raw(dst: &Buf >> _, omap: &Buf >> _, orig: int, b: int): void = let
  val () = buf_push(dst, b)
  val () = buf_push32(omap, orig)
in
end

fun step_buf(src: !Buf, p: int, en: int, dst: &Buf >> _, omap: &Buf >> _): int = let
  val b0 = buf_get(src, p)
in
  if ige(b0, 65) andalso ile(b0, 90) then let
    val () = push_cp(dst, omap, p, iadd(b0, 32))
  in
    iadd(p, 1)
  end else if ige(b0, 192) andalso ile(b0, 223) andalso ilt(iadd(p, 1), en) then let
    val b1 = buf_get(src, iadd(p, 1))
  in
    if ige(b1, 128) andalso ile(b1, 191) then let
      val cp = decode_utf8_2(b0, b1)
      val () = push_cp(dst, omap, p, fold_cp_2(cp))
    in
      iadd(p, 2)
    end else (push_raw(dst, omap, p, b0); iadd(p, 1))
  end else (push_raw(dst, omap, p, b0); iadd(p, 1))
end

fun step_doc(d: !Doc, p: int, en: int, dst: &Buf >> _, omap: &Buf >> _): int = let
  val b0 = doc_byte(d, p)
in
  if ige(b0, 65) andalso ile(b0, 90) then let
    val () = push_cp(dst, omap, p, iadd(b0, 32))
  in
    iadd(p, 1)
  end else if ige(b0, 192) andalso ile(b0, 223) andalso ilt(iadd(p, 1), en) then let
    val b1 = doc_byte(d, iadd(p, 1))
  in
    if ige(b1, 128) andalso ile(b1, 191) then let
      val cp = decode_utf8_2(b0, b1)
      val () = push_cp(dst, omap, p, fold_cp_2(cp))
    in
      iadd(p, 2)
    end else (push_raw(dst, omap, p, b0); iadd(p, 1))
  end else (push_raw(dst, omap, p, b0); iadd(p, 1))
end

fun fold_loop_buf_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, p: int, en: int, dst: &Buf >> _, omap: &Buf >> _): void =
  if recfuel > 0 then (
    if ilt(p, en) then let
      val nxt = step_buf(src, p, en, dst, omap)
    in
      fold_loop_buf_m(recfuel - 1, src, nxt, en, dst, omap)
    end else ()
  ) else ()

fun fold_loop_doc_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: int, en: int, dst: &Buf >> _, omap: &Buf >> _): void =
  if recfuel > 0 then (
    if ilt(p, en) then let
      val nxt = step_doc(d, p, en, dst, omap)
    in
      fold_loop_doc_m(recfuel - 1, d, nxt, en, dst, omap)
    end else ()
  ) else ()

implement fold_next_buf(b, i, n, cp, clen) = let
  val b0 = (if ilt(i, n) then buf_get(b, i) else 0)
in
  if ilt(i, n) andalso ige(b0, 192) andalso ile(b0, 223) andalso ilt(iadd(i, 1), n) then let
    val b1 = buf_get(b, iadd(i, 1))
  in
    cp := decode_utf8_2(b0, b1);
    clen := 2
  end else (cp := b0; clen := 1)
end

implement fold_range_buf(src, st, en, dst, omap) =
  fold_loop_buf_m(airlock_nat(MAX_REC_FUEL), src, st, en, dst, omap)

implement fold_range_doc(d, st, en, dst, omap) =
  fold_loop_doc_m(airlock_nat(MAX_REC_FUEL), d, st, en, dst, omap)
