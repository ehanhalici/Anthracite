#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "os/diag.sats"
staload "data_ast/doc.sats"
staload "data_ast/layout.sats"
staload "data_ast/layout_internal.sats"
staload "data_ast/doc_visual.sats"
staload "data_ast/visual_rows.sats"
staload "data_ast/doc_parse.sats"
staload "data_ast/ast.sats"
staload "data_ast/ast_test.sats"
staload "data_ast/blk_parse.sats"

#define NS 16

#define DOC_FIELD_LO 0
#define DOC_FIELD_HI 1
#define DOC_FIELD_LEN 2
#define DOC_FIELD_CARET 3
#define DOC_FIELD_ANCHOR 4
#define DOC_FIELD_NLINES 5
#define DOC_FIELD_NNODES 6
#define DOC_FIELD_SPAN 7

#define DOC_OP_NONE 0
#define DOC_OP_TYPING 1
#define DOC_OP_BATCH 2

datavtype Hist =
  | HNil of ()
  | HCons of (Buf, int, Hist)

extern fun hist_free_exh(h: Hist): void = "mac#anth_die_void"

fun hist_free_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), h: Hist): void =
  if recfuel > 0 then (
    case+ h of
    | ~HNil() => ()
    | ~HCons(b, _, rest) => let
        val () = buf_free(b)
      in
        hist_free_m(recfuel - 1, rest)
      end
  ) else hist_free_exh(h)

fun hist_free(h: Hist): void = hist_free_m(airlock_nat(MAX_REC_FUEL), h)

extern fun hist_drop_oldest_exh(h: Hist): Hist = "mac#anth_die_box"

fun hist_drop_oldest_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), h: Hist): Hist =
  if recfuel > 0 then (
    case+ h of
    | ~HNil() => HNil()
    | ~HCons(b, c, rest) =>
        case+ rest of
        | HNil() => let
            val () = buf_free(b)
            val () = hist_free(rest)
          in
            HNil()
          end
        | ~HCons(b2, c2, rest2) => HCons(b, c, hist_drop_oldest_m(recfuel - 1, HCons(b2, c2, rest2)))
  ) else hist_drop_oldest_exh(h)

fun hist_drop_oldest(h: Hist): Hist = hist_drop_oldest_m(airlock_nat(MAX_REC_FUEL), h)

extern fun hist_len_exh(h: !Hist): int = "mac#anth_die_int"

fun hist_len_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), h: !Hist): int =
  if recfuel > 0 then (
    case+ h of
    | HNil() => 0
    | HCons(_, _, rest) => iadd(1, hist_len_m(recfuel - 1, rest))
  ) else hist_len_exh(h)

fun hist_len(h: !Hist): int = hist_len_m(airlock_nat(MAX_REC_FUEL), h)

fun hist_trim(h: Hist): Hist =
  case+ ige(hist_len(h), 35) of
  | true => hist_drop_oldest(h)
  | false => h

datatype EditOp = OpNone | OpChar | OpBreak

fun op_code(k: EditOp): int = case+ k of
  | OpNone() => 0
  | OpChar() => 1
  | OpBreak() => 2

fun is_op(a: EditOp, b: EditOp): bool = ieq(op_code(a), op_code(b))

datavtype Doc_ = DOC of @{
  gap= Buf, lines= Buf, nodes= Buf, lay= Buf, visual= Option_vt(VisualRows)
, uhist= Hist, rhist= Hist
, lo= int, hi= int, len= int
, caret= int, anchor= int
, nlines= int, nnodes= int, span= int
, last_op= EditOp, typing_cnt= int, is_md= Toggle
, ver= int, folds= Buf
, flash_line= int, flash_time= lint, embed_level= int
}
(* skill.md 1. kural istisnasi: ATS2 soyut tip gerceklemesi (sats'taki absviewtype). Kanit disi cast veya ham C yoktur. *)
assume Doc = Doc_
#include "data_ast/private/doc_visual_owner.hats"
#include "data_ast/private/doc_visual_index_impl.hats"

implement doc_open() = DOC(@{
  gap= buf_make(256), lines= buf_make(64 * 4), nodes= buf_make(64 * NS * 4), lay= layout_open(), visual= None_vt()
, uhist= HNil(), rhist= HNil()
, lo= 0, hi= 256, len= 0
, caret= 0, anchor= 0
, nlines= 1, nnodes= 0, span= 0
, last_op= OpNone, typing_cnt= 0, is_md= On
, ver= 0, folds= buf_make(64 * 4)
, flash_line= ~1, flash_time= 0L, embed_level= 0
})

implement doc_set_flash(d, line, until) =
  case+ d of
  | @DOC(s) => let
      val () = s.flash_line := line
      val () = s.flash_time := until
    in
      fold@(d)
    end

implement doc_get_flash(d, now) =
  case+ d of
  | @DOC(s) => let
      val res = (if ige(s.flash_line, 0) andalso now < s.flash_time then s.flash_line else ~1)
    in
      fold@(d); res
    end

implement doc_is_md(d) =
  case+ d of
  | @DOC(s) => let
      val v = s.is_md
    in
      fold@(d); v
    end

implement doc_set_md(d, v) =
  case+ d of
  | @DOC(s) => let
      val () = s.is_md := v
    in
      fold@(d)
    end

implement doc_embed_level(d) =
  case+ d of
  | @DOC(s) => let
      val level = s.embed_level
    in
      fold@(d); level
    end

implement doc_set_embed_level(d, level) =
  case+ d of
  | @DOC(s) => let
      val () = s.embed_level := level
    in
      fold@(d)
    end

implement doc_free(d) = let
  val+~DOC(s) = d
  val () = visual_release(s.visual)
  val () = buf_free(s.gap)
  val () = buf_free(s.lines)
  val () = layout_dispose(s.lay)
  val () = buf_free(s.nodes)
  val () = buf_free(s.folds)
  val () = hist_free(s.uhist)
in
  hist_free(s.rhist)
end

fun d_ver(d: !Doc): int =
  case+ d of
  | @DOC(s) => let
      val v = s.ver
    in
      fold@(d); v
    end

fun d_bump_ver(d: !Doc): void =
  case+ d of
  | @DOC(s) => let
      val () = s.ver := iadd(s.ver, 1)
    in
      fold@(d)
    end

implement doc_bump_ver(d) = d_bump_ver(d)

fun fold_count(d: !Doc): int =
  case+ d of
  | @DOC(s) => let
      val n = buf_len(s.folds) / 4
    in
      fold@(d); n
    end

fun fold_get(d: !Doc, idx: int): int =
  case+ d of
  | @DOC(s) => let
      val v = buf_get32(s.folds, iadd(imul(idx, 4), 0))
    in
      fold@(d); v
    end

fun fold_set(d: !Doc, idx: int, v: int): void =
  case+ d of
  | @DOC(s) => let
      val () = buf_set32(s.folds, iadd(imul(idx, 4), 0), v)
    in
      fold@(d)
    end

extern fun fold_has_exh(d: !Doc, off: int, i: int, n: int): bool = "mac#anth_die_int"

fun fold_has_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, off: int, i: int, n: int
): bool =
  if recfuel > 0 then (
    if i >= n then false
    else if fold_get(d, i) = off then true
    else fold_has_m(recfuel - 1, d, off, iadd(i, 1), n)
  ) else fold_has_exh(d, off, i, n)

fun fold_has(d: !Doc, off: int): bool =
  fold_has_m(airlock_nat(MAX_REC_FUEL), d, off, 0, fold_count(d))

fun fold_add(d: !Doc, off: int): void =
  if fold_has(d, off) then ()
  else case+ d of
  | @DOC(s) => let
      val len = buf_len(s.folds)
      val () = buf_resize(s.folds, iadd(len, 4))
      val () = buf_set32(s.folds, len, off)
    in
      fold@(d)
    end

extern fun fold_del_shift_exh(d: !Doc, i: int, n: int): void = "mac#anth_die_void"

fun fold_del_shift_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, n: int
): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val v = fold_get(d, iadd(i, 1))
      val () = fold_set(d, i, v)
    in
      fold_del_shift_m(recfuel - 1, d, iadd(i, 1), n)
    end
  ) else fold_del_shift_exh(d, i, n)

extern fun fold_del_find_exh(d: !Doc, off: int, i: int, n: int): void = "mac#anth_die_void"

fun d_folds_trunc(d: !Doc): void =
  case+ d of
  | @DOC(s) => let
      val b = s.folds
      val n = buf_len(b)
      val () = buf_set_len(b, isub(n, 4))
      val () = s.folds := b
    in
      fold@(d)
    end

fun d_folds_clear(d: !Doc): void =
  case+ d of
  | @DOC(s) => let
      val b = s.folds
      val () = buf_set_len(b, 0)
      val () = s.folds := b
    in
      fold@(d)
    end

extern fun fold_del_find_exh(d: !Doc, off: int, i: int, n: int): void = "mac#anth_die_void"

fun fold_del_find_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, off: int, i: int, n: int
): void =
  if recfuel > 0 then (
    if i >= n then ()
    else if fold_get(d, i) = off then let
      val () = fold_del_shift_m(airlock_nat(MAX_REC_FUEL), d, i, isub(n, 1))
      val () = d_folds_trunc(d)
    in
    end else fold_del_find_m(recfuel - 1, d, off, iadd(i, 1), n)
  ) else fold_del_find_exh(d, off, i, n)

fun fold_del(d: !Doc, off: int): void =
  fold_del_find_m(airlock_nat(MAX_REC_FUEL), d, off, 0, fold_count(d))

extern fun fold_shift_exh(d: !Doc, at: int, delta: int, i: int, n: int): void = "mac#anth_die_void"

fun fold_shift_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, at: int, delta: int, i: int, n: int
): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val v = fold_get(d, i)
      val () = if v >= at then fold_set(d, i, iadd(v, delta)) else ()
    in
      fold_shift_m(recfuel - 1, d, at, delta, iadd(i, 1), n)
    end
  ) else fold_shift_exh(d, at, delta, i, n)

fun fold_shift(d: !Doc, at: int, delta: int): void =
  fold_shift_m(airlock_nat(MAX_REC_FUEL), d, at, delta, 0, fold_count(d))

fun fold_clear(d: !Doc): void = d_folds_clear(d)

fun dget(d: !Doc, w: int): int =
  case+ d of
  | @DOC(s) => let
      val v =
        if w = DOC_FIELD_LO then s.lo
        else if w = DOC_FIELD_HI then s.hi
        else if w = DOC_FIELD_LEN then s.len
        else if w = DOC_FIELD_CARET then s.caret
        else if w = DOC_FIELD_ANCHOR then s.anchor
        else if w = DOC_FIELD_NLINES then s.nlines
        else if w = DOC_FIELD_NNODES then s.nnodes
        else s.span
    in
      fold@(d); v
    end

fun dset(d: !Doc, w: int, v: int): void =
  case+ d of
  | @DOC(s) => let
      val () =
        if w = DOC_FIELD_LO then s.lo := v
        else if w = DOC_FIELD_HI then s.hi := v
        else if w = DOC_FIELD_LEN then s.len := v
        else if w = DOC_FIELD_CARET then s.caret := v
        else if w = DOC_FIELD_ANCHOR then s.anchor := v
        else if w = DOC_FIELD_NLINES then s.nlines := v
        else if w = DOC_FIELD_NNODES then s.nnodes := v
        else s.span := v
    in
      fold@(d)
    end

fun d_lo(d: !Doc): int = dget(d, DOC_FIELD_LO)
fun d_hi(d: !Doc): int = dget(d, DOC_FIELD_HI)
fun d_len(d: !Doc): int = dget(d, DOC_FIELD_LEN)
fun d_caret(d: !Doc): int = dget(d, DOC_FIELD_CARET)
fun d_anchor(d: !Doc): int = dget(d, DOC_FIELD_ANCHOR)
fun d_nlines(d: !Doc): int = dget(d, DOC_FIELD_NLINES)
fun d_nnodes(d: !Doc): int = dget(d, DOC_FIELD_NNODES)
fun d_span(d: !Doc): int = dget(d, DOC_FIELD_SPAN)

fun d_set_lo(d: !Doc, v: int): void = dset(d, DOC_FIELD_LO, v)
fun d_set_hi(d: !Doc, v: int): void = dset(d, DOC_FIELD_HI, v)
fun d_set_len(d: !Doc, v: int): void = dset(d, DOC_FIELD_LEN, v)
fun d_set_caret(d: !Doc, v: int): void = dset(d, DOC_FIELD_CARET, v)
fun d_set_anchor(d: !Doc, v: int): void = dset(d, DOC_FIELD_ANCHOR, v)
fun d_set_nlines(d: !Doc, v: int): void = dset(d, DOC_FIELD_NLINES, v)
fun d_set_nnodes(d: !Doc, v: int): void = dset(d, DOC_FIELD_NNODES, v)
fun d_set_span(d: !Doc, v: int): void = dset(d, DOC_FIELD_SPAN, v)

implement doc_len(d) = d_len(d)
implement doc_touch(d) = seen_int(doc_len(d))
implement doc_caret(d) = d_caret(d)
implement doc_anchor(d) = d_anchor(d)
implement doc_nlines(d) = d_nlines(d)
implement doc_nnodes(d) = d_nnodes(d)
implement doc_span(d) = d_span(d)
implement doc_set_span(d, v) = d_set_span(d, v)

fun take_gap(d: !Doc): Buf =
  case+ d of
  | @DOC(s) => let
      val b = s.gap
      val () = s.gap := buf_make(1)
    in
      fold@(d); b
    end

fun put_gap(d: !Doc, b: Buf): void =
  case+ d of
  | @DOC(s) => let
      val old = s.gap
      val () = s.gap := b
      val () = fold@(d)
    in
      buf_free(old)
    end


fun take_uhist(d: !Doc): Hist =
  case+ d of
  | @DOC(s) => let
      val h = s.uhist
      val () = s.uhist := HNil()
    in
      fold@(d); h
    end

