extern fun gap_room_fuel_exhausted(d: !Doc, n: int): void = "mac#anth_die_void"

fun gap_room_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, n: int): void =
  if recfuel > 0 then (
  let
    val lo = d_lo(d)
    val hi = d_hi(d)
  in
    if isub(hi, lo) >= n then () else let
      val () = gap_grow(d, n)
    in
      gap_room_with_fuel(recfuel - 1, d, n)
    end
  end
  ) else gap_room_fuel_exhausted(d, n)

fun gap_room(d: !Doc, n: int): void = gap_room_with_fuel(airlock_nat(MAX_REC_FUEL), d, n)

fun take_layout(d: !Doc): Buf =
  case+ d of
  | @DOC(s) => let
      val laybuf = s.lay
      val () = s.lay := buf_make(TAKE_LAYOUT_BUFFER_INITIAL_BYTES)
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
    val () = copy_bytes_forward(old, 0, fresh, 0, cap)
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

extern fun rebuild_scan_fuel_exhausted(lines: &Buf >> Buf, gap: !Buf, lo: int, hi: int, n: int, i: int, ln: int): int = "mac#anth_die_int"

fun rebuild_scan_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), lines: &Buf >> Buf, gap: !Buf, lo: int, hi: int, n: int, i: int, ln: int): int =
  if recfuel > 0 then (
    if ige(i, n) then ln
    else if ieq(gap_byte_at(gap, lo, hi, i), 10) then let
      val () = store_line_start(lines, ln, iadd(i, 1))
    in
      rebuild_scan_with_fuel(recfuel - 1, lines, gap, lo, hi, n, iadd(i, 1), iadd(ln, 1))
    end
    else rebuild_scan_with_fuel(recfuel - 1, lines, gap, lo, hi, n, iadd(i, 1), ln)
  ) else rebuild_scan_fuel_exhausted(lines, gap, lo, hi, n, i, ln)

fun rebuild_scan(lines: &Buf >> Buf, gap: !Buf, lo: int, hi: int, n: int, i: int, ln: int): int = rebuild_scan_with_fuel(airlock_nat(MAX_REC_FUEL), lines, gap, lo, hi, n, i, ln)

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

extern fun line_bsearch_fuel_exhausted(d: !Doc, off: int, lo: int, hi: int, best: int): int = "mac#anth_die_int"

fun line_bsearch_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, off: int, lo: int, hi: int, best: int): int =
  if recfuel > 0 then (
    if igt(lo, hi) then best
    else let
      val mid = iadd(lo, idiv(isub(hi, lo), 2))
      val st = doc_line_start(d, mid)
    in
      if ile(st, off) then line_bsearch_with_fuel(recfuel - 1, d, off, iadd(mid, 1), hi, mid)
      else line_bsearch_with_fuel(recfuel - 1, d, off, lo, isub(mid, 1), best)
    end
  ) else line_bsearch_fuel_exhausted(d, off, lo, hi, best)

fun line_bsearch(d: !Doc, off: int, lo: int, hi: int, best: int): int = line_bsearch_with_fuel(airlock_nat(MAX_REC_FUEL), d, off, lo, hi, best)

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

extern fun find_keep_fuel_exhausted(d: !Doc, at: int, cur: int, n: int): int = "mac#anth_die_int"

fun find_keep_lines_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, at: int, cur: int, n: int
): int =
  if recfuel > 0 then (
    if ige(cur, n) then n
    else let
      val st = doc_line_start(d, cur)
    in
      if ile(st, at) then find_keep_lines_with_fuel(recfuel - 1, d, at, iadd(cur, 1), n)
      else cur
    end
  ) else find_keep_fuel_exhausted(d, at, cur, n)

extern fun find_tail_fuel_exhausted(d: !Doc, max_del: int, cur: int, n: int): int = "mac#anth_die_int"

fun find_tail_line_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, max_del: int, cur: int, n: int
): int =
  if recfuel > 0 then (
    if ige(cur, n) then n
    else let
      val st = doc_line_start(d, cur)
    in
      if ile(st, max_del) then find_tail_line_with_fuel(recfuel - 1, d, max_del, iadd(cur, 1), n)
      else cur
    end
  ) else find_tail_fuel_exhausted(d, max_del, cur, n)

