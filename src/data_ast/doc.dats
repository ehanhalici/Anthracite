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
staload "data_ast/doc_parse.sats"

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
  gap= Buf, lines= Buf, liney= Buf, nodes= Buf
, uhist= Hist, rhist= Hist
, lo= int, hi= int, len= int
, caret= int, anchor= int
, nlines= int, nnodes= int, span= int
, last_op= EditOp, typing_cnt= int, is_md= Toggle
}
(* skill.md 1. kural istisnasi: ATS2 soyut tip gerceklemesi (sats'taki absviewtype). Kanit disi cast veya ham C yoktur. *)
assume Doc = Doc_

implement doc_open() = DOC(@{
  gap= buf_make(256), lines= buf_make(64 * 4), liney= buf_make(64 * 8), nodes= buf_make(64 * NS * 4)
, uhist= HNil(), rhist= HNil()
, lo= 0, hi= 256, len= 0
, caret= 0, anchor= 0
, nlines= 1, nnodes= 0, span= 0
, last_op= OpNone, typing_cnt= 0, is_md= On
})

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

implement doc_free(d) = let
  val+~DOC(s) = d
  val () = buf_free(s.gap)
  val () = buf_free(s.lines)
  val () = buf_free(s.liney)
  val () = buf_free(s.nodes)
  val () = hist_free(s.uhist)
in
  hist_free(s.rhist)
end

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
fun d_set_nnodes(d: !Doc, v: int): void = dset(d, DOC_FIELD_NNODES, v)
fun d_set_span(d: !Doc, v: int): void = dset(d, DOC_FIELD_SPAN, v)

implement doc_len(d) = d_len(d)
implement doc_touch(d) = seen_int(doc_len(d))
implement doc_caret(d) = d_caret(d)
implement doc_anchor(d) = d_anchor(d)
implement doc_nlines(d) = d_nlines(d)
implement doc_nnodes(d) = d_nnodes(d)
implement doc_span(d) = d_span(d)

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

fun take_nodes(d: !Doc): Buf =
  case+ d of
  | @DOC(s) => let
      val b = s.nodes
      val () = s.nodes := buf_make(NS * 4)
    in
      fold@(d); b
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

extern fun copy_fwd_exh(src: !Buf, so: int, dst: !Buf, dst0: int, n: int, i: int): void = "mac#anth_die_void"

fun copy_fwd_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, so: int, dst: !Buf, dst0: int, n: int, i: int): void =
  if recfuel > 0 then (
    if ilt(i, n) then let
      val () = buf_set(dst, iadd(dst0, i), buf_get(src, iadd(so, i)))
    in
      copy_fwd_m(recfuel - 1, src, so, dst, dst0, n, iadd(i, 1))
    end else ()
  ) else copy_fwd_exh(src, so, dst, dst0, n, i)

fun copy_fwd(src: !Buf, so: int, dst: !Buf, dst0: int, n: int): void =
  copy_fwd_m(airlock_nat(MAX_REC_FUEL), src, so, dst, dst0, n, 0)

extern fun copy_same_exh(b: !Buf, so: int, dst0: int, n: int, i: int): void = "mac#anth_die_void"

fun copy_same_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, so: int, dst0: int, n: int, i: int): void =
  if recfuel > 0 then (
    if ilt(i, n) then let
      val () = buf_set(b, iadd(dst0, i), buf_get(b, iadd(so, i)))
    in
      copy_same_m(recfuel - 1, b, so, dst0, n, iadd(i, 1))
    end else ()
  ) else copy_same_exh(b, so, dst0, n, i)

fun copy_fwd_same(b: !Buf, so: int, dst0: int, n: int): void =
  copy_same_m(airlock_nat(MAX_REC_FUEL), b, so, dst0, n, 0)

extern fun copy_back_exh(b: !Buf, so: int, dst0: int, i: int): void = "mac#anth_die_void"

fun copy_back_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, so: int, dst0: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, 0) then let
      val () = buf_set(b, iadd(dst0, i), buf_get(b, iadd(so, i)))
    in
      copy_back_m(recfuel - 1, b, so, dst0, isub(i, 1))
    end else ()
  ) else copy_back_exh(b, so, dst0, i)

fun copy_back_same(b: !Buf, so: int, dst0: int, n: int): void =
  copy_back_m(airlock_nat(MAX_REC_FUEL), b, so, dst0, isub(n, 1))

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