fun put_uhist(d: !Doc, h: Hist): void =
  case+ d of
  | @DOC(s) => let
      val old = s.uhist
      val () = s.uhist := h
      val () = fold@(d)
    in
      hist_free(old)
    end

fun take_rhist(d: !Doc): Hist =
  case+ d of
  | @DOC(s) => let
      val h = s.rhist
      val () = s.rhist := HNil()
    in
      fold@(d); h
    end

fun put_rhist(d: !Doc, h: Hist): void =
  case+ d of
  | @DOC(s) => let
      val old = s.rhist
      val () = s.rhist := h
      val () = fold@(d)
    in
      hist_free(old)
    end

fun gap_get(d: !Doc, i: int): int =
  case+ d of
  | @DOC(s) => let
      val v = buf_get(s.gap, i)
    in
      fold@(d); v
    end

fun gap_set(d: !Doc, i: int, v: int): void =
  case+ d of
  | @DOC(s) => let
      val () = buf_set(s.gap, i, v)
    in
      fold@(d)
    end

implement doc_byte(d, i) = let
  val lo = d_lo(d)
  val hi = d_hi(d)
  val p = if i < lo then i else iadd(hi, isub(i, lo))
in
  gap_get(d, p)
end

fun copy_fwd(src: !Buf, so: int, dst: !Buf, dst0: int, n: int): void =
  buf_copy_range(dst, dst0, src, so, n)

fun copy_fwd_same(b: !Buf, so: int, dst0: int, n: int): void =
  buf_move_within(b, dst0, so, n)

fun copy_back_same(b: !Buf, so: int, dst0: int, n: int): void =
  buf_move_within(b, dst0, so, n)

fun gap_grow(d: !Doc, need: int): void = let
  val lo = d_lo(d)
  val hi = d_hi(d)
  val len = d_len(d)
  val b0 = take_gap(d)
  val cap = buf_cap(b0)
  val want = imax(imul(cap, 2), iadd(iadd(len, need), 64))
  val b1 = buf_make(want)
  val tail = isub(len, lo)
  val nhi = isub(want, tail)
  val () = copy_fwd(b0, 0, b1, 0, lo)
  val () = copy_fwd(b0, hi, b1, nhi, tail)
  val () = buf_free(b0)
  val () = put_gap(d, b1)
  val () = d_set_hi(d, nhi)
in
end

fun gap_shift_back(d: !Doc, at: int, lo: int, hi: int): void = let
  val n = isub(lo, at)
  val b = take_gap(d)
  val () = copy_back_same(b, at, isub(hi, n), n)
  val () = put_gap(d, b)
  val () = d_set_lo(d, at)
  val () = d_set_hi(d, isub(hi, n))
in
end

fun gap_shift_fwd(d: !Doc, at: int, lo: int, hi: int): void = let
  val n = isub(at, lo)
  val b = take_gap(d)
  val () = copy_fwd_same(b, hi, lo, n)
  val () = put_gap(d, b)
  val () = d_set_lo(d, at)
  val () = d_set_hi(d, iadd(hi, n))
in
end

fun gap_move(d: !Doc, at0: int): void = let
  val len = d_len(d)
  val at = if at0 < 0 then 0 else if at0 > len then len else at0
  val lo = d_lo(d)
  val hi = d_hi(d)
in
  if ieq(at, lo) then ()
  else if ilt(at, lo) then gap_shift_back(d, at, lo, hi)
  else gap_shift_fwd(d, at, lo, hi)
end

extern fun gap_room_exh(d: !Doc, n: int): void = "mac#anth_die_void"

fun gap_room_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, n: int): void =
  if recfuel > 0 then (
  let
    val lo = d_lo(d)
    val hi = d_hi(d)
  in
    if isub(hi, lo) >= n then () else let
      val () = gap_grow(d, n)
    in
      gap_room_m(recfuel - 1, d, n)
    end
  end
  ) else gap_room_exh(d, n)

fun gap_room(d: !Doc, n: int): void = gap_room_m(airlock_nat(MAX_REC_FUEL), d, n)

fun take_layout(d: !Doc): Buf =
  case+ d of
  | @DOC(s) => let
      val laybuf = s.lay
      val () = s.lay := buf_make(1)
    in
      fold@(d); laybuf
    end

fun put_layout(d: !Doc, laybuf: Buf): void =
  case+ d of
  | @DOC(s) => let
      val old = s.lay
      val () = s.lay := laybuf
      val () = fold@(d)
    in
      buf_free(old)
    end

fun ensure_layout_capacity(d: !Doc, need: int): void = let
  val old = take_layout(d)
  val cap = buf_cap(old)
in
  if ige(cap, need) then put_layout(d, old)
  else let
    val want = imax(need, imul(cap, 2))
    val fresh = buf_make(want)
    val () = copy_fwd(old, 0, fresh, 0, cap)
    val () = buf_free(old)
  in
    put_layout(d, fresh)
  end
end

implement doc_line_start(d, i) =
  case+ d of
  | @DOC(s) => let
      val v = if i >= 0 andalso i < s.nlines then buf_get32(s.lines, i) else 0
    in
      fold@(d); v
    end

fun line_put(d: !Doc, i: int, y: int, step: int): void = let
  val () = ensure_layout_capacity(d, layout_line_need(i))
  val laybuf0 = take_layout(d)
  var laybuf = laybuf0
  val () = layout_line_put(laybuf, i, y, step, d_nlines(d))
in
  put_layout(d, laybuf)
end

implement doc_layout_store_line(d, line, y, step) =
  line_put(d, line, y, step)

implement doc_line_y(d, i) =
  case+ d of
  | @DOC(s) => let
      val v = layout_line_y(s.lay, i, s.nlines)
    in
      fold@(d); v
    end

implement doc_line_step(d, i) =
  case+ d of
  | @DOC(s) => let
      val v = layout_line_step(s.lay, i, s.nlines)
    in
      fold@(d); v
    end


fun store_line_start(lines: &Buf >> Buf, ln: int, off: int): void = let
  val need = imul(iadd(ln, 1), 4)
  val () = if buf_cap(lines) < need then buf_resize(lines, imax(imul(need, 2), 4096)) else ()
  val () = buf_set32(lines, ln, off)
in
end

fun gap_byte_at(gap: !Buf, lo: int, hi: int, i: int): int =
  if ilt(i, lo) then buf_get(gap, i)
  else buf_get(gap, iadd(hi, isub(i, lo)))

extern fun rebuild_scan_exh(lines: &Buf >> Buf, gap: !Buf, lo: int, hi: int, n: int, i: int, ln: int): int = "mac#anth_die_int"

fun rebuild_scan_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), lines: &Buf >> Buf, gap: !Buf, lo: int, hi: int, n: int, i: int, ln: int): int =
  if recfuel > 0 then (
    if ige(i, n) then ln
    else if ieq(gap_byte_at(gap, lo, hi, i), 10) then let
      val () = store_line_start(lines, ln, iadd(i, 1))
    in
      rebuild_scan_m(recfuel - 1, lines, gap, lo, hi, n, iadd(i, 1), iadd(ln, 1))
    end
    else rebuild_scan_m(recfuel - 1, lines, gap, lo, hi, n, iadd(i, 1), ln)
  ) else rebuild_scan_exh(lines, gap, lo, hi, n, i, ln)

fun rebuild_scan(lines: &Buf >> Buf, gap: !Buf, lo: int, hi: int, n: int, i: int, ln: int): int = rebuild_scan_m(airlock_nat(MAX_REC_FUEL), lines, gap, lo, hi, n, i, ln)

fun rebuild_lines(d: !Doc): void =
  case+ d of
  | @DOC(s) => let
      val n = s.len
      val lo = s.lo
      val hi = s.hi
      val () = if buf_cap(s.lines) < 4096 then buf_resize(s.lines, 4096) else ()
      val () = buf_set32(s.lines, 0, 0)
      val ln = rebuild_scan(s.lines, s.gap, lo, hi, n, 0, 1)
    in
      s.nlines := ln;
      fold@(d)
    end

extern fun line_bsearch_exh(d: !Doc, off: int, lo: int, hi: int, best: int): int = "mac#anth_die_int"

fun line_bsearch_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, off: int, lo: int, hi: int, best: int): int =
  if recfuel > 0 then (
    if igt(lo, hi) then best
    else let
      val mid = iadd(lo, idiv(isub(hi, lo), 2))
      val st = doc_line_start(d, mid)
    in
      if ile(st, off) then line_bsearch_m(recfuel - 1, d, off, iadd(mid, 1), hi, mid)
      else line_bsearch_m(recfuel - 1, d, off, lo, isub(mid, 1), best)
    end
  ) else line_bsearch_exh(d, off, lo, hi, best)

fun line_bsearch(d: !Doc, off: int, lo: int, hi: int, best: int): int = line_bsearch_m(airlock_nat(MAX_REC_FUEL), d, off, lo, hi, best)

implement doc_line_of(d, off) = let
  val n = d_nlines(d)
in
  if ile(n, 1) then 0
  else if ile(off, 0) then 0
  else line_bsearch(d, off, 0, isub(n, 1), 0)
end

fun d_line_set(d: !Doc, i: int, off: int): void =
  case+ d of
  | @DOC(s) => let
      val () = buf_set32(s.lines, i, off)
    in
      fold@(d)
    end

fun d_lines_replace(d: !Doc, b: Buf): void =
  case+ d of
  | @DOC(s) => let
      val () = buf_free(s.lines)
      val () = s.lines := b
    in
      fold@(d)
    end

extern fun find_keep_exh(d: !Doc, at: int, cur: int, n: int): int = "mac#anth_die_int"

fun find_keep_lines_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, at: int, cur: int, n: int
): int =
  if recfuel > 0 then (
    if ige(cur, n) then n
    else let
      val st = doc_line_start(d, cur)
    in
      if ile(st, at) then find_keep_lines_m(recfuel - 1, d, at, iadd(cur, 1), n)
      else cur
    end
  ) else find_keep_exh(d, at, cur, n)

extern fun find_tail_exh(d: !Doc, max_del: int, cur: int, n: int): int = "mac#anth_die_int"

fun find_tail_line_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, max_del: int, cur: int, n: int
): int =
  if recfuel > 0 then (
    if ige(cur, n) then n
    else let
      val st = doc_line_start(d, cur)
    in
      if ile(st, max_del) then find_tail_line_m(recfuel - 1, d, max_del, iadd(cur, 1), n)
      else cur
    end
  ) else find_tail_exh(d, max_del, cur, n)

extern fun count_edit_exh(d: !Doc, j: int, en: int, cnt: int): int = "mac#anth_die_int"

fun count_edit_nls_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, j: int, en: int, cnt: int
): int =
  if recfuel > 0 then (
    if ige(j, en) then cnt
    else let
      val b = doc_byte(d, j)
      val nxt_cnt = (if ieq(b, 10) then iadd(cnt, 1) else cnt)
    in
      count_edit_nls_m(recfuel - 1, d, iadd(j, 1), en, nxt_cnt)
    end
  ) else count_edit_exh(d, j, en, cnt)

extern fun shift_lines_exh(d: !Doc, cur: int, n: int, delta: int): void = "mac#anth_die_void"

fun shift_lines_inplace_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, cur: int, n: int, delta: int
): void =
  if recfuel > 0 then (
    if ige(cur, n) then ()
    else let
      val st = doc_line_start(d, cur)
      val () = d_line_set(d, cur, iadd(st, delta))
    in
      shift_lines_inplace_m(recfuel - 1, d, iadd(cur, 1), n, delta)
    end
  ) else shift_lines_exh(d, cur, n, delta)

extern fun copy_keep_exh(d: !Doc, dst: !Buf, cur: int, n: int): void = "mac#anth_die_void"

fun copy_keep_lines_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, dst: !Buf, cur: int, n: int
): void =
  if recfuel > 0 then (
    if ige(cur, n) then ()
    else let
      val st = doc_line_start(d, cur)
      val () = buf_set32(dst, cur, st)
    in
      copy_keep_lines_m(recfuel - 1, d, dst, iadd(cur, 1), n)
    end
  ) else copy_keep_exh(d, dst, cur, n)

extern fun scan_add_edit_exh(d: !Doc, j: int, en: int, dst: !Buf, cur_idx: int): int = "mac#anth_die_int"

fun scan_add_edit_nls_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, j: int, en: int, dst: !Buf, cur_idx: int
): int =
  if recfuel > 0 then (
    if ige(j, en) then cur_idx
    else let
      val b = doc_byte(d, j)
    in
      if ieq(b, 10) then let
        val () = buf_set32(dst, cur_idx, iadd(j, 1))
      in
        scan_add_edit_nls_m(recfuel - 1, d, iadd(j, 1), en, dst, iadd(cur_idx, 1))
      end else scan_add_edit_nls_m(recfuel - 1, d, iadd(j, 1), en, dst, cur_idx)
    end
  ) else scan_add_edit_exh(d, j, en, dst, cur_idx)

extern fun copy_tail_exh(d: !Doc, cur: int, n: int, dst: !Buf, cur_idx: int, delta: int): void = "mac#anth_die_void"

fun copy_tail_shifted_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, cur: int, n: int, dst: !Buf, cur_idx: int, delta: int
): void =
  if recfuel > 0 then (
    if ige(cur, n) then ()
    else let
      val st = doc_line_start(d, cur)
      val () = buf_set32(dst, cur_idx, iadd(st, delta))
    in
      copy_tail_shifted_m(recfuel - 1, d, iadd(cur, 1), n, dst, iadd(cur_idx, 1), delta)
    end
  ) else copy_tail_exh(d, cur, n, dst, cur_idx, delta)

