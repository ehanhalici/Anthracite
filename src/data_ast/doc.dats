#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "os/fs.sats"
staload "data_ast/doc.sats"
staload "data_ast/doc_parse.sats"

#define NS 16
#define NK_PARA 1
#define NK_H1 2
#define NK_H6 7
#define NK_UL 8
#define NK_OL 9
#define NK_LI 10
#define NK_QUOTE 11
#define NK_CODE 12
#define NK_HR 13
#define NK_TABLE 14
#define NK_TEXT 15
#define NK_WIKI 16
#define NK_EMBED 17
#define NK_TAG 18
#define NK_TASK 19
#define NK_FN 20
#define NK_FNDEF 21
#define NK_HIGH 22
#define NK_MATH 23
#define NK_MATHB 24
#define NK_FM 25
#define NK_IMAGE 26
#define NK_TD 27
#define NK_BOLD 28
#define NK_ITALIC 29
#define NK_STRIKE 30
#define NK_LINK 31

datavtype Hist =
  | HNil of ()
  | HCons of (Buf, int, Hist)

fun hist_free(h: Hist): void =
  case+ h of
  | ~HNil() => ()
  | ~HCons(b, _, rest) => let
      val () = buf_free(b)
    in
      hist_free(rest)
    end

fun hist_drop_oldest(h: Hist): Hist =
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
      | _ => HCons(b, c, hist_drop_oldest(rest))

fun hist_len(h: !Hist): int =
  case+ h of
  | HNil() => 0
  | HCons(_, _, rest) => iadd(1, hist_len(rest))

fun hist_trim(h: Hist): Hist =
  case+ ige(hist_len(h), 35) of
  | true => hist_drop_oldest(h)
  | false => h

datavtype Doc_ = DOC of @{
  gap= Buf, lines= Buf, liney= Buf, nodes= Buf
, uhist= Hist, rhist= Hist
, lo= int, hi= int, len= int
, caret= int, anchor= int
, nlines= int, nnodes= int, span= int
, last_op= int, typing_cnt= int, is_md= int
}
assume Doc = Doc_