implement doc_line_start(d, i) =
  case+ d of
  | @DOC(s) => let
      val v = if i >= 0 andalso i < s.nlines then buf_get32(s.lines, i) else 0
    in
      fold@(d); v
    end

fun line_room(d: !Doc, i: int): void =
  case+ d of
  | @DOC(s) => let
      val need = imul(iadd(i, 1), 8)
      val () = if buf_cap(s.liney) < need then buf_resize(s.liney, imul(need, 2)) else ()
    in
      fold@(d)
    end

fun line_put(d: !Doc, i: int, y: int, step: int): void = let
  val () = line_room(d, i)
in
  case+ d of
  | @DOC(s) => let
      val () = buf_set32(s.liney, imul(i, 2), y)
      val () = buf_set32(s.liney, iadd(imul(i, 2), 1), step)
    in
      fold@(d)
    end
end

implement doc_line_y(d, i) =
  case+ d of
  | @DOC(s) => let
      val v = if i >= 0 andalso i < s.nlines then buf_get32(s.liney, imul(i, 2)) else 0
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

implement doc_get(d, i, f) = nget(d, i, f)
implement doc_set(d, i, f, v) = nset(d, i, f, v)

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
  else KNone

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

implement is_inline(k) = case+ k of
  | KText() => true | KWiki() => true | KEmbed() => true | KTag() => true
  | KFn() => true | KHigh() => true | KMath() => true | KMathb() => true
  | KTd() => true | KNone() => false | KPara() => false | KH1() => false
  | KH2() => false | KH3() => false | KH4() => false | KH5() => false
  | KH6() => false | KUl() => false | KOl() => false | KLi() => false
  | KQuote() => false | KCode() => false | KHr() => false | KTable() => false
  | KTask() => false | KFndef() => false | KFm() => false | KImage() => false
  | KBold() => false | KItalic() => false | KStrike() => false | KLink() => false

implement heading_stops(k, limit) =
  is_heading(k) andalso ile(kind_code(k), kind_code(limit))

implement doc_node_kind(d, i) = kind_of(nget(d, i, NF_KIND))
implement doc_node_start(d, i) = nget(d, i, NF_START)
implement doc_node_end(d, i) = nget(d, i, NF_END)
implement doc_node_depth(d, i) = nget(d, i, NF_DEPTH)
implement doc_node_collapsed(d, i) = toggle_of(ieq(nget(d, i, NF_COLLAPSED), 1))
implement doc_node_height(d, i) = nget(d, i, NF_HEIGHT)
implement doc_node_parent(d, i) = nget(d, i, NF_PARENT)
implement doc_node_hidden(d, i) = toggle_of(ieq(nget(d, i, NF_HIDDEN), 1))
implement doc_node_aux(d, i) = nget(d, i, NF_AUX)
implement doc_node_y(d, i) = nget(d, i, NF_Y)

fun doc_node_set_collapsed(d: !Doc, i: int, v: Toggle): void = nset(d, i, NF_COLLAPSED, toggle_int(v))
fun doc_node_set_height(d: !Doc, i: int, h: int): void = nset(d, i, NF_HEIGHT, h)
fun doc_node_set_parent(d: !Doc, i: int, p: int): void = nset(d, i, NF_PARENT, p)
fun doc_node_set_next_sib(d: !Doc, i: int, s: int): void = nset(d, i, NF_NEXT_SIB, s)
fun doc_node_set_first_child(d: !Doc, i: int, c: int): void = nset(d, i, NF_FIRST_CHILD, c)
fun doc_node_set_hidden(d: !Doc, i: int, v: Toggle): void = nset(d, i, NF_HIDDEN, toggle_int(v))
fun doc_node_set_y(d: !Doc, i: int, y: int): void = nset(d, i, NF_Y, y)
fun doc_node_first_child(d: !Doc, i: int): int = nget(d, i, NF_FIRST_CHILD)

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

fun copy_node(src: !Buf, i: int, d: !Doc, delta: int): void = let
  val kind = buf_get32(src, iadd(imul(i, NS), NF_KIND))
  val st = iadd(buf_get32(src, iadd(imul(i, NS), NF_START)), delta)
  val en = iadd(buf_get32(src, iadd(imul(i, NS), NF_END)), delta)
  val depth = buf_get32(src, iadd(imul(i, NS), NF_DEPTH))
  val aux = buf_get32(src, iadd(imul(i, NS), NF_AUX))
  val col = buf_get32(src, iadd(imul(i, NS), NF_COLLAPSED))
  val () = npush(d, kind_of(kind), st, en, depth, aux)
  val id = isub(d_nnodes(d), 1)
  val () = doc_node_set_collapsed(d, id, toggle_of(ieq(col, 1)))