fun lines_apply_splice(
  d: !Doc, keep: int, tail: int, old_n: int, added: int, delta: int, at: int, newlen: int
): void = let
  val deleted = isub(tail, keep)
  val new_n = isub(iadd(old_n, added), deleted)
  var new_b = buf_make(imax(4096, imul(iadd(new_n, 4), 4)))
  val () = copy_keep_lines_m(airlock_nat(MAX_REC_FUEL), d, new_b, 0, keep)
  val after_nl = scan_add_edit_nls_m(airlock_nat(MAX_REC_FUEL), d, at, iadd(at, newlen), new_b, keep)
  val () = copy_tail_shifted_m(airlock_nat(MAX_REC_FUEL), d, tail, old_n, new_b, after_nl, delta)
  val () = d_lines_replace(d, new_b)
in
  d_set_nlines(d, new_n)
end

implement lines_apply_edit(d, at, oldlen, newlen) = let
  val old_n = d_nlines(d)
in
  if ile(old_n, 0) then rebuild_lines(d)
  else let
    val delta = isub(newlen, oldlen)
    val l0 = doc_line_of(d, at)
    val keep = find_keep_lines_m(airlock_nat(MAX_REC_FUEL), d, at, l0, old_n)
    val max_del = iadd(at, oldlen)
    val tail = find_tail_line_m(airlock_nat(MAX_REC_FUEL), d, max_del, keep, old_n)
    val added = count_edit_nls_m(airlock_nat(MAX_REC_FUEL), d, at, iadd(at, newlen), 0)
    val deleted = isub(tail, keep)
  in
    if ieq(deleted, 0) andalso ieq(added, 0) then (
      if ine(delta, 0) then shift_lines_inplace_m(airlock_nat(MAX_REC_FUEL), d, tail, old_n, delta)
      else ()
    ) else lines_apply_splice(d, keep, tail, old_n, added, delta, at, newlen)
  end
end

fun nget(d: !Doc, i: int, f: int): int =
  case+ d of
  | @DOC(s) => let
      val v = buf_get32(s.nodes, iadd(imul(i, NS), f))
    in
      fold@(d); v
    end

fun nset(d: !Doc, i: int, f: int, v: int): void =
  case+ d of
  | @DOC(s) => let
      val () = buf_set32(s.nodes, iadd(imul(i, NS), f), v)
    in
      fold@(d)
    end

fun kind_of_v2_tail(n: int): NodeKind =
  if ieq(n, 44) then KCalloutHead
  else if ieq(n, 45) then KTableRow
  else if ieq(n, 46) then KTableCell
  else if ieq(n, 47) then KTableDelim
  else if ieq(n, 48) then KLinkDest
  else if ieq(n, 49) then KLinkTitle
  else if ieq(n, 50) then KWikiTarget
  else if ieq(n, 51) then KWikiHeading
  else if ieq(n, 52) then KWikiBlock
  else if ieq(n, 53) then KWikiAlias
  else if ieq(n, 54) then KFnInline
  else if ieq(n, 55) then KMathBlock
  else if ieq(n, 90) then KDirective
  else KNone

fun kind_of_v2(n: int): NodeKind =
  if ieq(n, 32) then KMark
  else if ieq(n, 33) then KRaw
  else if ieq(n, 34) then KInfo
  else if ieq(n, 35) then KEscape
  else if ieq(n, 36) then KCodeSpan
  else if ieq(n, 37) then KUrl
  else if ieq(n, 38) then KHtmlBlock
  else if ieq(n, 39) then KHtmlInline
  else if ieq(n, 40) then KBreak
  else if ieq(n, 41) then KComment
  else if ieq(n, 42) then KBlockId
  else if ieq(n, 43) then KCallout
  else kind_of_v2_tail(n)

fun kind_of_tail(n: int): NodeKind =
  if ieq(n, 17) then KEmbed
  else if ieq(n, 18) then KTag
  else if ieq(n, 19) then KTask
  else if ieq(n, 20) then KFn
  else if ieq(n, 21) then KFndef
  else if ieq(n, 22) then KHigh
  else if ieq(n, 23) then KMath
  else if ieq(n, 24) then KMathb
  else if ieq(n, 25) then KFm
  else if ieq(n, 26) then KImage
  else if ieq(n, 27) then KTd
  else if ieq(n, 28) then KBold
  else if ieq(n, 29) then KItalic
  else if ieq(n, 30) then KStrike
  else if ieq(n, 31) then KLink
  else kind_of_v2(n)

implement kind_of(n) =
  if ieq(n, 1) then KPara
  else if ieq(n, 2) then KH1
  else if ieq(n, 3) then KH2
  else if ieq(n, 4) then KH3
  else if ieq(n, 5) then KH4
  else if ieq(n, 6) then KH5
  else if ieq(n, 7) then KH6
  else if ieq(n, 8) then KUl
  else if ieq(n, 9) then KOl
  else if ieq(n, 10) then KLi
  else if ieq(n, 11) then KQuote
  else if ieq(n, 12) then KCode
  else if ieq(n, 13) then KHr
  else if ieq(n, 14) then KTable
  else if ieq(n, 15) then KText
  else if ieq(n, 16) then KWiki
  else kind_of_tail(n)

implement kind_code(k) = case+ k of
  | KNone() => 0 | KPara() => 1 | KH1() => 2 | KH2() => 3
  | KH3() => 4 | KH4() => 5 | KH5() => 6 | KH6() => 7
  | KUl() => 8 | KOl() => 9 | KLi() => 10 | KQuote() => 11
  | KCode() => 12 | KHr() => 13 | KTable() => 14 | KText() => 15
  | KWiki() => 16 | KEmbed() => 17 | KTag() => 18 | KTask() => 19
  | KFn() => 20 | KFndef() => 21 | KHigh() => 22 | KMath() => 23
  | KMathb() => 24 | KFm() => 25 | KImage() => 26 | KTd() => 27
  | KBold() => 28 | KItalic() => 29 | KStrike() => 30 | KLink() => 31
  | KMark() => 32 | KRaw() => 33 | KInfo() => 34 | KEscape() => 35
  | KCodeSpan() => 36 | KUrl() => 37 | KHtmlBlock() => 38 | KHtmlInline() => 39
  | KBreak() => 40 | KComment() => 41 | KBlockId() => 42 | KCallout() => 43
  | KCalloutHead() => 44 | KTableRow() => 45 | KTableCell() => 46 | KTableDelim() => 47
  | KLinkDest() => 48 | KLinkTitle() => 49 | KWikiTarget() => 50 | KWikiHeading() => 51
  | KWikiBlock() => 52 | KWikiAlias() => 53 | KFnInline() => 54 | KMathBlock() => 55
  | KDirective() => 90

implement heading_kind(hashes) =
  if ieq(hashes, 1) then KH1
  else if ieq(hashes, 2) then KH2
  else if ieq(hashes, 3) then KH3
  else if ieq(hashes, 4) then KH4
  else if ieq(hashes, 5) then KH5
  else KH6

implement task_mark_of(c) =
  if ieq(c, 32) then TaskTodo
  else if ieq(c, 120) orelse ieq(c, 88) then TaskDone
  else if ieq(c, 47) then TaskProgress
  else TaskOther

implement task_next_mark(m) = case+ m of
  | TaskTodo() => TaskDone
  | TaskDone() => TaskProgress
  | TaskProgress() => TaskTodo
  | TaskOther() => TaskTodo

implement task_mark_byte(m) = case+ m of
  | TaskTodo() => 32
  | TaskDone() => 120
  | TaskProgress() => 47
  | TaskOther() => 32

implement task_aux_code(m) = case+ m of
  | TaskDone() => 1
  | TaskProgress() => 2
  | TaskTodo() => 0
  | TaskOther() => 0

implement is_kind(k, expect) = ieq(kind_code(k), kind_code(expect))

implement is_heading(k) = case+ k of
  | KH1() => true | KH2() => true | KH3() => true | KH4() => true
  | KH5() => true | KH6() => true | KNone() => false | KPara() => false
  | KUl() => false | KOl() => false | KLi() => false | KQuote() => false
  | KCode() => false | KHr() => false | KTable() => false | KText() => false
  | KWiki() => false | KEmbed() => false | KTag() => false | KTask() => false
  | KFn() => false | KFndef() => false | KHigh() => false | KMath() => false
  | KMathb() => false | KFm() => false | KImage() => false | KTd() => false
  | KBold() => false | KItalic() => false | KStrike() => false | KLink() => false
  | KMark() => false | KRaw() => false | KInfo() => false | KEscape() => false
  | KCodeSpan() => false | KUrl() => false | KHtmlBlock() => false | KHtmlInline() => false
  | KBreak() => false | KComment() => false | KBlockId() => false | KCallout() => false
  | KCalloutHead() => false | KTableRow() => false | KTableCell() => false | KTableDelim() => false
  | KLinkDest() => false | KLinkTitle() => false | KWikiTarget() => false | KWikiHeading() => false
  | KWikiBlock() => false | KWikiAlias() => false | KFnInline() => false | KMathBlock() => false
  | KDirective() => false

implement is_inline(k) = case+ k of
  | KText() => true | KWiki() => true | KEmbed() => true | KTag() => true
  | KFn() => true | KHigh() => true | KMath() => true | KMathb() => true
  | KTd() => true | KBold() => true | KItalic() => true | KStrike() => true | KLink() => true
  | KMark() => true | KRaw() => true | KInfo() => true | KEscape() => true
  | KCodeSpan() => true | KUrl() => true | KHtmlInline() => true | KBreak() => true
  | KComment() => true | KBlockId() => true | KLinkDest() => true
  | KLinkTitle() => true | KWikiTarget() => true | KWikiHeading() => true
  | KWikiBlock() => true | KWikiAlias() => true | KFnInline() => true
  | KNone() => false | KPara() => false | KH1() => false
  | KH2() => false | KH3() => false | KH4() => false | KH5() => false
  | KH6() => false | KUl() => false | KOl() => false | KLi() => false
  | KQuote() => false | KCode() => false | KHr() => false | KTable() => false
  | KTask() => false | KFndef() => false | KFm() => false | KImage() => false
  | KHtmlBlock() => false | KCallout() => false | KCalloutHead() => false
  | KTableRow() => false | KTableCell() => false | KTableDelim() => false
  | KMathBlock() => false | KDirective() => false

implement heading_stops(k, limit) =
  is_heading(k) andalso ile(kind_code(k), kind_code(limit))

fun style_bit(k: NodeKind): int =
  if is_kind(k, KBold) then STYLE_BOLD
  else if is_kind(k, KItalic) then STYLE_ITALIC
  else if is_kind(k, KStrike) then STYLE_STRIKE
  else if is_kind(k, KHigh) then STYLE_HIGH
  else if is_kind(k, KLink) orelse is_kind(k, KWiki) orelse is_kind(k, KUrl) then STYLE_LINK
  else if is_kind(k, KCode) orelse is_kind(k, KCodeSpan) then STYLE_CODE
  else if is_kind(k, KMath) orelse is_kind(k, KMathb) orelse is_kind(k, KMathBlock) then STYLE_MATH
  else if is_heading(k) then STYLE_HEADING
  else if is_kind(k, KQuote) orelse is_kind(k, KCallout) then STYLE_QUOTE
  else 0

fun lor_int(a: int, b: int): int =
  g0uint2int_uint_int(g0uint_lor(g0int2uint_int_uint(a), g0int2uint_int_uint(b)))

fun iand(a: int, n: int): int = anth_iand(a, n)

extern fun ast_style_exh(d: !Doc, cur: int, acc: int): int = "mac#anth_die_int"

fun ast_style_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, cur: int, acc: int): int =
  if recfuel > 0 then (
    if cur < 0 then acc
    else let
      val k = doc_node_kind(d, cur)
      val fl = doc_node_flags(d, cur)
      val bit = style_bit(k)
      val err_bit = (if iand(fl, FL_ERROR) != 0 then STYLE_ERROR else 0)
      val p = doc_node_parent(d, cur)
      val n_acc = lor_int(acc, lor_int(bit, err_bit))
    in
      ast_style_m(recfuel - 1, d, p, n_acc)
    end
  ) else ast_style_exh(d, cur, acc)

implement ast_style(d, i) = let
  val self_fl = doc_node_flags(d, i)
  val init_err = (if iand(self_fl, FL_ERROR) != 0 then STYLE_ERROR else 0)
in
  ast_style_m(airlock_nat(MAX_REC_FUEL), d, doc_node_parent(d, i), init_err)
end

implement doc_node_kind(d, i) = kind_of(nget(d, i, NF_KIND))
implement doc_node_start(d, i) = nget(d, i, NF_START)
implement doc_node_end(d, i) = nget(d, i, NF_END)
implement doc_node_depth(d, i) = nget(d, i, NF_DEPTH)
implement doc_node_collapsed(d, i) = toggle_of(ieq(nget(d, i, NF_COLLAPSED), 1))
implement doc_node_height(d, i) =
  case+ d of
  | @DOC(s) => let
      val h = layout_node_height(s.lay, i, s.nlines)
    in
      fold@(d); h
    end
implement doc_node_parent(d, i) = nget(d, i, NF_PARENT)
implement doc_node_hidden(d, i) = toggle_of(ieq(nget(d, i, NF_HIDDEN), 1))
implement doc_node_aux(d, i) = nget(d, i, NF_AUX)
implement doc_node_y(d, i) =
  case+ d of
  | @DOC(s) => let
      val y = layout_node_y(s.lay, i, s.nlines)
    in
      fold@(d); y
    end

implement doc_node_first_child(d, i) = nget(d, i, NF_FIRST_CHILD)
implement doc_node_next_sib(d, i) = nget(d, i, NF_NEXT_SIB)
implement doc_node_cstart(d, i) = nget(d, i, NF_CSTART)
implement doc_node_cend(d, i) = nget(d, i, NF_CEND)
implement doc_node_subend(d, i) = nget(d, i, NF_SUBEND)
implement doc_node_flags(d, i) = nget(d, i, NF_FLAGS)

