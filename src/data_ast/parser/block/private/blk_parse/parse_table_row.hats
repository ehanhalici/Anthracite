fun parse_table_row(
  d: !Doc, parent: int, prev: int, ls: int, le: int, is_header: bool
): int = let
  val flg = (if is_header then FL_HEADER_ROW else 0)
  val r_node = doc_node_add(d, KTableRow, ls, le, parent, prev, 0, flg)
in
  if ige(r_node, 0) then let
    val () = parse_table_cells_with_fuel(airlock_nat(MAX_REC_FUEL), d, r_node, ls, le, ~1, 0)
    val () = doc_node_close(d, r_node, le, ls, le)
  in
    r_node
  end else ~1
end

fun is_delim_char(b: int): bool =
  ieq(b, CHAR_MINUS) orelse ieq(b, CHAR_COLON) orelse ieq(b, CHAR_PIPE) orelse ieq(b, CHAR_SPACE) orelse ieq(b, CHAR_TAB)

extern fun check_is_delim_fuel_exhausted(d: !Doc, p: int, le: int): bool = "mac#anth_die_int"

fun check_is_delim_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, le: int
): bool =
  if recfuel > 0 then (
    if ige(p, le) then true
    else if is_delim_char(doc_byte(d, p)) then check_is_delim_with_fuel(recfuel - 1, d, iadd(p, 1), le)
    else false
  ) else check_is_delim_fuel_exhausted(d, p, le)

fun is_table_delim_line(d: !Doc, p: int, le: int): bool =
  check_is_delim_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, le)

fun parse_table_block(
  d: !Doc, stk: &Buf >> _, ls1: int, le1: int, ls2: int, le2: int, ls3: int, le3: int,
  next_pos: &int >> _
): void = let
  val tbl_end = (if igt(le3, 0) then le3 else le2)
  val t_node = add_child_node(d, stk, KTable, ls1, tbl_end, 0, 0)
in
  if ige(t_node, 0) then let
    val r1 = parse_table_row(d, t_node, ~1, ls1, le1, true)
    val d1 = parse_table_delim(d, t_node, r1, ls2, le2)
    val _ = (if igt(le3, 0) then parse_table_row(d, t_node, d1, ls3, le3, false) else ~1)
    val () = doc_node_close(d, t_node, tbl_end, ls1, tbl_end)
    val () = next_pos := (if igt(le3, 0) then line_next(d, ls3) else line_next(d, ls2))
  in
  end else ()
end

fun try_heading(d: !Doc, stk: &Buf >> _, cur: int, le: int, nxt: int, p: int, b: int): int =
  if ieq(b, CHAR_HASH) then let
    val hashes = count_char(d, p, le, 35)
  in
    if ige(hashes, 1) andalso ile(hashes, 6) andalso (
      ige(iadd(p, hashes), le) orelse is_space_or_tab(doc_byte(d, iadd(p, hashes)))
    ) then (parse_atx_heading(d, stk, cur, le, p, hashes); nxt)
    else ~1
  end else ~1

fun try_fence(d: !Doc, stk: &Buf >> _, cur: int, le: int, nxt: int, p: int, b: int): int =
  if (ieq(b, CHAR_BACKTICK) orelse ieq(b, CHAR_TILDE)) andalso ige(count_char(d, p, le, b), 3) then let
    var next_p: int = nxt
    val () = parse_fenced_code(d, stk, cur, le, p, b, count_char(d, p, le, b), nxt, next_p)
  in
    next_p
  end else ~1