in
end

implement doc_push_node(d, kind, st, en, depth, aux) =
  npush(d, kind, st, en, depth, aux)

extern fun copy_kept_exh(old: !Buf, d: !Doc, i: int, n: int, rs: int, re: int, delta: int, which: int): void = "mac#anth_die_void"

fun copy_kept_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), old: !Buf, d: !Doc, i: int, n: int, rs: int, re: int, delta: int, which: int): void =
  if recfuel > 0 then (
    if ige(i, n) then ()
    else let
      val st = buf_get32(old, iadd(imul(i, NS), NF_START))
      val en = buf_get32(old, iadd(imul(i, NS), NF_END))
      val () =
        if ieq(which, 0) then (
          if ile(en, rs) then copy_node(old, i, d, 0) else ()
        ) else (
          if ige(st, re) then copy_node(old, i, d, delta) else ()
        )
    in
      copy_kept_m(recfuel - 1, old, d, iadd(i, 1), n, rs, re, delta, which)
    end
  ) else copy_kept_exh(old, d, i, n, rs, re, delta, which)

fun copy_kept(old: !Buf, d: !Doc, i: int, n: int, rs: int, re: int, delta: int, which: int): void = copy_kept_m(airlock_nat(MAX_REC_FUEL), old, d, i, n, rs, re, delta, which)

fun salvage(d: !Doc, rs: int, re: int, delta: int): void = let
  val is_md = doc_is_md(d)
in
  if is_off(is_md) then let
    val () = d_set_nnodes(d, 0)
  in
  end else let
    val n = d_nnodes(d)
    val old = take_nodes(d)
    val () = d_set_nnodes(d, 0)
    val () = copy_kept(old, d, 0, n, rs, re, delta, 0)
    val () = doc_parse_range(d, rs, iadd(re, delta))
    val () = copy_kept(old, d, 0, n, rs, re, delta, 1)
    val () = buf_free(old)
    val () = d_set_span(d, iadd(isub(re, rs), delta))
  in
  end
end

(* endat, satir tablosu guncellenmeden onceki uzunluktur. *)
fun dirty(d: !Doc, at: int, endat: int, rs: &int >> _, re: &int >> _): void = let
  val line = doc_line_of(d, at)
  val a = if line > 0 then isub(line, 1) else 0
  val b0 = iadd(line, 2)
  val nlines = d_nlines(d)
  val b = if b0 < nlines then b0 else nlines
  val () = rs := doc_line_start(d, a)
  val re0 = if ige(b, nlines) then endat else doc_line_start(d, b)
  val () = re := re0
in
end

extern fun parent_of_exh(d: !Doc, i: int, j: int, steps: int): int = "mac#anth_die_int"

fun parent_of_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, j: int, steps: int): int =
  if recfuel > 0 then (
    if ilt(j, 0) orelse igt(steps, 80) then ~1
    else let
      val st = doc_node_start(d, i)
      val en = doc_node_end(d, i)
    in
      if ile(doc_node_start(d, j), st) andalso ige(doc_node_end(d, j), en) andalso igt(doc_node_end(d, j), doc_node_start(d, j)) then j
      else parent_of_m(recfuel - 1, d, i, isub(j, 1), iadd(steps, 1))
    end
  ) else parent_of_exh(d, i, j, steps)

fun parent_of(d: !Doc, i: int, j: int, steps: int): int = parent_of_m(airlock_nat(MAX_REC_FUEL), d, i, j, steps)

extern fun next_sib_exh(d: !Doc, n: int, p: int, k: int, steps: int): int = "mac#anth_die_int"

fun next_sib_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, n: int, p: int, k: int, steps: int): int =
  if recfuel > 0 then (
    if ige(k, n) orelse igt(steps, 80) then ~1
    else if ieq(doc_node_parent(d, k), p) then k
    else next_sib_m(recfuel - 1, d, n, p, iadd(k, 1), iadd(steps, 1))
  ) else next_sib_exh(d, n, p, k, steps)

fun next_sib(d: !Doc, n: int, p: int, k: int, steps: int): int = next_sib_m(airlock_nat(MAX_REC_FUEL), d, n, p, k, steps)

extern fun relink_clear_exh(d: !Doc, n: int, i: int): void = "mac#anth_die_void"