fun doc_node_set_collapsed(d: !Doc, i: int, v: Toggle): void = nset(d, i, NF_COLLAPSED, toggle_int(v))
fun doc_node_set_height(d: !Doc, i: int, h: int): void = let
  val line_count = d_nlines(d)
  val () = ensure_layout_capacity(d, layout_node_need(i, line_count))
  val laybuf0 = take_layout(d)
  var laybuf = laybuf0
  val () = layout_node_put_height(laybuf, i, h, line_count)
in
  put_layout(d, laybuf)
end
fun doc_node_set_parent(d: !Doc, i: int, p: int): void = nset(d, i, NF_PARENT, p)
fun doc_node_set_next_sib(d: !Doc, i: int, s: int): void = nset(d, i, NF_NEXT_SIB, s)
fun doc_node_set_first_child(d: !Doc, i: int, c: int): void = nset(d, i, NF_FIRST_CHILD, c)
fun doc_node_set_hidden(d: !Doc, i: int, v: Toggle): void = nset(d, i, NF_HIDDEN, toggle_int(v))
fun doc_node_set_y(d: !Doc, i: int, y: int): void = let
  val line_count = d_nlines(d)
  val () = ensure_layout_capacity(d, layout_node_need(i, line_count))
  val laybuf0 = take_layout(d)
  var laybuf = laybuf0
  val () = layout_node_put_y(laybuf, i, y, line_count)
in
  put_layout(d, laybuf)
end

implement doc_layout_store_node_y(d, node, y) =
  doc_node_set_y(d, node, y)

implement doc_get(d, i, f) =
  if ieq(f, NF_HEIGHT) then doc_node_height(d, i)
  else if ieq(f, NF_Y) then doc_node_y(d, i)
  else nget(d, i, f)

implement doc_set(d, i, f, v) =
  if ieq(f, NF_HEIGHT) then doc_node_set_height(d, i, v)
  else if ieq(f, NF_Y) then doc_node_set_y(d, i, v)
  else nset(d, i, f, v)

fun node_room(d: !Doc): void =
  case+ d of
  | @DOC(s) => let
      val need = imul(iadd(s.nnodes, 2), NS * 4)
      val () = if buf_cap(s.nodes) < need then buf_resize(s.nodes, imul(need, 2)) else ()
    in
      fold@(d)
    end

extern fun zero_node_exh(d: !Doc, i: int, f: int): void = "mac#anth_die_void"

fun zero_node_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, f: int): void =
  if recfuel > 0 then (
    if f < NS then let
      val () = nset(d, i, f, 0)
    in
      zero_node_m(recfuel - 1, d, i, iadd(f, 1))
    end else ()
  ) else zero_node_exh(d, i, f)

fun npush(d: !Doc, kind: NodeKind, st: int, en: int, depth: int, aux: int): void = let
  val () = node_room(d)
  val i = d_nnodes(d)
  val () = zero_node_m(airlock_nat(MAX_REC_FUEL), d, i, 0)
  val () = nset(d, i, NF_KIND, kind_code(kind))
  val () = nset(d, i, NF_START, st)
  val () = nset(d, i, NF_END, en)
  val () = nset(d, i, NF_DEPTH, depth)
  val () = doc_node_set_parent(d, i, ~1)
  val () = doc_node_set_next_sib(d, i, ~1)
  val () = doc_node_set_first_child(d, i, ~1)
  val () = nset(d, i, NF_AUX, aux)
  val () = d_set_nnodes(d, iadd(i, 1))
in
end

implement doc_push_node(d, kind, st, en, depth, aux) =
  npush(d, kind, st, en, depth, aux)

implement doc_node_add(d, kind, st, en, parent, prev_sib, aux, flags) = let
  val n = d_nnodes(d)
  val len = d_len(d)
in
  if st < 0 orelse st >= en orelse en > len orelse n >= MAX_NODES then ~1
  else let
    val dp = (if parent >= 0 then iadd(doc_node_depth(d, parent), 1) else 0)
    val () = npush(d, kind, st, en, dp, aux)
    val () = nset(d, n, NF_CSTART, st)
    val () = nset(d, n, NF_CEND, en)
    val () = nset(d, n, NF_PARENT, parent)
    val () = nset(d, n, NF_SUBEND, iadd(n, 1))
    val () = nset(d, n, NF_FLAGS, flags)
    val () =
      if prev_sib >= 0 then nset(d, prev_sib, NF_NEXT_SIB, n)
      else if parent >= 0 then nset(d, parent, NF_FIRST_CHILD, n)
      else ()
  in
    n
  end
end

implement doc_node_close(d, i, en, cs, ce) = let
  val n = d_nnodes(d)
in
  if i < 0 orelse i >= n then ()
  else let
    val () = nset(d, i, NF_END, en)
    val () = nset(d, i, NF_CSTART, cs)
    val () = nset(d, i, NF_CEND, ce)
    val () = nset(d, i, NF_SUBEND, n)
  in
  end
end

extern fun doc_find_child_exh(d: !Doc, c: int, kind: NodeKind): int = "mac#anth_die_int"

fun doc_find_child_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, c: int, kind: NodeKind
): int =
  if recfuel > 0 then (
    if c < 0 orelse c >= d_nnodes(d) then ~1
    else if is_kind(doc_node_kind(d, c), kind) then c
    else doc_find_child_m(recfuel - 1, d, doc_node_next_sib(d, c), kind)
  ) else doc_find_child_exh(d, c, kind)

implement doc_find_child(d, i, kind) = let
  val n = d_nnodes(d)
in
  if i < 0 orelse i >= n then ~1
  else let
    val fc = doc_node_first_child(d, i)
  in
    doc_find_child_m(airlock_nat(MAX_REC_FUEL), d, fc, kind)
  end
end

implement doc_ver(d) = d_ver(d)

implement doc_layout_version(d) = d_ver(d)

implement doc_layout_cache_match(d, version, key, mode) =
  case+ d of
  | @DOC(s) => let
      val hit = layout_cache_matches(s.lay, version, key, mode)
    in
      fold@(d); hit
    end

implement doc_layout_cache_height(d) =
  case+ d of
  | @DOC(s) => let
      val height = layout_cache_height(s.lay)
    in
      fold@(d); height
    end

implement doc_layout_cache_store(d, version, key, height, mode, wrap) =
  case+ d of
  | @DOC(s) => let
      val () = layout_cache_store(s.lay, version, key, height, mode, wrap)
    in
      fold@(d)
    end

implement doc_layout_cached_wrap(d) =
  case+ d of
  | @DOC(s) => let
      val wrap = layout_wrap(s.lay)
    in
      fold@(d); wrap
    end

implement doc_clear_nodes(d) =
  case+ d of
  | @DOC(s) => let
      val b = s.nodes
      val () = buf_set_len(b, 0)
      val () = s.nodes := b
      val () = s.nnodes := 0
    in
      fold@(d)
    end

extern fun fold_apply_exh(d: !Doc, i: int, n: int): void = "mac#anth_die_void"

fun fold_apply_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, n: int
): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val k = doc_node_kind(d, i)
      val () = if is_heading(k) then let
        val st = doc_node_start(d, i)
        val col = if fold_has(d, st) then On else Off
      in
        doc_node_set_collapsed(d, i, col)
      end else ()
    in
      fold_apply_m(recfuel - 1, d, iadd(i, 1), n)
    end
  ) else fold_apply_exh(d, i, n)

fun fold_apply(d: !Doc): void =
  fold_apply_m(airlock_nat(MAX_REC_FUEL), d, 0, d_nnodes(d))

extern fun hide_until_exh(d: !Doc, i: int, n: int, hk: NodeKind): void = "mac#anth_die_void"

fun hide_until_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, n: int, hk: NodeKind): void =
  if recfuel > 0 then (
    if ige(i, n) then ()
    else let
      val k = doc_node_kind(d, i)
    in
      if heading_stops(k, hk) then ()
      else let
        val () = doc_node_set_hidden(d, i, On)
        val () = doc_node_set_height(d, i, 0)
      in
        hide_until_m(recfuel - 1, d, iadd(i, 1), n, hk)
      end
    end
  ) else hide_until_exh(d, i, n, hk)

fun hide_until(d: !Doc, i: int, n: int, hk: NodeKind): void = hide_until_m(airlock_nat(MAX_REC_FUEL), d, i, n, hk)

extern fun hide_list_exh(d: !Doc, i: int, n: int, depth: int): void = "mac#anth_die_void"

fun hide_list_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, n: int, depth: int): void =
  if recfuel > 0 then (
    if ige(i, n) then ()
    else let
      val k = doc_node_kind(d, i)
      val dp = doc_node_depth(d, i)
    in
      if (is_kind(k, KLi) orelse is_kind(k, KTask) orelse is_kind(k, KUl) orelse is_kind(k, KOl)) andalso ile(dp, depth) then ()
      else if not(is_inline(k)) andalso ile(dp, depth) andalso not(is_kind(k, KText)) then ()
      else let
        val () = doc_node_set_hidden(d, i, On)
        val () = doc_node_set_height(d, i, 0)
      in
        hide_list_m(recfuel - 1, d, iadd(i, 1), n, depth)
      end
    end
  ) else hide_list_exh(d, i, n, depth)

fun hide_list(d: !Doc, i: int, n: int, depth: int): void = hide_list_m(airlock_nat(MAX_REC_FUEL), d, i, n, depth)

extern fun count_nl_exh(d: !Doc, p: int, en: int, lines: int): int = "mac#anth_die_int"

fun count_nl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: int, en: int, lines: int): int =
  if recfuel > 0 then (
    if ige(p, en) then lines
    else count_nl_m(recfuel - 1, d, iadd(p, 1), en, (if ieq(doc_byte(d, p), 10) then iadd(lines, 1) else lines))
  ) else count_nl_exh(d, p, en, lines)

fun count_nl(d: !Doc, p: int, en: int, lines: int): int = count_nl_m(airlock_nat(MAX_REC_FUEL), d, p, en, lines)

extern fun clear_hide_exh(d: !Doc, n: int, i: int): void = "mac#anth_die_void"

fun clear_hide_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, n: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, n) then ()
    else let
      val () = doc_node_set_hidden(d, i, Off)
    in
      clear_hide_m(recfuel - 1, d, n, iadd(i, 1))
    end
  ) else clear_hide_exh(d, n, i)

fun clear_hide(d: !Doc, n: int, i: int): void = clear_hide_m(airlock_nat(MAX_REC_FUEL), d, n, i)

fun node_height(d: !Doc, i: int, lh: int): int = let
  val k = doc_node_kind(d, i)
  val lines = count_nl(d, doc_node_start(d, i), doc_node_end(d, i), 1)
in
  if is_on(doc_node_hidden(d, i)) then 0
  else if is_kind(k, KEmbed) then let
    val a = doc_node_height(d, i)
  in
    if igt(a, 8) then a else 0
  end
  else if is_inline(k) then 0
  else if is_kind(k, KHr) then 12
  else if is_kind(k, KImage) then let
    val a = doc_node_height(d, i)
  in
    if igt(a, 8) then a else 96
  end
  else imul(lines, lh)
end

extern fun place_one_exh(d: !Doc, n: int, i: int, lh: int): void = "mac#anth_die_void"

fun place_one_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, n: int, i: int, lh: int): void =
  if recfuel > 0 then (
    if ige(i, n) then ()
    else let
      val k = doc_node_kind(d, i)
      val h = node_height(d, i, lh)
      val () = doc_node_set_height(d, i, h)
      val () =
        if is_heading(k) andalso is_on(doc_node_collapsed(d, i)) then hide_until(d, iadd(i, 1), n, k)
        else if (is_kind(k, KLi) orelse is_kind(k, KTask)) andalso is_on(doc_node_collapsed(d, i)) then hide_list(d, iadd(i, 1), n, doc_node_depth(d, i))
        else ()
    in
      place_one_m(recfuel - 1, d, n, iadd(i, 1), lh)
    end
  ) else place_one_exh(d, n, i, lh)

fun place_one(d: !Doc, n: int, i: int, lh: int): void = place_one_m(airlock_nat(MAX_REC_FUEL), d, n, i, lh)

implement doc_layout_ast_prepare(d, line_height) = let
  val nodes = d_nnodes(d)
  val () = clear_hide(d, nodes, 0)
in
  place_one(d, nodes, 0, line_height)
end

extern fun line_hidden_exh(d: !Doc, st: int, en: int, i: int, n: int, saw: Toggle): int = "mac#anth_die_int"

fun heading_stop_offset_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, n: int, hk: NodeKind
): int =
  if recfuel > 0 then (
    if ige(i, n) then d_len(d)
    else let
      val k = doc_node_kind(d, i)
    in
      if heading_stops(k, hk) then doc_node_start(d, i)
      else heading_stop_offset_m(recfuel - 1, d, iadd(i, 1), n, hk)
    end
  ) else d_len(d)

fun heading_section_hidden_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, st: int, i: int, n: int
): int =
  if recfuel > 0 then (
    if ige(i, n) then 0
    else let
      val k = doc_node_kind(d, i)
    in
      if is_heading(k) andalso is_on(doc_node_collapsed(d, i)) then let
        val h_end = doc_node_end(d, i)
        val stop = heading_stop_offset_m(airlock_nat(MAX_REC_FUEL), d, iadd(i, 1), n, k)
      in
        if ige(st, h_end) andalso ilt(st, stop) then 1
        else heading_section_hidden_m(recfuel - 1, d, st, iadd(i, 1), n)
      end
      else heading_section_hidden_m(recfuel - 1, d, st, iadd(i, 1), n)
    end
  ) else 0

