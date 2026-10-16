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

extern fun ast_style_fuel_exhausted(d: !Doc, cur: int, acc: int): int = "mac#anth_die_int"

fun ast_style_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, cur: int, acc: int): int =
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
      ast_style_with_fuel(recfuel - 1, d, p, n_acc)
    end
  ) else ast_style_fuel_exhausted(d, cur, acc)

implement ast_style(d, i) = let
  val self_fl = doc_node_flags(d, i)
  val init_err = (if iand(self_fl, FL_ERROR) != 0 then STYLE_ERROR else 0)
in
  ast_style_with_fuel(airlock_nat(MAX_REC_FUEL), d, doc_node_parent(d, i), init_err)
end

implement doc_node_kind(d, i) = kind_of(node_field_get(d, i, NF_KIND))
implement doc_node_start(d, i) = node_field_get(d, i, NF_START)
implement doc_node_end(d, i) = node_field_get(d, i, NF_END)
implement doc_node_depth(d, i) = node_field_get(d, i, NF_DEPTH)
implement doc_node_collapsed(d, i) = toggle_of(ieq(node_field_get(d, i, NF_COLLAPSED), 1))
implement doc_node_height(d, i) =
  case+ d of
  | @DOC(s) => let
      val h = layout_node_height(s.lay, i, s.nlines)
    in
      fold@(d); h
    end
implement doc_node_parent(d, i) = node_field_get(d, i, NF_PARENT)
implement doc_node_hidden(d, i) = toggle_of(ieq(node_field_get(d, i, NF_HIDDEN), 1))
implement doc_node_aux(d, i) = node_field_get(d, i, NF_AUX)
implement doc_node_y(d, i) =
  case+ d of
  | @DOC(s) => let
      val y = layout_node_y(s.lay, i, s.nlines)
    in
      fold@(d); y
    end

implement doc_node_first_child(d, i) = node_field_get(d, i, NF_FIRST_CHILD)
implement doc_node_next_sib(d, i) = node_field_get(d, i, NF_NEXT_SIB)
implement doc_node_cstart(d, i) = node_field_get(d, i, NF_CSTART)
implement doc_node_cend(d, i) = node_field_get(d, i, NF_CEND)
implement doc_node_subend(d, i) = node_field_get(d, i, NF_SUBEND)
implement doc_node_flags(d, i) = node_field_get(d, i, NF_FLAGS)

fun doc_node_set_collapsed(d: !Doc, i: int, v: Toggle): void = node_field_set(d, i, NF_COLLAPSED, toggle_int(v))
fun doc_node_set_height(d: !Doc, i: int, h: int): void = let
  val line_count = d_nlines(d)
  val () = ensure_layout_capacity(d, layout_node_need(i, line_count))
  val laybuf0 = take_layout(d)
  var laybuf = laybuf0
  val () = layout_node_put_height(laybuf, i, h, line_count)
in
  put_layout(d, laybuf)
end
fun doc_node_set_parent(d: !Doc, i: int, p: int): void = node_field_set(d, i, NF_PARENT, p)
fun doc_node_set_next_sib(d: !Doc, i: int, s: int): void = node_field_set(d, i, NF_NEXT_SIB, s)
fun doc_node_set_first_child(d: !Doc, i: int, c: int): void = node_field_set(d, i, NF_FIRST_CHILD, c)
fun doc_node_set_hidden(d: !Doc, i: int, v: Toggle): void = node_field_set(d, i, NF_HIDDEN, toggle_int(v))
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
  else node_field_get(d, i, f)

implement doc_set(d, i, f, v) =
  if ieq(f, NF_HEIGHT) then doc_node_set_height(d, i, v)
  else if ieq(f, NF_Y) then doc_node_set_y(d, i, v)
  else node_field_set(d, i, f, v)

fun node_room(d: !Doc): void =
  case+ d of
  | @DOC(s) => let
      val need = imul(iadd(s.nnodes, 2), AST_NODE_WORDS * 4)
      val () = if buf_cap(s.nodes) < need then buf_resize(s.nodes, imul(need, 2)) else ()
    in
      fold@(d)
    end

extern fun zero_node_fuel_exhausted(d: !Doc, i: int, f: int): void = "mac#anth_die_void"

fun zero_node_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, f: int): void =
  if recfuel > 0 then (
    if f < AST_NODE_WORDS then let
      val () = node_field_set(d, i, f, 0)
    in
      zero_node_with_fuel(recfuel - 1, d, i, iadd(f, 1))
    end else ()
  ) else zero_node_fuel_exhausted(d, i, f)