fun relink_clear_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, n: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, n) then ()
    else let
      val () = doc_node_set_parent(d, i, ~1)
      val () = doc_node_set_next_sib(d, i, ~1)
      val () = doc_node_set_first_child(d, i, ~1)
    in
      relink_clear_m(recfuel - 1, d, n, iadd(i, 1))
    end
  ) else relink_clear_exh(d, n, i)

fun relink_clear(d: !Doc, n: int, i: int): void = relink_clear_m(airlock_nat(MAX_REC_FUEL), d, n, i)

extern fun relink_parents_exh(d: !Doc, n: int, i: int): void = "mac#anth_die_void"

fun relink_parents_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, n: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, n) then ()
    else let
      val p = parent_of(d, i, isub(i, 1), 0)
      val () = doc_node_set_parent(d, i, p)
      val () = if ige(p, 0) andalso ilt(doc_node_first_child(d, p), 0) then doc_node_set_first_child(d, p, i) else ()
    in
      relink_parents_m(recfuel - 1, d, n, iadd(i, 1))
    end
  ) else relink_parents_exh(d, n, i)

fun relink_parents(d: !Doc, n: int, i: int): void = relink_parents_m(airlock_nat(MAX_REC_FUEL), d, n, i)

extern fun relink_next_exh(d: !Doc, n: int, i: int): void = "mac#anth_die_void"

fun relink_next_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, n: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, n) then ()
    else let
      val p = doc_node_parent(d, i)
      val () = doc_node_set_next_sib(d, i, next_sib(d, n, p, iadd(i, 1), 0))
    in
      relink_next_m(recfuel - 1, d, n, iadd(i, 1))
    end
  ) else relink_next_exh(d, n, i)

fun relink_next(d: !Doc, n: int, i: int): void = relink_next_m(airlock_nat(MAX_REC_FUEL), d, n, i)

fun relink(d: !Doc): void = let
  val is_md = doc_is_md(d)
in
  if is_off(is_md) then ()
  else let
    val n = d_nnodes(d)
    val () = relink_clear(d, n, 0)
    val () = relink_parents(d, n, 0)
  in
    relink_next(d, n, 0)
  end
end

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
    val a = doc_node_aux(d, i)
  in
    if igt(a, 8) then a else 0
  end
  else if is_inline(k) then 0
  else if is_kind(k, KHr) then 12
  else if is_kind(k, KImage) then let
    val a = doc_node_aux(d, i)
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

extern fun stack_y_exh(d: !Doc, n: int, i: int, y: int): int = "mac#anth_die_int"

fun stack_y_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, n: int, i: int, y: int): int =
  if recfuel > 0 then (
    if ige(i, n) then y
    else let
      val () = doc_node_set_y(d, i, y)
    in
      stack_y_m(recfuel - 1, d, n, iadd(i, 1), iadd(y, doc_node_height(d, i)))
    end
  ) else stack_y_exh(d, n, i, y)

fun stack_y(d: !Doc, n: int, i: int, y: int): int = stack_y_m(airlock_nat(MAX_REC_FUEL), d, n, i, y)

extern fun line_hidden_exh(d: !Doc, st: int, en: int, i: int, n: int, saw: Toggle): int = "mac#anth_die_int"

fun line_hidden_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, st: int, en: int, i: int, n: int, saw: Toggle): int =
  if recfuel > 0 then (
    if ige(i, n) then toggle_int(saw)
    else let
      val ns = doc_node_start(d, i)
      val ne = doc_node_end(d, i)
      val hit = ilt(ns, en) andalso igt(ne, st)
    in
      if hit andalso is_off(doc_node_hidden(d, i)) then 0
      else line_hidden_m(recfuel - 1, d, st, en, iadd(i, 1), n, if hit then On else saw)
    end
  ) else line_hidden_exh(d, st, en, i, n, saw)

fun line_hidden(d: !Doc, st: int, en: int, i: int, n: int, saw: Toggle): int = line_hidden_m(airlock_nat(MAX_REC_FUEL), d, st, en, i, n, saw)

extern fun widget_h_exh(d: !Doc, st: int, en: int, i: int, n: int, acc: int): int = "mac#anth_die_int"

fun widget_h_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, st: int, en: int, i: int, n: int, acc: int): int =
  if recfuel > 0 then (
    if ige(i, n) then acc
    else let
      val k = doc_node_kind(d, i)
      val ns = doc_node_start(d, i)
      val h = doc_node_height(d, i)
      val use = if is_off(doc_node_hidden(d, i)) andalso ige(ns, st) andalso ilt(ns, en) andalso (is_kind(k, KImage) orelse is_kind(k, KEmbed)) andalso igt(h, acc) then h else acc
    in
      widget_h_m(recfuel - 1, d, st, en, iadd(i, 1), n, use)
    end
  ) else widget_h_exh(d, st, en, i, n, acc)