fun line_hidden_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, st: int, en: int, i: int, n: int, saw: Toggle): int =
  if recfuel > 0 then (
    if ige(i, n) then (
      if is_on(saw) then 1
      else heading_section_hidden_m(airlock_nat(MAX_REC_FUEL), d, st, 0, n)
    ) else let
      val ns = doc_node_start(d, i)
      val ne = doc_node_end(d, i)
      val hit = ilt(ns, en) andalso igt(ne, st)
    in
      if hit andalso is_off(doc_node_hidden(d, i)) then 0
      else line_hidden_m(recfuel - 1, d, st, en, iadd(i, 1), n, if hit then On else saw)
    end
  ) else line_hidden_exh(d, st, en, i, n, saw)

fun line_hidden(d: !Doc, st: int, en: int, i: int, n: int, saw: Toggle): int = line_hidden_m(airlock_nat(MAX_REC_FUEL), d, st, en, i, n, saw)

implement doc_layout_line_hidden(d, start, stop, node_count) =
  line_hidden(d, start, stop, 0, node_count, Off)

extern fun widget_h_exh(d: !Doc, st: int, en: int, i: int, n: int, acc: int): int = "mac#anth_die_int"

fun widget_h_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, st: int, en: int, i: int, n: int, acc: int): int =
  if recfuel > 0 then (
    if ige(i, n) then acc
    else let
      val k = doc_node_kind(d, i)
      val ns = doc_node_start(d, i)
      val h = doc_node_height(d, i)
      val is_widget = is_kind(k, KImage) orelse is_kind(k, KEmbed) orelse is_kind(k, KMathb)
      val wh = if is_kind(k, KMathb) andalso ieq(h, 0) then 24 else h
      val use = if is_off(doc_node_hidden(d, i)) andalso ige(ns, st) andalso ilt(ns, en) andalso is_widget andalso igt(wh, acc) then wh else acc
    in
      widget_h_m(recfuel - 1, d, st, en, iadd(i, 1), n, use)
    end
  ) else widget_h_exh(d, st, en, i, n, acc)

fun widget_h(d: !Doc, st: int, en: int, i: int, n: int, acc: int): int = widget_h_m(airlock_nat(MAX_REC_FUEL), d, st, en, i, n, acc)

implement doc_layout_widget_height(d, start, stop, node_count) =
  widget_h(d, start, stop, 0, node_count, 0)

fun line_heading_extra(k: NodeKind, lh: int): int =
  if is_kind(k, KH1) then iadd(idiv(imul(lh, 3), 4), 24)
  else if is_kind(k, KH2) then iadd(idiv(lh, 2), 18)
  else if is_kind(k, KH3) then iadd(idiv(lh, 4), 14)
  else if is_kind(k, KH4) then 12
  else if is_kind(k, KH5) then 8
  else 0

extern fun line_heading_pad_exh(d: !Doc, st: int, en: int, i: int, n: int, lh: int, acc: int): int = "mac#anth_die_int"

fun line_heading_pad_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, st: int, en: int, i: int, n: int, lh: int, acc: int
): int =
  if recfuel > 0 then (
    if ige(i, n) then acc
    else let
      val k = doc_node_kind(d, i)
      val ns = doc_node_start(d, i)
      val ex = if ige(ns, st) andalso ilt(ns, en) then line_heading_extra(k, lh) else 0
    in
      line_heading_pad_m(recfuel - 1, d, st, en, iadd(i, 1), n, lh, imax(acc, ex))
    end
  ) else line_heading_pad_exh(d, st, en, i, n, lh, acc)

fun line_heading_pad(d: !Doc, st: int, en: int, i: int, n: int, lh: int): int =
  line_heading_pad_m(airlock_nat(MAX_REC_FUEL), d, st, en, i, n, lh, 0)

implement doc_layout_heading_padding(d, start, stop, node_count, line_height) =
  line_heading_pad(d, start, stop, 0, node_count, line_height)

fun reparse(d: !Doc, at: int, oldlen: int): void = let
  val curlen = d_len(d)
  val delta = isub(curlen, oldlen)
  val del_bytes = (if ilt(delta, 0) then isub(0, delta) else 0)
  val ins_bytes = (if igt(delta, 0) then delta else 0)
  val () = lines_apply_edit(d, at, del_bytes, ins_bytes)
  val () = ast_reparse_v2(d, at, del_bytes, ins_bytes)
in
  fold_apply(d)
end

extern fun gap_put_exh(d: !Doc, p: ptr, n: int, lo: int, i: int): void = "mac#anth_die_void"

fun gap_put_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: ptr, n: int, lo: int, i: int): void =
  if recfuel > 0 then (
    if i < n then let
      val () = gap_set(d, iadd(lo, i), mem_byte(p, n, i))
    in
      gap_put_m(recfuel - 1, d, p, n, lo, iadd(i, 1))
    end else ()
  ) else gap_put_exh(d, p, n, lo, i)

fun gap_put(d: !Doc, p: ptr, n: int): void = let
  val () = gap_room(d, n)
  val lo = d_lo(d)
  val () = gap_put_m(airlock_nat(MAX_REC_FUEL), d, p, n, lo, 0)
in
  d_set_lo(d, iadd(lo, n));
  d_set_len(d, iadd(d_len(d), n))
end

fun sel_span(d: !Doc, a: &int >> _, b: &int >> _): void = let
  val c = d_caret(d)
  val k = d_anchor(d)
in
  if c < k then (a := c; b := k) else (a := k; b := c)
end

fun remove_between(d: !Doc, a0: int, b0: int): void = let
  val len = d_len(d)
  val a = if a0 < 0 then 0 else a0
  val b = if b0 > len then len else b0
in
  if ile(b, a) then ()
  else let
    val old = d_len(d)
    val () = gap_move(d, a)
    val hi = d_hi(d)
    val () = d_set_hi(d, iadd(hi, isub(b, a)))
    val () = d_set_len(d, isub(len, isub(b, a)))
    val () = d_set_caret(d, a)
    val () = d_set_anchor(d, a)
    val () = d_bump_ver(d)
    val () = fold_shift(d, a, isub(a, b))
  in
    reparse(d, a, old)
  end
end

fun doc_gap_copy_to_ptr(d: !Doc, src_off: int, dst: ptr, dst_cap: int, dst_off: int, n: int): void =
  case+ d of
  | @DOC(s) => let
      val () = buf_copy_to_ptr(s.gap, src_off, dst, dst_cap, dst_off, n)
    in
      fold@(d)
    end

fun doc_gap_copy_to_buf(d: !Doc, src_off: int, dst: !Buf, dst_off: int, n: int): void =
  case+ d of
  | @DOC(s) => let
      val () = buf_copy_range(dst, dst_off, s.gap, src_off, n)
    in
      fold@(d)
    end

fun doc_slice_calc(d: !Doc, a: int, n: int, dst: ptr, cap: int): void = let
  val lo = d_lo(d)
  val hi = d_hi(d)
in
  if ilt(a, lo) then let
    val l1 = imin(n, isub(lo, a))
    val () = doc_gap_copy_to_ptr(d, a, dst, cap, 0, l1)
    val () = if igt(n, l1) then let
      val l2 = isub(n, l1)
      val () = doc_gap_copy_to_ptr(d, hi, dst, cap, l1, l2)
    in
    end else ()
  in
  end else let
    val s2 = iadd(hi, isub(a, lo))
    val () = doc_gap_copy_to_ptr(d, s2, dst, cap, 0, n)
  in
  end
end

implement doc_slice(d, a0, b0, dst, cap) = let
  val len = d_len(d)
  val a = if a0 < 0 then 0 else a0
  val b = if b0 > len then len else b0
  val n = if igt(isub(b, a), cap) then cap else isub(b, a)
  val () = if igt(n, 0) then doc_slice_calc(d, a, n, dst, cap) else ()
in
  n
end

implement doc_slice_buf(d, a, b, dst, cap) =
  doc_slice(d, a, b, buf_ptr(dst), cap)

implement doc_text(d, dst) = let
  val n = d_len(d)
  val () = buf_resize(dst, iadd(n, 1))
  val lo = d_lo(d)
  val hi = d_hi(d)
  val () = if igt(lo, 0) then doc_gap_copy_to_buf(d, 0, dst, 0, lo) else ()
  val tail = isub(n, lo)
  val () = if igt(tail, 0) then doc_gap_copy_to_buf(d, hi, dst, lo, tail) else ()
  val () = buf_set(dst, n, 0)
in
  buf_set_len(dst, n)
end

fun doc_snapshot_curr(d: !Doc): Buf = let
  var b = buf_make(iadd(doc_len(d), 1))
  val () = doc_text(d, b)
in
  b
end

fun get_last_op(d: !Doc): EditOp =
  case+ d of
  | @DOC(s) => let
      val o = s.last_op
    in
      fold@(d); o
    end

fun get_typing_cnt(d: !Doc): int =
  case+ d of
  | @DOC(s) => let
      val c = s.typing_cnt
    in
      fold@(d); c
    end

fun set_typing_cnt(d: !Doc, c: int): void =
  case+ d of
  | @DOC(s) => let
      val () = s.typing_cnt := c
    in
      fold@(d)
    end

fun set_last_op_and_reset_count(d: !Doc, opk: EditOp): void =
  case+ d of
  | @DOC(s) => let
      val () = s.last_op := opk
      val () = s.typing_cnt := 0
    in
      fold@(d)
    end

fun push_undo_current(d: !Doc): void = let
  val snap = doc_snapshot_curr(d)
  val cur_c = doc_caret(d)
  var u = take_uhist(d)
  val u2 = hist_trim(u)
  val u3 = HCons(snap, cur_c, u2)
in
  put_uhist(d, u3)
end

fun push_redo_current(d: !Doc): void = let
  val cur_snap = doc_snapshot_curr(d)
  val cur_c = doc_caret(d)
  var r = take_rhist(d)
  val r2 = hist_trim(r)
  val r3 = HCons(cur_snap, cur_c, r2)
in
  put_rhist(d, r3)
end

fun doc_record(d: !Doc, opk: EditOp): void = let
  val lo = get_last_op(d)
  val tc = get_typing_cnt(d)
in
  if is_op(opk, OpChar) andalso is_op(lo, OpChar) andalso ilt(tc, 8) then set_typing_cnt(d, iadd(tc, 1))
  else let
    val () = push_undo_current(d)
    val () = put_rhist(d, HNil())
    val () = set_last_op_and_reset_count(d, opk)
  in
  end
end

fun doc_insert_reparse(d: !Doc, at: int, n: int, old: int, delta: int): void = let
  val () = lines_apply_edit(d, at, 0, n)
  val () = ast_reparse_v2(d, at, 0, n)
  val () = seen_int(old); val () = seen_int(delta)
in
  fold_apply(d)
end

fun doc_insert_core(d: !Doc, p: ptr, n: int): void = let
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
  val () = if igt(b, a) then remove_between(d, a, b) else ()
  val at = d_caret(d)
  val old = d_len(d)
  val () = gap_move(d, at)
  val () = gap_put(d, p, n)
  val () = d_set_caret(d, iadd(at, n))
  val () = d_set_anchor(d, iadd(at, n))
  val () = d_bump_ver(d)
  val () = fold_shift(d, at, n)
in
  doc_insert_reparse(d, at, n, old, isub(d_len(d), old))
end

implement doc_insert(d, p, n) = let
  val () = if ieq(n, 1) then let
      val b = mem_byte(p, 1, 0)
    in
      if ieq(b, 32) orelse ieq(b, 10) then doc_record(d, OpBreak) else doc_record(d, OpChar)
    end else doc_record(d, OpBreak)
in
  doc_insert_core(d, p, n)
end

implement doc_insert_buf(d, src, n) =
  doc_insert(d, buf_ptr(src), n)

extern fun utf8_back_exh(d: !Doc, k: int, limit: int): int = "mac#anth_die_int"

fun utf8_back {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, k: int, limit: int): int =
  if recfuel > 0 then (
    if ile(k, 0) then 0
    else if ile(limit, 0) then k
    else let
      val b = doc_byte(d, isub(k, 1))
    in
      if b < 128 orelse b >= 192 then isub(k, 1)
      else utf8_back(recfuel - 1, d, isub(k, 1), isub(limit, 1))
    end
  ) else utf8_back_exh(d, k, limit)

fun utf8_prev(d: !Doc, i: int): int =
  if ile(i, 1) then 0
  else utf8_back(airlock_nat(MAX_REC_FUEL), d, i, 4)

fun utf8_align(d: !Doc, i: int): int =
  if ile(i, 0) then 0
  else if ige(i, d_len(d)) then d_len(d)
  else let
    val b = doc_byte(d, i)
  in
    if b < 128 orelse b >= 192 then i
    else utf8_prev(d, iadd(i, 1))
  end

fun utf8_next(d: !Doc, i: int): int = let
  val len = d_len(d)
in
  if ige(i, len) then len
  else let
    val b = doc_byte(d, i)
    val s = if ilt(b, 128) then 1 else if ilt(b, 224) then 2 else if ilt(b, 240) then 3 else 4
    val j = iadd(i, s)
  in
    if igt(j, len) then len else j
  end
end

implement doc_delete_range(d, start, finish) = let
  val a=imax(0,imin(doc_len(d),start))
  val b=imax(a,imin(doc_len(d),finish))
in if igt(b,a) then let val ()=doc_record(d,OpBreak)
  in remove_between(d,a,b) end else () end

implement doc_backspace(d) = let
  val () = doc_record(d, OpBreak)
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
in
  if igt(b, a) then remove_between(d, a, b)
  else let
    val c = d_caret(d)
  in
    if c <= 0 then () else remove_between(d, utf8_prev(d, c), c)
  end
end

implement doc_delete(d) = let
  val () = doc_record(d, OpBreak)
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
in
  if igt(b, a) then remove_between(d, a, b)
  else let
    val c = d_caret(d)
    val n = utf8_next(d, c)
  in
    if ile(n, c) then () else remove_between(d, c, n)
  end
end

implement doc_set_caret_move(d, i) = let
  val len = d_len(d)
  val c = if i < 0 then 0 else if i > len then len else i
  val () = d_set_caret(d, c)
