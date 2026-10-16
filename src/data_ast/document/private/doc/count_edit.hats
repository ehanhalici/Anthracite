extern fun count_edit_fuel_exhausted(d: !Doc, j: int, en: int, cnt: int): int = "mac#anth_die_int"

fun count_edit_nls_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, j: int, en: int, cnt: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(j, en) then cnt
    else let
      val b = doc_byte(d, j)
      val nxt_cnt = (if ieq(b, 10) then iadd(cnt, 1) else cnt)
    in
      count_edit_nls_with_fuel(recfuel - 1, d, iadd(j, 1), en, nxt_cnt)
    end
  ) else count_edit_fuel_exhausted(d, j, en, cnt)

extern fun shift_lines_fuel_exhausted(d: !Doc, cur: int, n: int, delta: int): void = "mac#anth_die_void"

fun shift_lines_inplace_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, cur: int, n: int, delta: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ige(cur, n) then ()
    else let
      val st = doc_line_start(d, cur)
      val () = d_line_set(d, cur, iadd(st, delta))
    in
      shift_lines_inplace_with_fuel(recfuel - 1, d, iadd(cur, 1), n, delta)
    end
  ) else shift_lines_fuel_exhausted(d, cur, n, delta)

extern fun copy_keep_fuel_exhausted(d: !Doc, dst: !Buf, cur: int, n: int): void = "mac#anth_die_void"

fun copy_keep_lines_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, dst: !Buf, cur: int, n: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ige(cur, n) then ()
    else let
      val st = doc_line_start(d, cur)
      val () = buf_set32(dst, cur, st)
    in
      copy_keep_lines_with_fuel(recfuel - 1, d, dst, iadd(cur, 1), n)
    end
  ) else copy_keep_fuel_exhausted(d, dst, cur, n)

extern fun scan_add_edit_fuel_exhausted(d: !Doc, j: int, en: int, dst: !Buf, cur_idx: int): int = "mac#anth_die_int"

fun scan_add_edit_nls_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, j: int, en: int, dst: !Buf, cur_idx: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(j, en) then cur_idx
    else let
      val b = doc_byte(d, j)
    in
      if ieq(b, 10) then let
        val () = buf_set32(dst, cur_idx, iadd(j, 1))
      in
        scan_add_edit_nls_with_fuel(recfuel - 1, d, iadd(j, 1), en, dst, iadd(cur_idx, 1))
      end else scan_add_edit_nls_with_fuel(recfuel - 1, d, iadd(j, 1), en, dst, cur_idx)
    end
  ) else scan_add_edit_fuel_exhausted(d, j, en, dst, cur_idx)

extern fun copy_tail_fuel_exhausted(d: !Doc, cur: int, n: int, dst: !Buf, cur_idx: int, delta: int): void = "mac#anth_die_void"

fun copy_tail_shifted_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, cur: int, n: int, dst: !Buf, cur_idx: int, delta: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ige(cur, n) then ()
    else let
      val st = doc_line_start(d, cur)
      val () = buf_set32(dst, cur_idx, iadd(st, delta))
    in
      copy_tail_shifted_with_fuel(recfuel - 1, d, iadd(cur, 1), n, dst, iadd(cur_idx, 1), delta)
    end
  ) else copy_tail_fuel_exhausted(d, cur, n, dst, cur_idx, delta)

fun lines_apply_splice(
  d: !Doc, keep: int, tail: int, old_n: int, added: int, delta: int, at: int, newlen: int
): void = let
  val deleted = isub(tail, keep)
  val new_n = isub(iadd(old_n, added), deleted)
  var new_b = buf_make(imax(4096, imul(iadd(new_n, 4), 4)))
  val () = copy_keep_lines_with_fuel(airlock_nat(MAX_REC_FUEL), d, new_b, 0, keep)
  val after_nl = scan_add_edit_nls_with_fuel(airlock_nat(MAX_REC_FUEL), d, at, iadd(at, newlen), new_b, keep)
  val () = copy_tail_shifted_with_fuel(airlock_nat(MAX_REC_FUEL), d, tail, old_n, new_b, after_nl, delta)
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
    val keep = find_keep_lines_with_fuel(airlock_nat(MAX_REC_FUEL), d, at, l0, old_n)
    val max_del = iadd(at, oldlen)
    val tail = find_tail_line_with_fuel(airlock_nat(MAX_REC_FUEL), d, max_del, keep, old_n)
    val added = count_edit_nls_with_fuel(airlock_nat(MAX_REC_FUEL), d, at, iadd(at, newlen), 0)
    val deleted = isub(tail, keep)
  in
    if ieq(deleted, 0) andalso ieq(added, 0) then (
      if ine(delta, 0) then shift_lines_inplace_with_fuel(airlock_nat(MAX_REC_FUEL), d, tail, old_n, delta)
      else ()
    ) else lines_apply_splice(d, keep, tail, old_n, added, delta, at, newlen)
  end
end

fun node_field_get(d: !Doc, i: int, f: int): int =
  case+ d of
  | @DOC(s) => let
      val v = buf_get32(s.nodes, iadd(imul(i, AST_NODE_WORDS), f))
    in
      fold@(d); v
    end

fun node_field_set(d: !Doc, i: int, f: int, v: int): void =
  case+ d of
  | @DOC(s) => let
      val () = buf_set32(s.nodes, iadd(imul(i, AST_NODE_WORDS), f), v)
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