fun widget_h(d: !Doc, st: int, en: int, i: int, n: int, acc: int): int = widget_h_m(airlock_nat(MAX_REC_FUEL), d, st, en, i, n, acc)

extern fun assign_lines_exh(d: !Doc, lh: int, line: int, y: int): int = "mac#anth_die_int"

fun assign_lines_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, lh: int, line: int, y: int): int =
  if recfuel > 0 then (
  let
    val nlines = d_nlines(d)
  in
    if ige(line, nlines) then y
    else let
      val n = d_nnodes(d)
      val st = doc_line_start(d, line)
      val en = if iadd(line, 1) < nlines then doc_line_start(d, iadd(line, 1)) else d_len(d)
      val hid = line_hidden(d, st, en, 0, n, Off)
      val extra = if ieq(hid, 1) then 0 else widget_h(d, st, en, 0, n, 0)
      val step = if ieq(hid, 1) then 0 else iadd(lh, extra)
      val () = line_put(d, line, y, step)
    in
      assign_lines_m(recfuel - 1, d, lh, iadd(line, 1), iadd(y, step))
    end
  end
  ) else assign_lines_exh(d, lh, line, y)

fun assign_lines(d: !Doc, lh: int, line: int, y: int): int = assign_lines_m(airlock_nat(MAX_REC_FUEL), d, lh, line, y)

extern fun stamp_nodes_exh(d: !Doc, lh: int, i: int): void = "mac#anth_die_void"

fun stamp_nodes_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, lh: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, d_nnodes(d)) then ()
    else let
      val line = doc_line_of(d, doc_node_start(d, i))
      val ly = doc_line_y(d, line)
      val k = doc_node_kind(d, i)
      val y = if is_kind(k, KImage) orelse is_kind(k, KEmbed) then iadd(ly, lh) else ly
      val () = doc_node_set_y(d, i, y)
    in
      stamp_nodes_m(recfuel - 1, d, lh, iadd(i, 1))
    end
  ) else stamp_nodes_exh(d, lh, i)

fun stamp_nodes(d: !Doc, lh: int, i: int): void = stamp_nodes_m(airlock_nat(MAX_REC_FUEL), d, lh, i)

extern fun fill_liney_exh(liney: !Buf, i: int, nlines: int, lh: int): void = "mac#anth_die_void"

fun fill_liney_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), liney: !Buf, i: int, nlines: int, lh: int): void =
  if recfuel > 0 then (
    if ilt(i, nlines) then let
      val () = buf_set32(liney, imul(i, 2), imul(i, lh))
      val () = buf_set32(liney, iadd(imul(i, 2), 1), lh)
    in
      fill_liney_m(recfuel - 1, liney, iadd(i, 1), nlines, lh)
    end else ()
  ) else fill_liney_exh(liney, i, nlines, lh)

fun fill_plain_lines(d: !Doc, lh: int, nlines: int): void =
  case+ d of
  | @DOC(s) => let
      val need = imul(iadd(nlines, 1), 8)
      val () = if buf_cap(s.liney) < need then buf_resize(s.liney, imax(imul(need, 2), 4096)) else ()
      val () = fill_liney_m(airlock_nat(MAX_REC_FUEL), s.liney, 0, nlines, lh)
    in
      fold@(d)
    end

implement doc_layout(d, lh0) = let
  val lh = if ilt(lh0, 8) then 8 else lh0
  val is_md = doc_is_md(d)
  val n = d_nnodes(d)
in
  if is_off(is_md) orelse ieq(n, 0) then let
    val nlines = d_nlines(d)
    val () = fill_plain_lines(d, lh, nlines)
  in
    imul(nlines, lh)
  end else let
    val () = clear_hide(d, n, 0)
    val () = place_one(d, n, 0, lh)
    val total = assign_lines(d, lh, 0, 0)
    val () = stamp_nodes(d, lh, 0)
  in
    total
  end
end

fun reparse(d: !Doc, at: int, oldlen: int): void = let
  var rs: int = 0
  var re: int = 0
  val () = dirty(d, at, oldlen, rs, re)
  val delta = isub(d_len(d), oldlen)
  val () = rebuild_lines(d)
  val () = salvage(d, rs, re, delta)