in
  d_set_anchor(d, c)
end

implement doc_set_caret_extend(d, i) = let
  val len = d_len(d)
  val c = if i < 0 then 0 else if i > len then len else i
in
  d_set_caret(d, c)
end

fun doc_left_target(d: !Doc, keep: Toggle): int = let
  val c = d_caret(d)
  val a = d_anchor(d)
in
  if is_off(keep) andalso ine(c, a) then imin(c, a) else utf8_prev(d, c)
end

fun doc_right_target(d: !Doc, keep: Toggle): int = let
  val c = d_caret(d)
  val a = d_anchor(d)
in
  if is_off(keep) andalso ine(c, a) then imax(c, a) else utf8_next(d, c)
end

implement doc_left_move(d) = doc_set_caret_move(d, doc_left_target(d, Off))
implement doc_left_select(d) = doc_set_caret_extend(d, doc_left_target(d, On))

implement doc_right_move(d) = doc_set_caret_move(d, doc_right_target(d, Off))
implement doc_right_select(d) = doc_set_caret_extend(d, doc_right_target(d, On))

fun doc_home_target(d: !Doc): int =
  doc_line_start(d, doc_line_of(d, d_caret(d)))

fun doc_end_target(d: !Doc): int = let
  val line = doc_line_of(d, d_caret(d))
  val n = d_nlines(d)
  val e = if iadd(line, 1) >= n then d_len(d) else doc_line_start(d, iadd(line, 1))
in
  if igt(e, 0) andalso ieq(doc_byte(d, isub(e, 1)), 10) then isub(e, 1) else e
end

implement doc_home_move(d) = doc_set_caret_move(d, doc_home_target(d))
implement doc_home_select(d) = doc_set_caret_extend(d, doc_home_target(d))

implement doc_end_move(d) = doc_set_caret_move(d, doc_end_target(d))
implement doc_end_select(d) = doc_set_caret_extend(d, doc_end_target(d))

fun prev_line_target(d: !Doc, prev: int, ls: int, col_cps: int, wc: int): int = let
  val st = doc_line_start(d, prev)
  val stop = if igt(ls, st) andalso ieq(doc_byte(d, isub(ls, 1)), 10) then isub(ls, 1) else ls
  val plen_cps = doc_codepoints(d, st, stop)
  val prow = (if wc > 0 andalso igt(plen_cps, wc) then idiv(isub(plen_cps, 1), wc) else 0) : int
  val target_cps = imin(plen_cps, iadd(imul(prow, wc), col_cps))
in
  doc_advance_cps(d, st, stop, target_cps)
end

fun doc_up_target(d: !Doc): int = let
  val c = d_caret(d)
  val line = doc_line_of(d, c)
  val ls = doc_line_start(d, line)
  val cur_cps = doc_codepoints(d, ls, c)
  val wc = doc_get_wrap(d)
  val col_cps = (if wc > 0 then imod(cur_cps, wc) else cur_cps) : int
in
  if wc > 0 andalso ige(cur_cps, wc) then
    doc_advance_cps(d, ls, c, isub(cur_cps, wc))
  else if line <= 0 then 0
  else prev_line_target(d, isub(line, 1), ls, col_cps, wc)
end

fun next_line_target(d: !Doc, n: int, next_line: int, col_cps: int, wc: int): int = let
  val st = doc_line_start(d, next_line)
  val en = if iadd(next_line, 1) >= n then d_len(d) else doc_line_start(d, iadd(next_line, 1))
  val stop = if igt(en, st) andalso ieq(doc_byte(d, isub(en, 1)), 10) then isub(en, 1) else en
  val nlen_cps = doc_codepoints(d, st, stop)
  val target_cps = imin(nlen_cps, col_cps)
in
  doc_advance_cps(d, st, stop, target_cps)
end

fun doc_down_target(d: !Doc): int = let
  val c = d_caret(d)
  val line = doc_line_of(d, c)
  val n = d_nlines(d)
  val ls = doc_line_start(d, line)
  val en0 = if iadd(line, 1) < n then doc_line_start(d, iadd(line, 1)) else d_len(d)
  val stop0 = if igt(en0, ls) andalso ieq(doc_byte(d, isub(en0, 1)), 10) then isub(en0, 1) else en0
  val total_cps = doc_codepoints(d, ls, stop0)
  val cur_cps = doc_codepoints(d, ls, c)
  val wc = doc_get_wrap(d)
  val col_cps = (if wc > 0 then imod(cur_cps, wc) else cur_cps) : int
  val down_cps = iadd(cur_cps, wc)
in
  if wc > 0 andalso ilt(down_cps, total_cps) then
    doc_advance_cps(d, ls, stop0, down_cps)
  else if iadd(line, 1) >= n then d_len(d)
  else next_line_target(d, n, iadd(line, 1), col_cps, wc)
end

implement doc_up_move(d) = doc_set_caret_move(d, doc_up_target(d))
implement doc_up_select(d) = doc_set_caret_extend(d, doc_up_target(d))
implement doc_down_move(d) = doc_set_caret_move(d, doc_down_target(d))
implement doc_down_select(d) = doc_set_caret_extend(d, doc_down_target(d))

datatype CharClass = ClassBlank | ClassWord | ClassOther

fun class_code(c: CharClass): int = case+ c of
  | ClassBlank() => 0
  | ClassWord() => 1
  | ClassOther() => 2

fun is_class(a: CharClass, b: CharClass): bool = class_code(a) = class_code(b)

fun doc_char_class(b: int): CharClass =
  if b <= 32 then ClassBlank()
  else if (b >= 97 andalso b <= 122) orelse (b >= 65 andalso b <= 90) orelse (b >= 48 andalso b <= 57) orelse (b >= 128) then ClassWord()
  else ClassOther()

extern fun blank_back_exh(d: !Doc, i: int): int = "mac#anth_die_int"

fun blank_back_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int): int =
  if recfuel > 0 then (
    if i > 0 andalso is_class(doc_char_class(doc_byte(d, isub(i, 1))), ClassBlank) then
      blank_back_m(recfuel - 1, d, utf8_prev(d, i))
    else i
  ) else blank_back_exh(d, i)

extern fun class_back_exh(d: !Doc, i: int, cls: CharClass): int = "mac#anth_die_int"

fun class_back_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, cls: CharClass): int =
  if recfuel > 0 then (
    if i > 0 andalso is_class(doc_char_class(doc_byte(d, isub(i, 1))), cls) then
      class_back_m(recfuel - 1, d, utf8_prev(d, i), cls)
    else i
  ) else class_back_exh(d, i, cls)

fun word_left_pos(d: !Doc, cur: int): int =
  if cur <= 0 then 0
  else let
    val i = blank_back_m(airlock_nat(MAX_REC_FUEL), d, cur)
  in
    if i > 0 then class_back_m(airlock_nat(MAX_REC_FUEL), d, i, doc_char_class(doc_byte(d, isub(i, 1)))) else i
  end

extern fun skip_class_run_exh(d: !Doc, i: int, len: int, cls: CharClass): int = "mac#anth_die_int"

fun skip_class_run_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, len: int, cls: CharClass): int =
  if recfuel > 0 then (
    if ilt(i, len) andalso is_class(doc_char_class(doc_byte(d, i)), cls) then skip_class_run_m(recfuel - 1, d, utf8_next(d, i), len, cls)
    else i
  ) else skip_class_run_exh(d, i, len, cls)

fun skip_class_run(d: !Doc, i: int, len: int, cls: CharClass): int = skip_class_run_m(airlock_nat(MAX_REC_FUEL), d, i, len, cls)

extern fun skip_blank_run_exh(d: !Doc, i: int, len: int): int = "mac#anth_die_int"

fun skip_blank_run_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, len: int): int =
  if recfuel > 0 then (
    if ilt(i, len) andalso is_class(doc_char_class(doc_byte(d, i)), ClassBlank) andalso ine(doc_byte(d, i), 10) then skip_blank_run_m(recfuel - 1, d, utf8_next(d, i), len)
    else i
  ) else skip_blank_run_exh(d, i, len)

fun skip_blank_run(d: !Doc, i: int, len: int): int = skip_blank_run_m(airlock_nat(MAX_REC_FUEL), d, i, len)

fun word_right_pos(d: !Doc, cur: int): int = let
  val len = d_len(d)
in
  if cur >= len then len
  else let
    val cls = doc_char_class(doc_byte(d, cur))
  in
    if is_class(cls, ClassBlank) then skip_class_run(d, cur, len, ClassBlank)
    else skip_blank_run(d, skip_class_run(d, cur, len, cls), len)
  end
end

implement doc_word_left_move(d) = let
  val c = d_caret(d)
  val target = word_left_pos(d, c)
in
  doc_set_caret_move(d, target)
end

implement doc_word_left_select(d) = let
  val c = d_caret(d)
  val target = word_left_pos(d, c)
in
  doc_set_caret_extend(d, target)
end

implement doc_word_right_move(d) = let
  val c = d_caret(d)
  val target = word_right_pos(d, c)
in
  doc_set_caret_move(d, target)
end

implement doc_word_right_select(d) = let
  val c = d_caret(d)
  val target = word_right_pos(d, c)
in
  doc_set_caret_extend(d, target)
end

implement doc_del_word_left(d) = let
  val () = doc_record(d, OpBreak)
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
in
  if igt(b, a) then remove_between(d, a, b)
  else let
    val c = d_caret(d)
    val target = word_left_pos(d, c)
  in
    if target < c then remove_between(d, target, c) else ()
  end
end

implement doc_del_word_right(d) = let
  val () = doc_record(d, OpBreak)
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
in
  if igt(b, a) then remove_between(d, a, b)
  else let
    val c = d_caret(d)
    val target = word_right_pos(d, c)
  in
    if target > c then remove_between(d, c, target) else ()
  end
end

implement doc_doc_start_move(d) = doc_set_caret_move(d, 0)
implement doc_doc_start_select(d) = doc_set_caret_extend(d, 0)

implement doc_doc_end_move(d) = doc_set_caret_move(d, d_len(d))
implement doc_doc_end_select(d) = doc_set_caret_extend(d, d_len(d))

extern fun page_up_move_exh(d: !Doc, k: int, nlines: int): void = "mac#anth_die_void"

fun page_up_move_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, k: int, nlines: int): void =
  if recfuel > 0 then (
    if k < nlines then let
      val () = doc_up_move(d)
    in
      page_up_move_m(recfuel - 1, d, iadd(k, 1), nlines)
    end else ()
  ) else page_up_move_exh(d, k, nlines)

implement doc_page_up_move(d, nlines) = page_up_move_m(airlock_nat(MAX_REC_FUEL), d, 0, nlines)

extern fun page_up_select_exh(d: !Doc, k: int, nlines: int): void = "mac#anth_die_void"

fun page_up_select_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, k: int, nlines: int): void =
  if recfuel > 0 then (
    if k < nlines then let
      val () = doc_up_select(d)
    in
      page_up_select_m(recfuel - 1, d, iadd(k, 1), nlines)
    end else ()
  ) else page_up_select_exh(d, k, nlines)

implement doc_page_up_select(d, nlines) = page_up_select_m(airlock_nat(MAX_REC_FUEL), d, 0, nlines)

extern fun page_down_move_exh(d: !Doc, k: int, nlines: int): void = "mac#anth_die_void"

fun page_down_move_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, k: int, nlines: int): void =
  if recfuel > 0 then (
    if k < nlines then let
      val () = doc_down_move(d)
    in
      page_down_move_m(recfuel - 1, d, iadd(k, 1), nlines)
    end else ()
  ) else page_down_move_exh(d, k, nlines)

implement doc_page_down_move(d, nlines) = page_down_move_m(airlock_nat(MAX_REC_FUEL), d, 0, nlines)

extern fun page_down_select_exh(d: !Doc, k: int, nlines: int): void = "mac#anth_die_void"

fun page_down_select_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, k: int, nlines: int): void =
  if recfuel > 0 then (
    if k < nlines then let
      val () = doc_down_select(d)
    in
      page_down_select_m(recfuel - 1, d, iadd(k, 1), nlines)
    end else ()
  ) else page_down_select_exh(d, k, nlines)

implement doc_page_down_select(d, nlines) = page_down_select_m(airlock_nat(MAX_REC_FUEL), d, 0, nlines)

implement doc_save(d, path) = let
  var b = buf_make(16)
  val () = doc_text(d, b)
  val n = buf_len(b)
  val ok = fs_write_buf(path, b, n)
  val () = buf_free(b)
in
  ok
end

implement doc_save_vfs(d, path) = let
  val plen = c_strlen(path)
in
  if plen <= 0 then 0
  else let
    var vbuf = buf_make(512)
    val () = fs_vfs_buf(path, vbuf, 511)
    val vp = buf_cstr(vbuf)
    val vlen = c_strlen(vp)
    val res = if vlen > 0 then doc_save(d, vp) else 0
    val () = buf_free(vbuf)
  in
    res
  end
end

implement doc_save_physical(d, path) = let
  val plen = c_strlen(path)
in
  if plen <= 0 then 0
  else let
    val res = doc_save(d, path)
    var vbuf = buf_make(512)
    val () = fs_vfs_buf(path, vbuf, 511)
    val vp = buf_cstr(vbuf)
    val vlen = c_strlen(vp)
    val ul = if igt(vlen, 0) andalso ieq(fs_exists(vp), 1) then fs_unlink(vp) else 0
    val () = if ine(ul, 0) then report_failure("vfs_unlink", vp) else ()
    val () = buf_free(vbuf)
  in
    res
  end
end

fun replace_all_raw(d: !Doc, p: ptr, n: int): void = let
  val b = take_gap(d)
  val () = buf_free(b)
  val nb = buf_make(imax(256, iadd(n, 64)))
  val c = buf_cap(nb)
  val () = put_gap(d, nb)
  val () = d_set_lo(d, 0)
  val () = d_set_hi(d, c)
  val () = d_set_len(d, 0)
  val () = d_set_caret(d, 0)
  val () = d_set_anchor(d, 0)
  val () = d_set_nnodes(d, 0)