fun try_quote_callout(d: !Doc, stk: &Buf >> _, cur: int, le: int, nxt: int, len: int, p: int, b: int): int =
  if ieq(b, CHAR_GT) then let
    val c_st = (if ilt(iadd(p, 1), le) andalso ieq(doc_byte(d, iadd(p, 1)), CHAR_SPACE) then iadd(p, 2) else iadd(p, 1))
  in
    if is_callout_head(d, c_st, le) then let
      val nxt_le = (if ilt(nxt, len) then line_end(d, nxt) else ~1)
      val nxt_p = (if ilt(nxt, len) andalso ieq(doc_byte(d, nxt), CHAR_GT) then (
        if ilt(iadd(nxt, 1), nxt_le) andalso ieq(doc_byte(d, iadd(nxt, 1)), CHAR_SPACE) then iadd(nxt, 2) else iadd(nxt, 1)
      ) else ~1)
      var next_pos: int = nxt
      val () = parse_callout_block(d, stk, cur, le, c_st, (if ige(nxt_p, 0) then nxt_p else 0), (if ige(nxt_p, 0) then nxt_le else ~1), next_pos)
    in
      next_pos
    end else (parse_quote(d, stk, cur, le, p); nxt)
  end else ~1

fun try_list_or_table(d: !Doc, stk: &Buf >> _, cur: int, le: int, nxt: int, len: int, p: int, b: int): int =
  if ieq(b, CHAR_MINUS) andalso ilt(iadd(p, 1), le) andalso ieq(doc_byte(d, iadd(p, 1)), CHAR_SPACE) then (
    parse_list_item(d, stk, cur, le, p); nxt
  ) else if ieq(b, CHAR_PIPE) then let
    val l2_st = nxt
    val l2_le = (if ilt(l2_st, len) then line_end(d, l2_st) else ~1)
  in
    if igt(l2_le, 0) andalso is_table_delim_line(d, l2_st, l2_le) then let
      val l3_st = line_next(d, l2_st)
      val l3_le = (if ilt(l3_st, len) then line_end(d, l3_st) else ~1)
      var next_p: int = nxt
      val () = parse_table_block(d, stk, cur, le, l2_st, l2_le, l3_st, l3_le, next_p)
    in
      next_p
    end else ~1
  end else ~1

fun try_hr(d: !Doc, stk: &Buf >> _, cur: int, le: int, nxt: int, p: int, b: int): int =
  if (ieq(b, CHAR_MINUS) orelse ieq(b, CHAR_STAR) orelse ieq(b, CHAR_UNDERSCORE)) andalso ige(count_char(d, p, le, b), 3)
     andalso is_blank(d, iadd(p, count_char(d, p, le, b)), le) then (
    parse_hr(d, stk, cur, le); nxt
  ) else ~1

fun try_frontmatter(d: !Doc, stk: &Buf >> _, cur: int, le: int, nxt: int, len: int): int =
  if ieq(cur, 0) andalso ige(le, 3) andalso ieq(doc_byte(d, 0), CHAR_MINUS)
     andalso ieq(doc_byte(d, 1), CHAR_MINUS) andalso ieq(doc_byte(d, 2), CHAR_MINUS) then let
    var c_st: int = ~1
    var c_en: int = ~1
    val found = find_close_fence_with_fuel(airlock_nat(MAX_REC_FUEL), d, nxt, len, 45, 3, c_st, c_en)
  in
    if found then let
      val fm = add_child_node(d, stk, KFm, 0, c_en, 0, 0)
      val () = if ige(fm, 0) then let
        val m1 = doc_node_add(d, KMark, 0, 3, fm, ~1, 0, 0)
        val raw = (if igt(c_st, nxt) then doc_node_add(d, KRaw, nxt, isub(c_st, 1), fm, m1, 0, 0) else m1)
        val _ = doc_node_add(d, KMark, c_st, c_en, fm, raw, 0, 0)
        val () = doc_node_close(d, fm, c_en, nxt, isub(c_st, 1))
      in
      end else ()
    in
      line_next(d, c_st)
    end else ~1
  end else ~1

fun find_fndef_colon_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, le: int
): int =
  if recfuel > 0 then (
    if ige(iadd(p, 1), le) then ~1
    else if ieq(doc_byte(d, p), CHAR_RBRACKET) andalso ieq(doc_byte(d, iadd(p, 1)), CHAR_COLON) then p
    else find_fndef_colon_with_fuel(recfuel - 1, d, iadd(p, 1), le)
  ) else ~1

fun parse_footnote_body(d: !Doc,parent: int,start: int,finish: int,previous: int): void = let
  val paragraph=doc_node_add(d,KPara,start,finish,parent,previous,0,0)