in
  relink(d)
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
  in
    reparse(d, a, old)
  end
end

extern fun slice_exh(d: !Doc, a: int, dst: ptr, cap: int, i: int, n: int): void = "mac#anth_die_void"

fun slice_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, a: int, dst: ptr, cap: int, i: int, n: int): void =
  if recfuel > 0 then (
    if ilt(i, n) then let
      val () = mem_set_byte(dst, cap, i, doc_byte(d, iadd(a, i)))
    in
      slice_m(recfuel - 1, d, a, dst, cap, iadd(i, 1), n)
    end else ()
  ) else slice_exh(d, a, dst, cap, i, n)

implement doc_slice(d, a0, b0, dst, cap) = let
  val len = d_len(d)
  val a = if a0 < 0 then 0 else a0
  val b = if b0 > len then len else b0
  val n = if igt(isub(b, a), cap) then cap else isub(b, a)
  val () = slice_m(airlock_nat(MAX_REC_FUEL), d, a, dst, cap, 0, n)
in
  n
end

implement doc_slice_buf(d, a, b, dst, cap) =
  doc_slice(d, a, b, buf_ptr(dst), cap)

extern fun text_copy_exh(d: !Doc, dst: !Buf, i: int, n: int): void = "mac#anth_die_void"

fun text_copy_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, dst: !Buf, i: int, n: int): void =
  if recfuel > 0 then (
    if i < n then let
      val () = buf_set(dst, i, doc_byte(d, i))
    in
      text_copy_m(recfuel - 1, d, dst, iadd(i, 1), n)
    end else ()
  ) else text_copy_exh(d, dst, i, n)

implement doc_text(d, dst) = let
  val n = d_len(d)
  val () = buf_resize(dst, iadd(n, 1))
  val () = text_copy_m(airlock_nat(MAX_REC_FUEL), d, dst, 0, n)
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

fun doc_insert_core(d: !Doc, p: ptr, n: int): void = let
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
  val () = if igt(b, a) then remove_between(d, a, b) else ()
  val at = d_caret(d)
  var rs: int = 0
  var re: int = 0
  val () = dirty(d, at, d_len(d), rs, re)
  val old = d_len(d)
  val () = gap_move(d, at)
  val () = gap_put(d, p, n)
  val () = d_set_caret(d, iadd(at, n))
  val () = d_set_anchor(d, iadd(at, n))
  val delta = isub(d_len(d), old)
  val () = rebuild_lines(d)
  val () = salvage(d, rs, re, delta)
in
  relink(d)
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

fun doc_up_target(d: !Doc): int = let
  val c = d_caret(d)
  val line = doc_line_of(d, c)
  val col = isub(c, doc_line_start(d, line))
in
  if line <= 0 then 0
  else let
    val st = doc_line_start(d, isub(line, 1))
    val en = doc_line_start(d, line)
    val stop = if igt(en, st) andalso ieq(doc_byte(d, isub(en, 1)), 10) then isub(en, 1) else en
  in
    utf8_align(d, imin(iadd(st, col), stop))
  end
end

fun doc_down_target(d: !Doc): int = let
  val c = d_caret(d)
  val line = doc_line_of(d, c)
  val n = d_nlines(d)
  val col = isub(c, doc_line_start(d, line))
in
  if iadd(line, 1) >= n then d_len(d)
  else let
    val st = doc_line_start(d, iadd(line, 1))
    val en = if iadd(line, 2) >= n then d_len(d) else doc_line_start(d, iadd(line, 2))
    val stop = if igt(en, st) andalso ieq(doc_byte(d, isub(en, 1)), 10) then isub(en, 1) else en
  in
    utf8_align(d, imin(iadd(st, col), stop))
  end
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

implement doc_toggle(d, i) = let
  val n = d_nnodes(d)
in
  if i < 0 orelse i >= n then ()
  else let
    val c = doc_node_collapsed(d, i)
  in
    doc_node_set_collapsed(d, i, (if is_off(c) then On else Off))
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

implement doc_toggle_task(d, i) = let
  val n = d_nnodes(d)
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
    else if is_kind(doc_node_kind(d, i), k) then 1
    else has_kind_m(recfuel - 1, d, k, iadd(i, 1))
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
  val () = doc_free(d)
in
  (if ieq(a_ok, 1) andalso ieq(b_ok, 1) andalso ieq(c_ok, 1) andalso ieq(v_ok, 1) andalso ieq(d_ok, 1) then 1 else 0)
end