in
  doc_insert_core(d, p, n)
end

fun replace_all(d: !Doc, p: ptr, n: int): void = let
  val () = put_uhist(d, HNil())
  val () = put_rhist(d, HNil())
  val () = fold_clear(d)
in
  replace_all_raw(d, p, n)
end

fun replace_all_buf(d: !Doc, src: !Buf, n: int): void =
  replace_all(d, buf_ptr(src), n)

fun replace_raw_buf(d: !Doc, src: !Buf, n: int): void =
  replace_all_raw(d, buf_ptr(src), n)

fun insert_core_buf(d: !Doc, src: !Buf, n: int): void =
  doc_insert_core(d, buf_ptr(src), n)

fun restore_snapshot(d: !Doc, snap_b: Buf, snap_c: int): void = let
  val sn = buf_len(snap_b)
  val () = replace_raw_buf(d, snap_b, sn)
  val () = doc_set_caret_move(d, snap_c)
  val () = buf_free(snap_b)
in
end

implement doc_undo(d) = let
  var u = take_uhist(d)
in
  case+ u of
  | ~HNil() => put_uhist(d, HNil())
  | ~HCons(snap_b, snap_c, rest_u) => let
      val () = put_uhist(d, rest_u)
      val () = push_redo_current(d)
      val () = restore_snapshot(d, snap_b, snap_c)
    in
      set_last_op_and_reset_count(d, OpNone)
    end
end

implement doc_redo(d) = let
  var r = take_rhist(d)
in
  case+ r of
  | ~HNil() => put_rhist(d, HNil())
  | ~HCons(snap_b, snap_c, rest_r) => let
      val () = put_rhist(d, rest_r)
      val () = push_undo_current(d)
      val () = restore_snapshot(d, snap_b, snap_c)
    in
      set_last_op_and_reset_count(d, OpNone)
    end
end

fun wrap_selection(d: !Doc, a: int, b: int, pre: string, plen: int, suf: string, suflen: int): void = let
  val slen = isub(b, a)
  var sel_buf = buf_make(iadd(slen, 1))
  val () = seen_int(doc_slice_buf(d, a, b, sel_buf, slen))
  val () = buf_set_len(sel_buf, slen)
  val () = remove_between(d, a, b)
  val () = doc_insert_core(d, c_str_ptr(pre), plen)
  val () = insert_core_buf(d, sel_buf, slen)
  val () = doc_insert_core(d, c_str_ptr(suf), suflen)
  val () = buf_free(sel_buf)
  val new_pos = iadd(a, iadd(plen, iadd(slen, suflen)))
in
  doc_set_caret_move(d, new_pos)
end

fun wrap_at_caret(d: !Doc, a: int, pre: string, plen: int, suf: string, suflen: int): void = let
  val () = doc_insert_core(d, c_str_ptr(pre), plen)
  val () = doc_insert_core(d, c_str_ptr(suf), suflen)
  val mid = iadd(a, plen)
in
  doc_set_caret_move(d, mid)
end

implement doc_wrap(d, pre, plen, suf, suflen) = let
  val () = doc_record(d, OpBreak)
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
in
  if igt(b, a) then wrap_selection(d, a, b, pre, plen, suf, suflen)
  else wrap_at_caret(d, a, pre, plen, suf, suflen)
end

fun resolve_load_path(path: string, vbuf: !Buf): string = let
  val () = fs_vfs_buf(path, vbuf, 511)
  val vp = buf_cstr(vbuf)
  val vlen = c_strlen(vp)
  val has_vfs = igt(vlen, 0) andalso ieq(fs_exists(vp), 1) andalso igt(fs_size(vp), 0)
in
  if has_vfs then vp else path
end

fun is_markdown_path(path: string): bool = let
  val plen = c_strlen(path)
in
  if plen >= 3 andalso c_str_byte(path, isub(plen, 3)) = 46 andalso (c_str_byte(path, isub(plen, 2)) = 109 orelse c_str_byte(path, isub(plen, 2)) = 77) andalso (c_str_byte(path, isub(plen, 1)) = 100 orelse c_str_byte(path, isub(plen, 1)) = 68) then true
  else if plen >= 9 andalso c_str_byte(path, isub(plen, 9)) = 46 then true
  else false
end

fun read_doc_bytes(d: !Doc, path: string, fd: int, sz: int): bool = let
  val b = buf_make(iadd(sz, 1))
  val n = fs_read_buf(fd, b, sz)
  val () = fs_close(fd)
  val () = buf_set_len(b, if n > 0 then n else 0)
  val () = doc_set_md(d, toggle_of(is_markdown_path(path)))
  val () = replace_all_buf(d, b, if n > 0 then n else 0)
  val () = buf_free(b)
in
  true
end

fun load_doc_file(d: !Doc, path: string, actual_path: string): bool = let
  val sz = fs_size(actual_path)
in
  if sz < 0 orelse sz > 50000000 then false
  else let
    val fd = fs_open_read(actual_path)
  in
    if fd < 0 then false else read_doc_bytes(d, path, fd, sz)
  end
end

implement doc_load(d, path) = let
  var vbuf = buf_make(512)
  val actual_path = resolve_load_path(path, vbuf)
  val res = load_doc_file(d, path, actual_path)
  val () = buf_free(vbuf)
in
  res
end

(* Var olan bir dosya yuklenemezse bos belge kaydetmeye yol acmamak icin
   hata raporlanir ve 0 doner. Dosya yoksa (yeni belge) 1 doner. *)
implement doc_load_checked(d, path) = let
  val res = doc_load(d, path)
in
  if res then true
  else if ieq(fs_exists(path), 1) then let
    val () = report_failure("doc_load", path)
  in
    false
  end
  else true
end

fun doc_foldable_target_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, n: int
): int =
  if recfuel > 0 then (
    if i < 0 orelse i >= n then ~1
    else let
      val k = doc_node_kind(d, i)
    in
      if is_heading(k) orelse is_kind(k, KLi) orelse is_kind(k, KTask) then i
      else let
        val p = doc_node_parent(d, i)
      in
        if ige(p, 0) andalso ilt(p, n) then doc_foldable_target_m(recfuel - 1, d, p, n)
        else i
      end
    end
  ) else i

fun find_next_block_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, n: int, start_after: int
): int =
  if recfuel > 0 then (
    if ige(i, n) then ~1
    else if ilt(doc_node_start(d, i), start_after) then
      find_next_block_m(recfuel - 1, d, iadd(i, 1), n, start_after)
    else let
      val k = doc_node_kind(d, i)
    in
      if is_inline(k) orelse is_kind(k, KUl) orelse is_kind(k, KOl) then
        find_next_block_m(recfuel - 1, d, iadd(i, 1), n, start_after)
      else i
    end
  ) else ~1

fun find_next_block(d: !Doc, i: int, n: int, start_after: int): int =
  find_next_block_m(airlock_nat(MAX_REC_FUEL), d, i, n, start_after)

implement doc_is_foldable(d, i) = let
  val n = d_nnodes(d)
in
  if i < 0 orelse i >= n then false
  else let
    val k = doc_node_kind(d, i)
  in
    if is_heading(k) then true
    else let
      val nxt = find_next_block(d, iadd(i, 1), n, doc_node_end(d, i))
    in
      if nxt < 0 then false
      else igt(doc_node_depth(d, nxt), doc_node_depth(d, i))
    end
  end
end

implement doc_toggle(d, i0) = let
  val n = d_nnodes(d)
  val i = doc_foldable_target_m(airlock_nat(MAX_REC_FUEL), d, i0, n)
in
  if i < 0 orelse i >= n then ()
  else if not(doc_is_foldable(d, i)) then ()
  else let
    val c = doc_node_collapsed(d, i)
    val st = doc_node_start(d, i)
    val next_c = (if is_off(c) then On else Off)
    val () = if is_off(c) then fold_add(d, st) else fold_del(d, st)
    val () = d_bump_ver(d)
  in
    doc_node_set_collapsed(d, i, next_c)
  end
end

extern fun task_box_find_exh(d: !Doc, st: int, en: int, p: int): int = "mac#anth_die_int"

fun task_box_find_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, st: int, en: int, p: int): int =
  if recfuel > 0 then (
    if ige(p, en) orelse ige(iadd(p, 2), d_len(d)) then ~1
    else if ieq(doc_byte(d, p), 91) andalso ieq(doc_byte(d, iadd(p, 2)), 93) then iadd(p, 1)
    else task_box_find_m(recfuel - 1, d, st, en, iadd(p, 1))
  ) else task_box_find_exh(d, st, en, p)

fun task_box_find(d: !Doc, st: int, en: int, p: int): int = task_box_find_m(airlock_nat(MAX_REC_FUEL), d, st, en, p)

fun task_next_state(cur: int): int =
  task_mark_byte(task_next_mark(task_mark_of(cur)))

fun replace_task_mark(d: !Doc, pos: int, nxt: int): void = let
  var nb = buf_make(2)
  val () = buf_push(nb, nxt)
  val () = doc_set_caret_move(d, pos)
  val () = doc_set_caret_extend(d, iadd(pos, 1))
  val () = doc_delete(d)
  val () = doc_insert_buf(d, nb, 1)
in
  buf_free(nb)
end

implement doc_toggle_task(d, i0) = let
  val n = d_nnodes(d)
  val i = doc_foldable_target_m(airlock_nat(MAX_REC_FUEL), d, i0, n)
in
  if i < 0 orelse i >= n then ()
  else if not(is_kind(doc_node_kind(d, i), KTask)) then ()
  else let
    val st = doc_node_start(d, i)
    val en = doc_node_end(d, i)
    val pos = task_box_find(d, st, en, st)
  in
    if pos < 0 then ()
    else replace_task_mark(d, pos, task_next_state(doc_byte(d, pos)))
  end
end

implement column_w(avail) =
  if avail < 720 then avail else if avail > 850 then 850 else avail

implement column_x(pane, avail) = iadd(pane, idiv(isub(avail, column_w(avail)), 2))

extern fun has_kind_exh(d: !Doc, k: NodeKind, i: int): int = "mac#anth_die_int"

fun has_kind_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, k: NodeKind, i: int): int =
  if recfuel > 0 then (
    if ige(i, d_nnodes(d)) then 0
    else let
      val ki = doc_node_kind(d, i)
      val kc = kind_code(k)
      val kic = kind_code(ki)
      val hit = (if ieq(kc, kic) then true
        else if ieq(kc, kind_code(KImage)) andalso ieq(kic, kind_code(KEmbed)) then true
        else false)
    in
      if hit then 1
      else has_kind_m(recfuel - 1, d, k, iadd(i, 1))
    end
  ) else has_kind_exh(d, k, i)

fun has_kind(d: !Doc, k: NodeKind, i: int): int = has_kind_m(airlock_nat(MAX_REC_FUEL), d, k, i)

fun put_str(d: !Doc, s: string): void =
  doc_insert(d, c_str_ptr(s), c_strlen(s))

extern fun fill_paras_exh(d: !Doc, i: int): void = "mac#anth_die_void"

fun fill_paras_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int): void =
  if recfuel > 0 then (
    if ige(i, 100) then ()
    else let
      val () = put_str(d, "paragraf\n\n")
    in
      fill_paras_m(recfuel - 1, d, iadd(i, 1))
    end
  ) else fill_paras_exh(d, i)

fun fill_paras(d: !Doc, i: int): void = fill_paras_m(airlock_nat(MAX_REC_FUEL), d, i)

extern fun first_heading_exh(d: !Doc, i: int): int = "mac#anth_die_int"

fun first_heading_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int): int =
  if recfuel > 0 then (
    if ige(i, doc_nnodes(d)) then ~1
    else if is_kind(doc_node_kind(d, i), KH1) then i
    else first_heading_m(recfuel - 1, d, iadd(i, 1))
  ) else first_heading_exh(d, i)

fun first_heading(d: !Doc, i: int): int = first_heading_m(airlock_nat(MAX_REC_FUEL), d, i)

fun selftest_gap_check(d: !Doc): int = let
  val () = put_str(d, "ab")
  val () = doc_left_move(d)
  val () = doc_backspace(d)
in
  (if ieq(doc_len(d), 1) andalso ieq(doc_byte(d, 0), 98) andalso ieq(doc_caret(d), 0) then 1 else 0)
end

fun selftest_fill_markdown(d: !Doc): void = let
  val () = doc_right_move(d)
  val () = put_str(d, "\n# Baslik\n\n- madde\n- [ ] gorev\n- [x] bitti\n\n> alinti\n\n```\nkod\n```\n\n| a | b |\n| --- | --- |\n| 1 | 2 |\n\n[[Sayfa|ad]] ![[Resim.png]] #etiket/alt ==vurgu== $x$ $$y$$\n\n[^1]: not\n")
  val () = put_str(d, "[[Sayfa#b]]\n")
in
end

fun selftest_fm_check(): int = let
  val d2 = doc_open()
  val () = put_str(d2, "---\ntitle: x\n---\n")
  val fm = has_kind(d2, KFm, 0)
  val () = doc_free(d2)
in
  fm
end

fun selftest_print_kinds_1(d: !Doc, gap_ok: Toggle): int = let
  val h = has_kind(d, KH1, 0)
  val li = has_kind(d, KLi, 0)
  val task = has_kind(d, KTask, 0)
  val code = has_kind(d, KCode, 0)
  val () = println! ("gap=", toggle_int(gap_ok), " h=", h, " li=", li, " task=", task, " code=", code)
in
  (if is_on(gap_ok) andalso ieq(h, 1) andalso ieq(li, 1) andalso ieq(task, 1) andalso ieq(code, 1) then 1 else 0)
end