in if ige(paragraph,0) then let
  var sibling: int = ~1
  val ()=inl_parse_depth(d,paragraph,start,finish,0,sibling)
in doc_node_close(d,paragraph,finish,start,finish) end else () end

fun try_fndef(d: !Doc, stk: &Buf >> _, cur: int, le: int, nxt: int, p: int, b: int): int =
  if ieq(b, CHAR_LBRACKET) andalso ilt(iadd(p, 1), le) andalso ieq(doc_byte(d, iadd(p, 1)), CHAR_CARET) then let
    val colon = find_fndef_colon_with_fuel(airlock_nat(MAX_REC_FUEL), d, iadd(p, 2), le)
  in
    if igt(colon, 0) then let
      val fnd = add_child_node(d, stk, KFndef, cur, le, 0, 0)
      val () = if ige(fnd, 0) then let
        val fn_mark_en = iadd(colon, 2)
        val fn_node = doc_node_add(d, KFn, p, fn_mark_en, fnd, ~1, 0, 0)
        val c_st = (if ilt(fn_mark_en, le) andalso is_space_or_tab(doc_byte(d, fn_mark_en)) then iadd(fn_mark_en, 1) else fn_mark_en)
        val ()=parse_footnote_body(d,fnd,c_st,le,fn_node)
        val () = doc_node_close(d, fnd, le, c_st, le)
      in
      end else ()
    in
      nxt
    end else ~1
  end else ~1

fun dispatch_plain_block(d: !Doc,stk: &Buf >> _,cur: int,le: int,nxt: int,len: int,p: int,b: int): int = let
  val list_or_table=try_list_or_table(d,stk,cur,le,nxt,len,p,b)
in if ige(list_or_table,0) then list_or_table else let
  val footnote=try_fndef(d,stk,cur,le,nxt,p,b)
in if ige(footnote,0) then footnote else let
  val rule=try_hr(d,stk,cur,le,nxt,p,b)
in if ige(rule,0) then rule else (parse_para_line(d,stk,cur,le); nxt) end end end

fun dispatch_fenced_block(d: !Doc,stk: &Buf >> _,cur: int,le: int,nxt: int,len: int,p: int,b: int): int = let
  val fence=try_fence(d,stk,cur,le,nxt,p,b)
in if ige(fence,0) then fence else let
  val quote=try_quote_callout(d,stk,cur,le,nxt,len,p,b)
in if ige(quote,0) then quote else dispatch_plain_block(d,stk,cur,le,nxt,len,p,b) end end

fun dispatch_line(d: !Doc,stk: &Buf >> _,cur: int,le: int,nxt: int,len: int,p: int): int = let
  val frontmatter=if ieq(cur,0) then try_frontmatter(d,stk,cur,le,nxt,len) else ~1
in if ige(frontmatter,0) then frontmatter else let
  val byte=doc_byte(d,p)
  val heading=try_heading(d,stk,cur,le,nxt,p,byte)
in if ige(heading,0) then heading else dispatch_fenced_block(d,stk,cur,le,nxt,len,p,byte) end end


extern fun bsearch_resync_fuel_exhausted(resync: !Buf, nres: int, target: int, lo: int, hi: int): int = "mac#anth_die_int"

fun bsearch_resync_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), resync: !Buf, nres: int, target: int, lo: int, hi: int
): int =
  if recfuel > 0 then (
    if igt(lo, hi) then ~1
    else let
      val mid = iadd(lo, idiv(isub(hi, lo), 2))
      val st = buf_get32(resync, imul(mid, 2))
    in
      if ieq(st, target) then buf_get32(resync, iadd(imul(mid, 2), 1))
      else if ilt(st, target) then bsearch_resync_with_fuel(recfuel - 1, resync, nres, target, iadd(mid, 1), hi)
      else bsearch_resync_with_fuel(recfuel - 1, resync, nres, target, lo, isub(mid, 1))
    end
  ) else bsearch_resync_fuel_exhausted(resync, nres, target, lo, hi)