implement doc_open() = DOC(@{
  gap= buf_make(256), lines= buf_make(64 * 4), liney= buf_make(64 * 8), nodes= buf_make(64 * NS * 4)
, uhist= HNil(), rhist= HNil()
, lo= 0, hi= 256, len= 0
, caret= 0, anchor= 0
, nlines= 1, nnodes= 0, span= 0
, last_op= 0, typing_cnt= 0, is_md= 1
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
        if w = 0 then s.lo
        else if w = 1 then s.hi
        else if w = 2 then s.len
        else if w = 3 then s.caret
        else if w = 4 then s.anchor
        else if w = 5 then s.nlines
        else if w = 6 then s.nnodes
        else s.span
    in
      fold@(d); v
    end

fun dset(d: !Doc, w: int, v: int): void =
  case+ d of
  | @DOC(s) => let
      val () =
        if w = 0 then s.lo := v
        else if w = 1 then s.hi := v
        else if w = 2 then s.len := v
        else if w = 3 then s.caret := v
        else if w = 4 then s.anchor := v
        else if w = 5 then s.nlines := v
        else if w = 6 then s.nnodes := v
        else s.span := v
    in
      fold@(d)
    end

implement doc_len(d) = dget(d, 2)
implement doc_caret(d) = dget(d, 3)
implement doc_anchor(d) = dget(d, 4)
implement doc_nlines(d) = dget(d, 5)
implement doc_nnodes(d) = dget(d, 6)
implement doc_span(d) = dget(d, 7)

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

fun put_nodes(d: !Doc, b: Buf): void =
  case+ d of
  | @DOC(s) => let
      val old = s.nodes
      val () = s.nodes := b
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
  val lo = dget(d, 0)
  val hi = dget(d, 1)
  val p = if i < lo then i else iadd(hi, isub(i, lo))
in
  gap_get(d, p)
end

fun copy_fwd(src: !Buf, so: int, dst: !Buf, dst0: int, n: int): void = let
  var i: int = 0
in
  while (ilt(i, n)) (
    buf_set(dst, iadd(dst0, i), buf_get(src, iadd(so, i)));
    i := iadd(i, 1)
  )
end

fun copy_fwd_same(b: !Buf, so: int, dst0: int, n: int): void = let
  var i: int = 0
in
  while (ilt(i, n)) (
    buf_set(b, iadd(dst0, i), buf_get(b, iadd(so, i)));
    i := iadd(i, 1)
  )
end

fun copy_back_same(b: !Buf, so: int, dst0: int, n: int): void = let
  var i: int = isub(n, 1)
in
  while (ige(i, 0)) (
    buf_set(b, iadd(dst0, i), buf_get(b, iadd(so, i)));
    i := isub(i, 1)
  )
end

fun gap_grow(d: !Doc, need: int): void = let
  val lo = dget(d, 0)
  val hi = dget(d, 1)
  val len = dget(d, 2)
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
  val () = dset(d, 1, nhi)
in
end

fun gap_move(d: !Doc, at0: int): void = let
  val len = dget(d, 2)
  val at = if at0 < 0 then 0 else if at0 > len then len else at0
  val lo = dget(d, 0)
  val hi = dget(d, 1)
in
  if ieq(at, lo) then ()
  else if ilt(at, lo) then let
    val n = isub(lo, at)
    val b = take_gap(d)
    val () = copy_back_same(b, at, isub(hi, n), n)
    val () = put_gap(d, b)
    val () = dset(d, 0, at)
    val () = dset(d, 1, isub(hi, n))
  in
  end else let
    val n = isub(at, lo)
    val b = take_gap(d)
    val () = copy_fwd_same(b, hi, lo, n)
    val () = put_gap(d, b)
    val () = dset(d, 0, at)
    val () = dset(d, 1, iadd(hi, n))
  in
  end
end

fun gap_room(d: !Doc, n: int): void = let
  val lo = dget(d, 0)
  val hi = dget(d, 1)
in
  if isub(hi, lo) >= n then () else let
    val () = gap_grow(d, n)
  in
    gap_room(d, n)
  end
end

fun line_set(d: !Doc, i: int, v: int): void =
  case+ d of
  | @DOC(s) => let
      val () = if imul(iadd(i, 1), 4) >= buf_cap(s.lines) then buf_resize(s.lines, imul(iadd(i, 8), 8)) else ()
      val () = buf_set32(s.lines, i, v)
    in
      fold@(d)
    end

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

implement doc_line_step(d, i) =
  case+ d of
  | @DOC(s) => let
      val v = if i >= 0 andalso i < s.nlines then buf_get32(s.liney, iadd(imul(i, 2), 1)) else 0
    in
      fold@(d); v
    end

fun rebuild_lines(d: !Doc): void =
  case+ d of
  | @DOC(s) => let
      val n = s.len
      val lo = s.lo
      val hi = s.hi
      val gp = buf_ptr(s.gap)
      val gcap = buf_cap(s.gap)
      val () = if buf_cap(s.lines) < 4096 then buf_resize(s.lines, 4096) else ()
      val () = buf_set32(s.lines, 0, 0)
      var i: int = 0
      var ln: int = 1
    in
      while (ilt(i, n)) (
        let
          val b = if ilt(i, lo) then mem_byte(gp, gcap, i)
                  else mem_byte(gp, gcap, iadd(hi, isub(i, lo)))
        in
          if ieq(b, 10) then let
            val need = imul(iadd(ln, 1), 4)
            val () = if buf_cap(s.lines) < need then buf_resize(s.lines, imax(imul(need, 2), 4096)) else ()
            val () = buf_set32(s.lines, ln, iadd(i, 1))
            val () = ln := iadd(ln, 1)
          in
          end else ();
          i := iadd(i, 1)
        end
      );
      s.nlines := ln;
      fold@(d)
    end

fun line_bsearch(d: !Doc, off: int, lo: int, hi: int, best: int): int =
  if igt(lo, hi) then best
  else let
    val mid = iadd(lo, idiv(isub(hi, lo), 2))
    val st = doc_line_start(d, mid)
  in
    if ile(st, off) then line_bsearch(d, off, iadd(mid, 1), hi, mid)
    else line_bsearch(d, off, lo, isub(mid, 1), best)
  end

implement doc_line_of(d, off) = let
  val n = dget(d, 5)
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

fun node_room(d: !Doc): void =
  case+ d of
  | @DOC(s) => let
      val need = imul(iadd(s.nnodes, 2), NS * 4)
      val () = if buf_cap(s.nodes) < need then buf_resize(s.nodes, imul(need, 2)) else ()
    in
      fold@(d)
    end

fun npush(d: !Doc, kind: int, st: int, en: int, depth: int, aux: int): void = let
  val () = node_room(d)
  val i = dget(d, 6)
  var f: int = 0
  val () = while (f < NS) (nset(d, i, f, 0); f := iadd(f, 1))
  val () = nset(d, i, 0, kind)
  val () = nset(d, i, 1, st)
  val () = nset(d, i, 2, en)
  val () = nset(d, i, 3, depth)
  val () = nset(d, i, 6, ~1)
  val () = nset(d, i, 7, ~1)
  val () = nset(d, i, 8, ~1)
  val () = nset(d, i, 10, aux)
  val () = dset(d, 6, iadd(i, 1))
in
end

fun copy_node(src: !Buf, i: int, d: !Doc, delta: int): void = let
  val kind = buf_get32(src, iadd(imul(i, NS), 0))
  val st = iadd(buf_get32(src, iadd(imul(i, NS), 1)), delta)
  val en = iadd(buf_get32(src, iadd(imul(i, NS), 2)), delta)
  val depth = buf_get32(src, iadd(imul(i, NS), 3))
  val aux = buf_get32(src, iadd(imul(i, NS), 10))
  val col = buf_get32(src, iadd(imul(i, NS), 4))
  val () = npush(d, kind, st, en, depth, aux)
  val id = isub(dget(d, 6), 1)
  val () = nset(d, id, 4, col)
in
end

implement doc_push_node(d, kind, st, en, depth, aux) =
  npush(d, kind, st, en, depth, aux)

fun copy_kept(old: !Buf, d: !Doc, i: int, n: int, rs: int, re: int, delta: int, which: int): void =
  if ige(i, n) then ()
  else let
    val st = buf_get32(old, iadd(imul(i, NS), 1))
    val en = buf_get32(old, iadd(imul(i, NS), 2))
    val () =
      if ieq(which, 0) then (
        if ile(en, rs) then copy_node(old, i, d, 0) else ()
      ) else (
        if ige(st, re) then copy_node(old, i, d, delta) else ()
      )
  in
    copy_kept(old, d, iadd(i, 1), n, rs, re, delta, which)
  end

fun salvage(d: !Doc, rs: int, re: int, delta: int): void = let
  val is_md = doc_is_md(d)
in
  if ieq(is_md, 0) then let
    val () = dset(d, 6, 0)
  in
  end else let
    val n = dget(d, 6)
    val old = take_nodes(d)
    val () = dset(d, 6, 0)
    val () = copy_kept(old, d, 0, n, rs, re, delta, 0)
    val () = doc_parse_range(d, rs, iadd(re, delta))
    val () = copy_kept(old, d, 0, n, rs, re, delta, 1)
    val () = buf_free(old)
    val () = dset(d, 7, iadd(isub(re, rs), delta))
  in
  end
end

fun dirty(d: !Doc, at: int, rs: &int >> _, re: &int >> _): void = let
  val len = dget(d, 2)
  val line = doc_line_of(d, at)
  val a = if line > 0 then isub(line, 1) else 0
  val b0 = iadd(line, 2)
  val b = if b0 < dget(d, 5) then b0 else dget(d, 5)
  val () = rs := doc_line_start(d, a)
  val re0 = if ige(b, dget(d, 5)) then len else doc_line_start(d, b)
  val () = re := re0
in
end

fun parent_of(d: !Doc, i: int, j: int, steps: int): int =
  if ilt(j, 0) orelse igt(steps, 80) then ~1
  else let
    val st = nget(d, i, 1)
    val en = nget(d, i, 2)
  in
    if ile(nget(d, j, 1), st) andalso ige(nget(d, j, 2), en) andalso igt(nget(d, j, 2), nget(d, j, 1)) then j
    else parent_of(d, i, isub(j, 1), iadd(steps, 1))
  end

fun next_sib(d: !Doc, n: int, p: int, k: int, steps: int): int =
  if ige(k, n) orelse igt(steps, 80) then ~1
  else if ieq(nget(d, k, 6), p) then k
  else next_sib(d, n, p, iadd(k, 1), iadd(steps, 1))

fun relink_clear(d: !Doc, n: int, i: int): void =
  if ige(i, n) then ()
  else let
    val () = nset(d, i, 6, ~1)
    val () = nset(d, i, 7, ~1)
    val () = nset(d, i, 8, ~1)
  in
    relink_clear(d, n, iadd(i, 1))
  end

fun relink_parents(d: !Doc, n: int, i: int): void =
  if ige(i, n) then ()
  else let
    val p = parent_of(d, i, isub(i, 1), 0)
    val () = nset(d, i, 6, p)
    val () = if ige(p, 0) andalso ilt(nget(d, p, 8), 0) then nset(d, p, 8, i) else ()
  in
    relink_parents(d, n, iadd(i, 1))
  end

fun relink_next(d: !Doc, n: int, i: int): void =
  if ige(i, n) then ()
  else let
    val p = nget(d, i, 6)
    val () = nset(d, i, 7, next_sib(d, n, p, iadd(i, 1), 0))
  in
    relink_next(d, n, iadd(i, 1))
  end

fun relink(d: !Doc): void = let
  val is_md = doc_is_md(d)
in
  if ieq(is_md, 0) then ()
  else let
    val n = dget(d, 6)
    val () = relink_clear(d, n, 0)
    val () = relink_parents(d, n, 0)
  in
    relink_next(d, n, 0)
  end
end

fun block_kind(k: int): int =
  if ieq(k, NK_TEXT) orelse ieq(k, NK_WIKI) orelse ieq(k, NK_EMBED) orelse ieq(k, NK_TAG) orelse ieq(k, NK_FN) orelse ieq(k, NK_HIGH) orelse ieq(k, NK_MATH) orelse ieq(k, NK_MATHB) orelse ieq(k, NK_TD) then 0 else 1

fun hide_until(d: !Doc, i: int, n: int, hk: int): void =
  if ige(i, n) then ()
  else let
    val k = nget(d, i, 0)
  in
    if ige(k, NK_H1) andalso ile(k, NK_H6) andalso ile(k, hk) then ()
    else let
      val () = nset(d, i, 9, 1)
      val () = nset(d, i, 5, 0)
    in
      hide_until(d, iadd(i, 1), n, hk)
    end
  end

fun hide_list(d: !Doc, i: int, n: int, depth: int): void =
  if ige(i, n) then ()
  else let
    val k = nget(d, i, 0)
    val dp = nget(d, i, 3)
  in
    if (ieq(k, NK_LI) orelse ieq(k, NK_TASK) orelse ieq(k, NK_UL) orelse ieq(k, NK_OL)) andalso ile(dp, depth) then ()
    else if block_kind(k) = 1 andalso ile(dp, depth) andalso ine(k, NK_TEXT) then ()
    else let
      val () = nset(d, i, 9, 1)
      val () = nset(d, i, 5, 0)
    in
      hide_list(d, iadd(i, 1), n, depth)
    end
  end

fun count_nl(d: !Doc, p: int, en: int, lines: int): int =
  if ige(p, en) then lines
  else count_nl(d, iadd(p, 1), en, iif(ieq(doc_byte(d, p), 10), iadd(lines, 1), lines))

fun clear_hide(d: !Doc, n: int, i: int): void =
  if ige(i, n) then ()
  else let
    val () = nset(d, i, 9, 0)
  in
    clear_hide(d, n, iadd(i, 1))
  end

fun node_height(d: !Doc, i: int, lh: int): int = let
  val k = nget(d, i, 0)
  val lines = count_nl(d, nget(d, i, 1), nget(d, i, 2), 1)
in
  if ine(nget(d, i, 9), 0) then 0
  else if ieq(k, NK_EMBED) then let
    val a = nget(d, i, 10)
  in
    if igt(a, 8) then a else 0
  end
  else if ieq(block_kind(k), 0) then 0
  else if ieq(k, NK_HR) then 12
  else if ieq(k, NK_IMAGE) then let
    val a = nget(d, i, 10)
  in
    if igt(a, 8) then a else 96
  end
  else imul(lines, lh)
end

fun place_one(d: !Doc, n: int, i: int, lh: int): void =
  if ige(i, n) then ()
  else let
    val k = nget(d, i, 0)
    val h = node_height(d, i, lh)
    val () = nset(d, i, 5, h)
    val () =
      if ige(k, NK_H1) andalso ile(k, NK_H6) andalso ine(nget(d, i, 4), 0) then hide_until(d, iadd(i, 1), n, k)
      else if (ieq(k, NK_LI) orelse ieq(k, NK_TASK)) andalso ine(nget(d, i, 4), 0) then hide_list(d, iadd(i, 1), n, nget(d, i, 3))
      else ()
  in
    place_one(d, n, iadd(i, 1), lh)
  end

fun stack_y(d: !Doc, n: int, i: int, y: int): int =
  if ige(i, n) then y
  else let
    val () = nset(d, i, 13, y)
  in
    stack_y(d, n, iadd(i, 1), iadd(y, nget(d, i, 5)))
  end

fun line_hidden(d: !Doc, st: int, en: int, i: int, n: int, saw: int): int =
  if ige(i, n) then saw
  else let
    val ns = nget(d, i, 1)
    val ne = nget(d, i, 2)
    val hit = if ilt(ns, en) andalso igt(ne, st) then 1 else 0
  in
    if ieq(hit, 1) andalso ieq(nget(d, i, 9), 0) then 0
    else line_hidden(d, st, en, iadd(i, 1), n, iif(ieq(hit, 1), 1, saw))
  end

fun widget_h(d: !Doc, st: int, en: int, i: int, n: int, acc: int): int =
  if ige(i, n) then acc
  else let
    val k = nget(d, i, 0)
    val ns = nget(d, i, 1)
    val h = nget(d, i, 5)
    val use = if ieq(nget(d, i, 9), 0) andalso ige(ns, st) andalso ilt(ns, en) andalso (ieq(k, NK_IMAGE) orelse ieq(k, NK_EMBED)) andalso igt(h, acc) then h else acc
  in
    widget_h(d, st, en, iadd(i, 1), n, use)
  end

fun assign_lines(d: !Doc, lh: int, line: int, y: int): int =
  if ige(line, dget(d, 5)) then y
  else let
    val n = dget(d, 6)
    val st = doc_line_start(d, line)
    val en = if iadd(line, 1) < dget(d, 5) then doc_line_start(d, iadd(line, 1)) else dget(d, 2)
    val hid = line_hidden(d, st, en, 0, n, 0)
    val extra = if ieq(hid, 1) then 0 else widget_h(d, st, en, 0, n, 0)
    val step = if ieq(hid, 1) then 0 else iadd(lh, extra)
    val () = line_put(d, line, y, step)
  in
    assign_lines(d, lh, iadd(line, 1), iadd(y, step))
  end

fun stamp_nodes(d: !Doc, lh: int, i: int): void =
  if ige(i, dget(d, 6)) then ()
  else let
    val line = doc_line_of(d, nget(d, i, 1))
    val ly = doc_line_y(d, line)
    val k = nget(d, i, 0)
    val y = if ieq(k, NK_IMAGE) orelse ieq(k, NK_EMBED) then iadd(ly, lh) else ly
    val () = nset(d, i, 13, y)
  in
    stamp_nodes(d, lh, iadd(i, 1))
  end

fun fill_plain_lines(d: !Doc, lh: int, nlines: int): void =
  case+ d of
  | @DOC(s) => let
      val need = imul(iadd(nlines, 1), 8)
      val () = if buf_cap(s.liney) < need then buf_resize(s.liney, imax(imul(need, 2), 4096)) else ()
      var i: int = 0
    in
      while (ilt(i, nlines)) (
        buf_set32(s.liney, imul(i, 2), imul(i, lh));
        buf_set32(s.liney, iadd(imul(i, 2), 1), lh);
        i := iadd(i, 1)
      );
      fold@(d)
    end

implement doc_layout(d, lh0) = let
  val lh = if ilt(lh0, 8) then 8 else lh0
  val is_md = doc_is_md(d)
  val n = dget(d, 6)
in
  if ieq(is_md, 0) orelse ieq(n, 0) then let
    val nlines = dget(d, 5)
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
  val () = dirty(d, at, rs, re)
  val delta = isub(dget(d, 2), oldlen)
  val () = rebuild_lines(d)
  val () = salvage(d, rs, re, delta)
in
  relink(d)
end

fun gap_put(d: !Doc, p: ptr, n: int): void = let
  val () = gap_room(d, n)
  val lo = dget(d, 0)
  var i: int = 0
in
  while (i < n) (
    gap_set(d, iadd(lo, i), mem_byte(p, n, i));
    i := iadd(i, 1)
  );
  dset(d, 0, iadd(lo, n));
  dset(d, 2, iadd(dget(d, 2), n))
end

fun sel_span(d: !Doc, a: &int >> _, b: &int >> _): void = let
  val c = dget(d, 3)
  val k = dget(d, 4)
in
  if c < k then (a := c; b := k) else (a := k; b := c)
end

fun remove_between(d: !Doc, a0: int, b0: int): void = let
  val len = dget(d, 2)
  val a = if a0 < 0 then 0 else a0
  val b = if b0 > len then len else b0
in
  if ile(b, a) then ()
  else let
    val old = dget(d, 2)
    val () = gap_move(d, a)
    val hi = dget(d, 1)
    val () = dset(d, 1, iadd(hi, isub(b, a)))
    val () = dset(d, 2, isub(len, isub(b, a)))
    val () = dset(d, 3, a)
    val () = dset(d, 4, a)
  in
    reparse(d, a, old)
  end
end

implement doc_slice(d, a0, b0, dst, cap) = let
  val len = dget(d, 2)
  val a = if a0 < 0 then 0 else a0
  val b = if b0 > len then len else b0
  val n = if igt(isub(b, a), cap) then cap else isub(b, a)
  var i: int = 0
in
  while (ilt(i, n)) (
    mem_set_byte(dst, cap, i, doc_byte(d, iadd(a, i)));
    i := iadd(i, 1)
  );
  n
end

implement doc_text(d, dst) = let
  val n = dget(d, 2)
  val () = buf_resize(dst, iadd(n, 1))
  var i: int = 0
in
  while (i < n) (
    buf_set(dst, i, doc_byte(d, i));
    i := iadd(i, 1)
  );
  buf_set(dst, n, 0);
  buf_set_len(dst, n)
end

fun doc_snapshot_curr(d: !Doc): Buf = let
  var b = buf_make(iadd(doc_len(d), 1))
  val () = doc_text(d, b)
in
  b
end

fun doc_record(d: !Doc, opk: int): void = let
  val lo = case+ d of
    | @DOC(s) => let
        val o = s.last_op
      in
        fold@(d); o
      end
  val tc = case+ d of
    | @DOC(s) => let
        val c = s.typing_cnt
      in
        fold@(d); c
      end
in
  if ieq(opk, 1) andalso ieq(lo, 1) andalso ilt(tc, 8) then
    case+ d of
    | @DOC(s) => let
        val () = s.typing_cnt := iadd(tc, 1)
      in
        fold@(d)
      end
  else let
    val snap = doc_snapshot_curr(d)
    val cur_c = doc_caret(d)
    var u = take_uhist(d)
    val u2 = hist_trim(u)
    val u3 = HCons(snap, cur_c, u2)
    val () = put_uhist(d, u3)
    val () = put_rhist(d, HNil())
  in
    case+ d of
    | @DOC(s) => let
        val () = s.last_op := opk
        val () = s.typing_cnt := 0
      in
        fold@(d)
      end
  end
end

fun doc_insert_core(d: !Doc, p: ptr, n: int): void = let
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
  val () = if igt(b, a) then remove_between(d, a, b) else ()
  val at = dget(d, 3)
  var rs: int = 0
  var re: int = 0
  val () = dirty(d, at, rs, re)
  val old = dget(d, 2)
  val () = gap_move(d, at)
  val () = gap_put(d, p, n)
  val () = dset(d, 3, iadd(at, n))
  val () = dset(d, 4, iadd(at, n))
  val delta = isub(dget(d, 2), old)
  val () = rebuild_lines(d)
  val () = salvage(d, rs, re, delta)
in
  relink(d)
end

implement doc_insert(d, p, n) = let
  val () = if ieq(n, 1) then let
      val b = mem_byte(p, 1, 0)
    in
      if ieq(b, 32) orelse ieq(b, 10) then doc_record(d, 2) else doc_record(d, 1)
    end else doc_record(d, 2)
in
  doc_insert_core(d, p, n)
end

fun utf8_prev(d: !Doc, i: int): int =
  if ile(i, 1) then 0
  else let
    fun back(d: !Doc, k: int, limit: int): int =
      if ile(k, 0) then 0
      else if ile(limit, 0) then k
      else let
        val b = doc_byte(d, isub(k, 1))
      in
        if b < 128 orelse b >= 192 then isub(k, 1)
        else back(d, isub(k, 1), isub(limit, 1))
      end
  in
    back(d, i, 4)
  end

fun utf8_align(d: !Doc, i: int): int =
  if ile(i, 0) then 0
  else if ige(i, dget(d, 2)) then dget(d, 2)
  else let
    val b = doc_byte(d, i)
  in
    if b < 128 orelse b >= 192 then i
    else utf8_prev(d, iadd(i, 1))
  end

fun utf8_next(d: !Doc, i: int): int = let
  val len = dget(d, 2)
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
  val () = doc_record(d, 2)
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
in
  if igt(b, a) then remove_between(d, a, b)
  else let
    val c = dget(d, 3)
  in
    if c <= 0 then () else remove_between(d, utf8_prev(d, c), c)
  end
end

implement doc_delete(d) = let
  val () = doc_record(d, 2)
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
in
  if igt(b, a) then remove_between(d, a, b)
  else let
    val c = dget(d, 3)
    val n = utf8_next(d, c)
  in
    if ile(n, c) then () else remove_between(d, c, n)
  end
end

implement doc_set_caret(d, i, keep) = let
  val len = dget(d, 2)
  val c = if i < 0 then 0 else if i > len then len else i
  val () = dset(d, 3, c)
in
  if keep = 0 then dset(d, 4, c) else ()
end

implement doc_left(d) = doc_left_k(d, 0)
implement doc_right(d) = doc_right_k(d, 0)
implement doc_home(d) = doc_home_k(d, 0)
implement doc_end(d) = doc_end_k(d, 0)
implement doc_up(d) = doc_up_k(d, 0)
implement doc_down(d) = doc_down_k(d, 0)

implement doc_left_k(d, keep) = let
  val c = dget(d, 3)
  val a = dget(d, 4)
  val target = if keep = 0 andalso ine(c, a) then imin(c, a) else utf8_prev(d, c)
in
  doc_set_caret(d, target, keep)
end

implement doc_right_k(d, keep) = let
  val c = dget(d, 3)
  val a = dget(d, 4)
  val target = if keep = 0 andalso ine(c, a) then imax(c, a) else utf8_next(d, c)
in
  doc_set_caret(d, target, keep)
end

implement doc_home_k(d, keep) = let
  val c = doc_line_start(d, doc_line_of(d, dget(d, 3)))
in
  doc_set_caret(d, c, keep)
end

implement doc_end_k(d, keep) = let
  val line = doc_line_of(d, dget(d, 3))
  val n = dget(d, 5)
  val e = if iadd(line, 1) >= n then dget(d, 2) else doc_line_start(d, iadd(line, 1))
  val c = if igt(e, 0) andalso ieq(doc_byte(d, isub(e, 1)), 10) then isub(e, 1) else e
in
  doc_set_caret(d, c, keep)
end

implement doc_up_k(d, keep) = let
  val c = dget(d, 3)
  val line = doc_line_of(d, c)
  val col = isub(c, doc_line_start(d, line))
in
  if line <= 0 then doc_set_caret(d, 0, keep)
  else let
    val st = doc_line_start(d, isub(line, 1))
    val en = doc_line_start(d, line)
    val stop = if igt(en, st) andalso ieq(doc_byte(d, isub(en, 1)), 10) then isub(en, 1) else en
    val at = utf8_align(d, imin(iadd(st, col), stop))
  in
    doc_set_caret(d, at, keep)
  end
end

implement doc_down_k(d, keep) = let
  val c = dget(d, 3)
  val line = doc_line_of(d, c)
  val n = dget(d, 5)
  val col = isub(c, doc_line_start(d, line))
in
  if iadd(line, 1) >= n then doc_set_caret(d, dget(d, 2), keep)
  else let
    val st = doc_line_start(d, iadd(line, 1))
    val en = if iadd(line, 2) >= n then dget(d, 2) else doc_line_start(d, iadd(line, 2))
    val stop = if igt(en, st) andalso ieq(doc_byte(d, isub(en, 1)), 10) then isub(en, 1) else en
  in
    doc_set_caret(d, utf8_align(d, imin(iadd(st, col), stop)), keep)
  end
end

fun doc_char_class(b: int): int =
  if b <= 32 then 0
  else if (b >= 97 andalso b <= 122) orelse (b >= 65 andalso b <= 90) orelse (b >= 48 andalso b <= 57) orelse (b >= 128) then 1
  else 2

fun word_left_pos(d: !Doc, cur: int): int =
  if cur <= 0 then 0
  else let
    var i: int = cur
    val () = while (i > 0 andalso doc_char_class(doc_byte(d, isub(i, 1))) = 0) (
      i := utf8_prev(d, i)
    )
    val () = if i > 0 then let
      val cls = doc_char_class(doc_byte(d, isub(i, 1)))
      val () = while (i > 0 andalso doc_char_class(doc_byte(d, isub(i, 1))) = cls) (
        i := utf8_prev(d, i)
      )
    in
    end else ()
  in
    i
  end

fun word_right_pos(d: !Doc, cur: int): int = let
  val len = dget(d, 2)
in
  if cur >= len then len
  else let
    var i: int = cur
    val cls = doc_char_class(doc_byte(d, i))
    val () = if cls = 0 then (
      while (i < len andalso doc_char_class(doc_byte(d, i)) = 0) (
        i := utf8_next(d, i)
      )
    ) else let
      val () = while (i < len andalso doc_char_class(doc_byte(d, i)) = cls) (
        i := utf8_next(d, i)
      )
      val () = while (i < len andalso doc_char_class(doc_byte(d, i)) = 0 andalso doc_byte(d, i) != 10) (
        i := utf8_next(d, i)
      )
    in
    end
  in
    i
  end
end

implement doc_word_left(d, keep) = let
  val c = dget(d, 3)
  val target = word_left_pos(d, c)
in
  doc_set_caret(d, target, keep)
end

implement doc_word_right(d, keep) = let
  val c = dget(d, 3)
  val target = word_right_pos(d, c)
in
  doc_set_caret(d, target, keep)
end

implement doc_del_word_left(d) = let
  val () = doc_record(d, 2)
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
in
  if igt(b, a) then remove_between(d, a, b)
  else let
    val c = dget(d, 3)
    val target = word_left_pos(d, c)
  in
    if target < c then remove_between(d, target, c) else ()
  end
end

implement doc_del_word_right(d) = let
  val () = doc_record(d, 2)
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
in
  if igt(b, a) then remove_between(d, a, b)
  else let
    val c = dget(d, 3)
    val target = word_right_pos(d, c)
  in
    if target > c then remove_between(d, c, target) else ()
  end
end

implement doc_doc_start(d, keep) = doc_set_caret(d, 0, keep)
implement doc_doc_end(d, keep) = doc_set_caret(d, dget(d, 2), keep)

implement doc_page_up(d, nlines, keep) = let
  var k: int = 0
in
  while (k < nlines) (
    doc_up_k(d, keep);
    k := iadd(k, 1)
  )
end

implement doc_page_down(d, nlines, keep) = let
  var k: int = 0
in
  while (k < nlines) (
    doc_down_k(d, keep);
    k := iadd(k, 1)
  )
end

implement doc_save(d, path) = let
  var b = buf_make(16)
  val () = doc_text(d, b)
  val fd = fs_open_write(path)
in
  if fd < 0 then let
    val () = buf_free(b)
  in
    0
  end else let
    val n = fs_write(fd, buf_ptr(b), buf_len(b))
    val () = fs_close(fd)
    val () = buf_free(b)
  in
    if n >= 0 then 1 else 0
  end
end

implement doc_save_vfs(d, path) = let
  val plen = c_strlen(path)
in
  if plen <= 0 then 0
  else let
    var vbuf = buf_make(512)
    val () = fs_vfs_path(path, buf_ptr(vbuf), 511)
    val vp = ptr_string(buf_ptr(vbuf))
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
    val () = fs_vfs_path(path, buf_ptr(vbuf), 511)
    val vp = ptr_string(buf_ptr(vbuf))
    val vlen = c_strlen(vp)
    val _ul = if igt(vlen, 0) andalso ieq(fs_exists(vp), 1) then fs_unlink(vp) else 0
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
  val () = dset(d, 0, 0)
  val () = dset(d, 1, c)
  val () = dset(d, 2, 0)
  val () = dset(d, 3, 0)
  val () = dset(d, 4, 0)
  val () = dset(d, 6, 0)
in
  doc_insert_core(d, p, n)
end

fun replace_all(d: !Doc, p: ptr, n: int): void = let
  val () = put_uhist(d, HNil())
  val () = put_rhist(d, HNil())
in
  replace_all_raw(d, p, n)
end

implement doc_undo(d) = let
  var u = take_uhist(d)
in
  case+ u of
  | ~HNil() => put_uhist(d, HNil())
  | ~HCons(snap_b, snap_c, rest_u) => let
      val () = put_uhist(d, rest_u)
      val cur_snap = doc_snapshot_curr(d)
      val cur_c = doc_caret(d)
      var r = take_rhist(d)
      val r2 = hist_trim(r)
      val r3 = HCons(cur_snap, cur_c, r2)
      val () = put_rhist(d, r3)
      val sn = buf_len(snap_b)
      val sp = buf_ptr(snap_b)
      val () = replace_all_raw(d, sp, sn)
      val () = doc_set_caret(d, snap_c, 0)
      val () = buf_free(snap_b)
    in
      case+ d of
      | @DOC(s) => let
          val () = s.last_op := 0
          val () = s.typing_cnt := 0
        in
          fold@(d)
        end
    end
end

implement doc_redo(d) = let
  var r = take_rhist(d)
in
  case+ r of
  | ~HNil() => put_rhist(d, HNil())
  | ~HCons(snap_b, snap_c, rest_r) => let
      val () = put_rhist(d, rest_r)
      val cur_snap = doc_snapshot_curr(d)
      val cur_c = doc_caret(d)
      var u = take_uhist(d)
      val u2 = hist_trim(u)
      val u3 = HCons(cur_snap, cur_c, u2)
      val () = put_uhist(d, u3)
      val sn = buf_len(snap_b)
      val sp = buf_ptr(snap_b)
      val () = replace_all_raw(d, sp, sn)
      val () = doc_set_caret(d, snap_c, 0)
      val () = buf_free(snap_b)
    in
      case+ d of
      | @DOC(s) => let
          val () = s.last_op := 0
          val () = s.typing_cnt := 0
        in
          fold@(d)
        end
    end
end

implement doc_wrap(d, pre, plen, suf, suflen) = let
  val () = doc_record(d, 2)
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
in
  if igt(b, a) then let
    val slen = isub(b, a)
    var sel_buf = buf_make(iadd(slen, 1))
    val _n = doc_slice(d, a, b, buf_ptr(sel_buf), slen)
    val () = buf_set_len(sel_buf, slen)
    val () = remove_between(d, a, b)
    val () = doc_insert_core(d, c_str_ptr(pre), plen)
    val () = doc_insert_core(d, buf_ptr(sel_buf), slen)
    val () = doc_insert_core(d, c_str_ptr(suf), suflen)
    val () = buf_free(sel_buf)
    val new_pos = iadd(a, iadd(plen, iadd(slen, suflen)))
    val () = doc_set_caret(d, new_pos, 0)
  in
  end else let
    val () = doc_insert_core(d, c_str_ptr(pre), plen)
    val () = doc_insert_core(d, c_str_ptr(suf), suflen)
    val mid = iadd(a, plen)
    val () = doc_set_caret(d, mid, 0)
  in
  end
end

implement doc_load(d, path) = let
  var vbuf = buf_make(512)
  val () = fs_vfs_path(path, buf_ptr(vbuf), 511)
  val vp = ptr_string(buf_ptr(vbuf))
  val vlen = c_strlen(vp)
  val has_vfs = if igt(vlen, 0) andalso ieq(fs_exists(vp), 1) andalso igt(fs_size(vp), 0) then 1 else 0
  val actual_path = if ieq(has_vfs, 1) then vp else path
  val sz = fs_size(actual_path)
in
  if sz < 0 orelse sz > 50000000 then let
    val () = buf_free(vbuf)
  in
    0
  end else let
    val fd = fs_open_read(actual_path)
  in
    if fd < 0 then let
      val () = buf_free(vbuf)
    in
      0
    end else let
      val b = buf_make(iadd(sz, 1))
      val n = fs_read(fd, buf_ptr(b), sz)
      val () = fs_close(fd)
      val () = buf_free(vbuf)
      val () = buf_set_len(b, if n > 0 then n else 0)
      val plen = c_strlen(path)
      val is_md =
        if plen >= 3 andalso c_str_byte(path, isub(plen, 3)) = 46 andalso (c_str_byte(path, isub(plen, 2)) = 109 orelse c_str_byte(path, isub(plen, 2)) = 77) andalso (c_str_byte(path, isub(plen, 1)) = 100 orelse c_str_byte(path, isub(plen, 1)) = 68) then 1
        else if plen >= 9 andalso c_str_byte(path, isub(plen, 9)) = 46 then 1
        else 0
      val () = doc_set_md(d, is_md)
      val () = replace_all(d, buf_ptr(b), if n > 0 then n else 0)
      val () = buf_free(b)
    in
      1
    end
  end
end

implement doc_toggle(d, i) = let
  val n = dget(d, 6)
in
  if i < 0 orelse i >= n then ()
  else nset(d, i, 4, iif(ieq(nget(d, i, 4), 0), 1, 0))
end

fun task_box_find(d: !Doc, st: int, en: int, p: int): int =
  if ige(p, en) orelse ige(iadd(p, 2), dget(d, 2)) then ~1
  else if ieq(doc_byte(d, p), 91) andalso ieq(doc_byte(d, iadd(p, 2)), 93) then iadd(p, 1)
  else task_box_find(d, st, en, iadd(p, 1))

implement doc_toggle_task(d, i) = let
  val n = dget(d, 6)
in
  if i < 0 orelse i >= n then ()
  else if ine(nget(d, i, 0), NK_TASK) then ()
  else let
    val st = nget(d, i, 1)
    val en = nget(d, i, 2)
    val pos = task_box_find(d, st, en, st)
  in
    if pos < 0 then ()
    else let
      val cur = doc_byte(d, pos)
      val nxt = if ieq(cur, 32) then 120
                else if ieq(cur, 120) orelse ieq(cur, 88) then 47
                else 32
      var nb = buf_make(2)
      val () = buf_push(nb, nxt)
      val () = doc_set_caret(d, pos, 0)
      val () = doc_set_caret(d, iadd(pos, 1), 1)
      val () = doc_delete(d)
      val () = doc_insert(d, buf_ptr(nb), 1)
    in
      buf_free(nb)
    end
  end
end

implement column_w(avail) =
  if avail < 720 then avail else if avail > 850 then 850 else avail

implement column_x(pane, avail) = iadd(pane, idiv(isub(avail, column_w(avail)), 2))

fun has_kind(d: !Doc, k: int, i: int): int =
  if ige(i, dget(d, 6)) then 0
  else if ieq(nget(d, i, 0), k) then 1
  else has_kind(d, k, iadd(i, 1))

fun put_str(d: !Doc, s: string): void =
  doc_insert(d, c_str_ptr(s), c_strlen(s))

fun fill_paras(d: !Doc, i: int): void =
  if ige(i, 100) then ()
  else let
    val () = put_str(d, "paragraf\n\n")
  in
    fill_paras(d, iadd(i, 1))
  end

fun first_heading(d: !Doc, i: int): int =
  if ige(i, doc_nnodes(d)) then ~1
  else if ieq(doc_get(d, i, 0), NK_H1) then i
  else first_heading(d, iadd(i, 1))

implement doc_selftest() = let
  val d = doc_open()
  val () = put_str(d, "ab")
  val () = doc_left(d)
  val () = doc_backspace(d)
  val gap_ok = iif(ieq(doc_len(d), 1) andalso ieq(doc_byte(d, 0), 98) andalso ieq(doc_caret(d), 0), 1, 0)
  val () = doc_right(d)
  val () = put_str(d, "\n# Baslik\n\n- madde\n- [ ] gorev\n- [x] bitti\n\n> alinti\n\n```\nkod\n```\n\n| a | b |\n| --- | --- |\n| 1 | 2 |\n\n[[Sayfa|ad]] ![[Resim.png]] #etiket/alt ==vurgu== $x$ $$y$$\n\n[^1]: not\n")
  val () = put_str(d, "[[Sayfa#b]]\n")
  val sample = "---\ntitle: x\n---\n"
  val d2 = doc_open()
  val () = put_str(d2, sample)
  val fm = has_kind(d2, NK_FM, 0)
  val h = has_kind(d, NK_H1, 0)
  val li = has_kind(d, NK_LI, 0)
  val task = has_kind(d, NK_TASK, 0)
  val code = has_kind(d, NK_CODE, 0)
  val table = has_kind(d, NK_TABLE, 0)
  val quote = has_kind(d, NK_QUOTE, 0)
  val wiki = has_kind(d, NK_WIKI, 0)
  val img = has_kind(d, NK_IMAGE, 0)
  val tag = has_kind(d, NK_TAG, 0)
  val high = has_kind(d, NK_HIGH, 0)
  val math = has_kind(d, NK_MATH, 0)
  val mathb = has_kind(d, NK_MATHB, 0)
  val fndef = has_kind(d, NK_FNDEF, 0)
  val d3 = doc_open()
  val () = fill_paras(d3, 0)
  val mid = idiv(doc_len(d3), 2)
  val () = doc_set_caret(d3, mid, 0)
  val () = put_str(d3, "Z")
  val sp = doc_span(d3)
  val inc = iif(ilt(sp, 80) andalso igt(doc_len(d3), 500), 1, 0)
  val y0 = doc_layout(d, 18)
  val hi = first_heading(d, 0)
  val () = doc_toggle(d, hi)
  val y1 = doc_layout(d, 18)
  val folded = iif(ilt(hi, 0), 0, iif(ieq(doc_get(d, hi, 4), 1) andalso ieq(doc_get(d, iadd(hi, 1), 5), 0), 1, 0))
  val d4 = doc_open()
  val () = put_str(d4, "#etiket/alt\n")
  val tagline = iif(ieq(has_kind(d4, NK_TAG, 0), 1) andalso ilt(doc_nnodes(d4), 8), 1, 0)
  val col = iif(ieq(column_w(1000), 850) andalso ieq(column_w(800), 800) andalso ieq(column_w(400), 400) andalso ieq(column_x(0, 1000), 75), 1, 0)
  val d5 = doc_open()
  val () = put_str(d5, "deneme")
  val () = put_str(d5, " bir")
  val () = doc_undo(d5)
  val undo_ok = iif(ieq(doc_len(d5), 6), 1, 0)
  val () = doc_redo(d5)
  val redo_ok = iif(ieq(doc_len(d5), 10), 1, 0)
  val () = doc_set_caret(d5, 0, 0)
  val () = doc_set_caret(d5, 6, 1)
  val () = doc_wrap(d5, "**", 2, "**", 2)
  val wrap_ok = iif(ieq(doc_byte(d5, 0), 42) andalso ieq(doc_byte(d5, 1), 42), 1, 0)
  val () = doc_free(d5)

  val d_nav = doc_open()
  val () = put_str(d_nav, "hello world anthracite\n")
  val () = doc_doc_end(d_nav, 0)
  val end_c = doc_caret(d_nav)
  val () = doc_word_left(d_nav, 0)
  val w_left1 = doc_caret(d_nav)
  val () = doc_word_left(d_nav, 0)
  val w_left2 = doc_caret(d_nav)
  val () = doc_doc_start(d_nav, 0)
  val start_c = doc_caret(d_nav)
  val () = doc_word_right(d_nav, 0)
  val w_right1 = doc_caret(d_nav)
  val () = doc_del_word_right(d_nav)
  val del_len = doc_len(d_nav)
  val () = doc_free(d_nav)
  val nav_ok = iif(ieq(start_c, 0) andalso igt(end_c, 15) andalso ilt(w_left1, end_c) andalso ilt(w_left2, w_left1) andalso igt(w_right1, 0) andalso ilt(del_len, end_c), 1, 0)

  val () = println! ("gap=", gap_ok, " h=", h, " li=", li, " task=", task, " code=", code)
  val () = println! ("table=", table, " quote=", quote, " wiki=", wiki, " img=", img, " tag=", tag)
  val () = println! ("high=", high, " math=", math, " mathb=", mathb, " fn=", fndef, " fm=", fm)
  val () = println! ("span=", sp, " inc=", inc, " fold=", folded, " y0=", y0, " y=", y1, " col=", col, " tl=", tagline)
  val () = println! ("undo=", undo_ok, " redo=", redo_ok, " wrap=", wrap_ok, " nav=", nav_ok)
  val d_big = doc_open()
  val big_ok = doc_load(d_big, "build/CMakeFiles/CMakeConfigureLog.yaml")
  val big_lines = doc_nlines(d_big)
  val big_h = doc_layout(d_big, 18)
  val big_c_line = doc_line_of(d_big, isub(doc_len(d_big), 10))
  val () = doc_free(d_big)
  val () = println! ("big_load=", big_ok, " lines=", big_lines, " h=", big_h, " last_line=", big_c_line)

  val dvfs = doc_open()
  val () = put_str(dvfs, "vfs test content\n")
  val test_disk_p = "/tmp/anth_test_vfs.txt"
  val _ul0 = if ieq(fs_exists(test_disk_p), 1) then fs_unlink(test_disk_p) else 0
  val svfs_ok = doc_save_vfs(dvfs, test_disk_p)
  var vbuf = buf_make(512)
  val () = fs_vfs_path(test_disk_p, buf_ptr(vbuf), 511)
  val vpath = ptr_string(buf_ptr(vbuf))
  val in_vfs = fs_exists(vpath)
  val on_disk_yet = fs_exists(test_disk_p)
  val vfs_ok1 = iif(ieq(svfs_ok, 1) andalso ieq(in_vfs, 1) andalso ieq(on_disk_yet, 0), 1, 0)
  val sphys_ok = doc_save_physical(dvfs, test_disk_p)
  val on_disk_now = fs_exists(test_disk_p)
  val in_vfs_after = fs_exists(vpath)
  val vfs_ok2 = iif(ieq(sphys_ok, 1) andalso ieq(on_disk_now, 1) andalso ieq(in_vfs_after, 0), 1, 0)
  val _ul1 = fs_unlink(test_disk_p)
  val () = buf_free(vbuf)
  val () = doc_free(dvfs)
  val vfs_ok = iif(ieq(vfs_ok1, 1) andalso ieq(vfs_ok2, 1), 1, 0)
  val () = println! ("vfs_autosave=", vfs_ok, " in_ram=", vfs_ok1, " close_disk=", vfs_ok2)

  val () = doc_free(d)
  val () = doc_free(d2)
  val () = doc_free(d3)
  val () = doc_free(d4)
  val ok = iif(ieq(nav_ok, 1) andalso ieq(vfs_ok, 1) andalso ieq(gap_ok, 1) andalso ieq(h, 1) andalso ieq(li, 1) andalso ieq(task, 1) andalso ieq(code, 1) andalso ieq(table, 1) andalso ieq(quote, 1) andalso ieq(wiki, 1) andalso ieq(img, 1) andalso ieq(tag, 1) andalso ieq(high, 1) andalso ieq(math, 1) andalso ieq(mathb, 1) andalso ieq(fndef, 1) andalso ieq(fm, 1) andalso ieq(inc, 1) andalso ieq(folded, 1) andalso ieq(col, 1) andalso ieq(tagline, 1) andalso ieq(undo_ok, 1) andalso ieq(redo_ok, 1) andalso ieq(wrap_ok, 1), 1, 0)
in
  ok
end