fun selftest_print_kinds_2(d: !Doc): int = let
  val table = has_kind(d, KTable, 0)
  val quote = has_kind(d, KQuote, 0)
  val wiki = has_kind(d, KWiki, 0)
  val img = has_kind(d, KImage, 0)
  val tag = has_kind(d, KTag, 0)
  val () = println! ("table=", table, " quote=", quote, " wiki=", wiki, " img=", img, " tag=", tag)
in
  (if ieq(table, 1) andalso ieq(quote, 1) andalso ieq(wiki, 1) andalso ieq(img, 1) andalso ieq(tag, 1) then 1 else 0)
end

fun selftest_print_kinds_3(d: !Doc, fm: int): int = let
  val high = has_kind(d, KHigh, 0)
  val math = has_kind(d, KMath, 0)
  val mathb = has_kind(d, KMathb, 0)
  val fndef = has_kind(d, KFndef, 0)
  val () = println! ("high=", high, " math=", math, " mathb=", mathb, " fn=", fndef, " fm=", fm)
in
  (if ieq(high, 1) andalso ieq(math, 1) andalso ieq(mathb, 1) andalso ieq(fndef, 1) andalso ieq(fm, 1) then 1 else 0)
end

fun selftest_markdown_part(d: !Doc): int = let
  val gap_ok = selftest_gap_check(d)
  val () = selftest_fill_markdown(d)
  val fm = selftest_fm_check()
  val k1 = selftest_print_kinds_1(d, toggle_of(ieq(gap_ok, 1)))
  val k2 = selftest_print_kinds_2(d)
  val k3 = selftest_print_kinds_3(d, fm)
in
  (if ieq(k1, 1) andalso ieq(k2, 1) andalso ieq(k3, 1) then 1 else 0)
end

fun selftest_fill_d3(d3: !Doc): void = let
  val () = fill_paras(d3, 0)
  val mid = idiv(doc_len(d3), 2)
  val () = doc_set_caret_move(d3, mid)
  val () = put_str(d3, "Z")
in
end

fun selftest_fold_flag(d: !Doc, hi: int): int =
  (if ilt(hi, 0) then 0 else (if ieq(doc_get(d, hi, 4), 1) andalso ieq(doc_get(d, iadd(hi, 1), 5), 0) then 1 else 0))

fun selftest_tagline_check(): int = let
  val d4 = doc_open()
  val () = put_str(d4, "#etiket/alt\n")
  val tl = (if ieq(has_kind(d4, KTag, 0), 1) andalso ilt(doc_nnodes(d4), 8) then 1 else 0) : int
  val () = doc_free(d4)
in
  tl
end

fun selftest_column_check(): int =
  (if ieq(column_w(1000), 850) andalso ieq(column_w(800), 800) andalso ieq(column_w(400), 400) andalso ieq(column_x(0, 1000), 75) then 1 else 0)

fun selftest_layout_part(d: !Doc): int = let
  val d3 = doc_open()
  val () = selftest_fill_d3(d3)
  val sp = doc_span(d3)
  val inc = (if ilt(sp, 80) andalso igt(doc_len(d3), 500) then 1 else 0) : int
  val () = doc_free(d3)
  val y0 = doc_layout(d, 18)
  val hi = first_heading(d, 0)
  val () = doc_toggle(d, hi)
  val y1 = doc_layout(d, 18)
  val folded = selftest_fold_flag(d, hi)
  val tagline = selftest_tagline_check()
  val col = selftest_column_check()
  val () = println! ("span=", sp, " inc=", inc, " fold=", folded, " y0=", y0, " y=", y1, " col=", col, " tl=", tagline)
in
  (if ieq(inc, 1) andalso ieq(folded, 1) andalso ieq(col, 1) andalso ieq(tagline, 1) then 1 else 0)
end

fun selftest_nav_check(): int = let
  val d_nav = doc_open()
  val () = put_str(d_nav, "hello world anthracite\n")
  val () = doc_doc_end_move(d_nav)
  val end_c = doc_caret(d_nav)
  val () = doc_word_left_move(d_nav)
  val w_left1 = doc_caret(d_nav)
  val () = doc_word_left_move(d_nav)
  val w_left2 = doc_caret(d_nav)
  val () = doc_doc_start_move(d_nav)
  val start_c = doc_caret(d_nav)
  val () = doc_word_right_move(d_nav)
  val w_right1 = doc_caret(d_nav)
  val () = doc_del_word_right(d_nav)
  val del_len = doc_len(d_nav)
  val () = doc_free(d_nav)
in
  (if ieq(start_c, 0) andalso igt(end_c, 15) andalso ilt(w_left1, end_c) andalso ilt(w_left2, w_left1) andalso igt(w_right1, 0) andalso ilt(del_len, end_c) then 1 else 0)
end

fun selftest_history_part(): int = let
  val d5 = doc_open()
  val () = put_str(d5, "deneme")
  val () = put_str(d5, " bir")
  val () = doc_undo(d5)
  val undo_ok = (if ieq(doc_len(d5), 6) then 1 else 0) : int
  val () = doc_redo(d5)
  val redo_ok = (if ieq(doc_len(d5), 10) then 1 else 0) : int
  val () = doc_set_caret_move(d5, 0)
  val () = doc_set_caret_extend(d5, 6)
  val () = doc_wrap(d5, "**", 2, "**", 2)
  val wrap_ok = (if ieq(doc_byte(d5, 0), CHAR_STAR) andalso ieq(doc_byte(d5, 1), CHAR_STAR) then 1 else 0) : int
  val () = doc_free(d5)
  val nav_ok = selftest_nav_check()
  val () = println! ("undo=", undo_ok, " redo=", redo_ok, " wrap=", wrap_ok, " nav=", nav_ok)
in
  (if ieq(undo_ok, 1) andalso ieq(redo_ok, 1) andalso ieq(wrap_ok, 1) andalso ieq(nav_ok, 1) then 1 else 0)
end

fun selftest_big_part(): void = let
  val d_big = doc_open()
  val big_ok = doc_load(d_big, "build/CMakeFiles/CMakeConfigureLog.yaml")
  val big_lines = doc_nlines(d_big)
  val big_h = doc_layout(d_big, 18)
  val big_c_line = doc_line_of(d_big, isub(doc_len(d_big), 10))
  val () = doc_free(d_big)
  val big_digit = (if big_ok then 1 else 0) : int
  val () = println! ("big_load=", big_digit, " lines=", big_lines, " h=", big_h, " last_line=", big_c_line)
in
end

fun selftest_vfs_autosave_ok(svfs_ok: Toggle, p: string, vpath: string): int = let
  val in_vfs = fs_exists(vpath)
  val on_disk_yet = fs_exists(p)
in
  (if is_on(svfs_ok) andalso ieq(in_vfs, 1) andalso ieq(on_disk_yet, 0) then 1 else 0)
end

fun selftest_vfs_close_ok(d: !Doc, p: string, vpath: string): int = let
  val sphys_ok = doc_save_physical(d, p)
  val on_disk_now = fs_exists(p)
  val in_vfs_after = fs_exists(vpath)
in
  (if ieq(sphys_ok, 1) andalso ieq(on_disk_now, 1) andalso ieq(in_vfs_after, 0) then 1 else 0)
end

fun selftest_vfs_part(): int = let
  val dvfs = doc_open()
  val () = put_str(dvfs, "vfs test content\n")
  val test_disk_p = "/tmp/anth_test_vfs.txt"
  val () = seen_int(if ieq(fs_exists(test_disk_p), 1) then fs_unlink(test_disk_p) else 0)
  val svfs_ok = doc_save_vfs(dvfs, test_disk_p)
  var vbuf = buf_make(512)
  val () = fs_vfs_buf(test_disk_p, vbuf, 511)
  val vpath = buf_cstr(vbuf)
  val vfs_ok1 = selftest_vfs_autosave_ok(toggle_of(ieq(svfs_ok, 1)), test_disk_p, vpath)
  val vfs_ok2 = selftest_vfs_close_ok(dvfs, test_disk_p, vpath)
  val () = seen_int(fs_unlink(test_disk_p))
  val () = buf_free(vbuf)
  val () = doc_free(dvfs)
  val vfs_ok = (if ieq(vfs_ok1, 1) andalso ieq(vfs_ok2, 1) then 1 else 0) : int
  val () = println! ("vfs_autosave=", vfs_ok, " in_ram=", vfs_ok1, " close_disk=", vfs_ok2)
in
  vfs_ok
end

fun eqb(d: !Doc, i: int, b: int): int =
  (if ieq(doc_byte(d, i), b) then 1 else 0)

extern fun text_covers_exh(d: !Doc, i: int, n: int, p: int): int = "mac#anth_die_int"

fun text_covers_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, n: int, p: int): int =
  if recfuel > 0 then (
    if ige(i, n) then 0
    else if is_kind(doc_node_kind(d, i), KText) andalso ile(doc_node_start(d, i), p) andalso ilt(p, doc_node_end(d, i)) then 1
    else text_covers_m(recfuel - 1, d, iadd(i, 1), n, p)
  ) else text_covers_exh(d, i, n, p)

fun text_covers(d: !Doc, p: int): int =
  text_covers_m(airlock_nat(MAX_REC_FUEL), d, 0, doc_nnodes(d), p)

extern fun span_covered_exh(d: !Doc, p: int, n: int): int = "mac#anth_die_int"

fun span_covered_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: int, n: int): int =
  if recfuel > 0 then (
    if ige(p, n) then 1
    else if ieq(text_covers(d, p), 0) then 0
    else span_covered_m(recfuel - 1, d, iadd(p, 1), n)
  ) else span_covered_exh(d, p, n)

fun span_covered(d: !Doc): int =
  span_covered_m(airlock_nat(MAX_REC_FUEL), d, 0, doc_len(d))

fun mid_bytes(d: !Doc): int =
  (if ieq(doc_len(d), 5) andalso ieq(eqb(d, 0, 97), 1) andalso ieq(eqb(d, 1, 98), 1) andalso ieq(eqb(d, 2, 99), 1) andalso ieq(eqb(d, 3, 101), 1) andalso ieq(eqb(d, 4, 102), 1) andalso ieq(doc_caret(d), 3) then 1 else 0)

fun selftest_delete_mid(): int = let
  val d = doc_open()
  val () = put_str(d, "abcdef")
  val () = doc_left_move(d)
  val () = doc_left_move(d)
  val () = doc_left_move(d)
  val () = doc_delete(d)
  val ok = (if ieq(mid_bytes(d), 1) andalso ieq(span_covered(d), 1) then 1 else 0)
  val () = doc_free(d)
in
  ok
end

fun tail_bytes(d: !Doc): int =
  (if ieq(doc_len(d), 5) andalso ieq(eqb(d, 0, 97), 1) andalso ieq(eqb(d, 1, 98), 1) andalso ieq(eqb(d, 2, 99), 1) andalso ieq(eqb(d, 3, 100), 1) andalso ieq(eqb(d, 4, 101), 1) andalso ieq(doc_caret(d), 5) then 1 else 0)

fun selftest_delete_tail(): int = let
  val d = doc_open()
  val () = put_str(d, "abcdef")
  val () = doc_left_move(d)
  val () = doc_delete(d)
  val ok = (if ieq(tail_bytes(d), 1) andalso ieq(span_covered(d), 1) then 1 else 0)
  val () = doc_free(d)
in
  ok
end

fun utf_bytes(d: !Doc): int =
  (if ieq(doc_len(d), 4) andalso ieq(eqb(d, 0, 97), 1) andalso ieq(eqb(d, 1, 98), 1) andalso ieq(eqb(d, 2, 100), 1) andalso ieq(eqb(d, 3, 101), 1) andalso ieq(doc_caret(d), 2) then 1 else 0)

fun selftest_delete_utf(): int = let
  val d = doc_open()
  val () = put_str(d, "abğde")
  val () = doc_set_caret_move(d, 2)
  val () = doc_delete(d)
  val ok = (if ieq(utf_bytes(d), 1) andalso ieq(span_covered(d), 1) then 1 else 0)
  val () = doc_free(d)
in
  ok
end

fun twice_bytes(d: !Doc): int =
  (if ieq(doc_len(d), 4) andalso ieq(eqb(d, 0, 97), 1) andalso ieq(eqb(d, 1, 98), 1) andalso ieq(eqb(d, 2, 99), 1) andalso ieq(eqb(d, 3, 102), 1) andalso ieq(doc_caret(d), 3) then 1 else 0)

fun selftest_delete_twice(): int = let
  val d = doc_open()
  val () = put_str(d, "abcdef")
  val () = doc_set_caret_move(d, 3)
  val () = doc_delete(d)
  val () = doc_delete(d)
  val ok = (if ieq(twice_bytes(d), 1) andalso ieq(span_covered(d), 1) then 1 else 0)
  val () = doc_free(d)
in
  ok
end

fun selftest_delete_part(): int = let
  val mid = selftest_delete_mid()
  val tail = selftest_delete_tail()
  val utf = selftest_delete_utf()
  val twice = selftest_delete_twice()
  val () = println! ("del_mid=", mid, " del_tail=", tail, " del_utf=", utf, " del_twice=", twice)
in
  (if ieq(mid, 1) andalso ieq(tail, 1) andalso ieq(utf, 1) andalso ieq(twice, 1) then 1 else 0)
end

implement doc_selftest() = let
  val d = doc_open()
  val a_ok = selftest_markdown_part(d)
  val b_ok = selftest_layout_part(d)
  val c_ok = selftest_history_part()
  val () = selftest_big_part()
  val v_ok = selftest_vfs_part()
  val d_ok = selftest_delete_part()
  val t_ok = ast_selftest()
  val () = doc_free(d)
in
  (if ieq(a_ok, 1) andalso ieq(b_ok, 1) andalso ieq(c_ok, 1) andalso ieq(v_ok, 1) andalso ieq(d_ok, 1) andalso ieq(t_ok, 1) then 1 else 0)
end
