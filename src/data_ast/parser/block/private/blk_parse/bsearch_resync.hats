fun bsearch_resync(resync: !Buf, nres: int, target: int): int =
  if ile(nres, 0) then ~1
  else bsearch_resync_with_fuel(airlock_nat(MAX_REC_FUEL), resync, nres, target, 0, isub(nres, 1))

extern fun parse_lines_fuel_exhausted(d: !Doc, cur: int, len: int, stk: &Buf >> _): int = "mac#anth_die_int"

fun check_resync_hit(resync: !Buf, nres: int, cur: int, minpos: int, delta: int): int =
  if igt(nres, 0) andalso ige(cur, minpos) then bsearch_resync(resync, nres, isub(cur, delta))
  else ~1

fun line_content_start(d: !Doc,start: int,finish: int): int = let
  var columns: int=0
  var position: int=start
  val ()=indent_cols(d,start,finish,columns,position)
in position end

fun parse_lines_resync_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, cur: int, len: int, stk: &Buf >> _,
  resync: !Buf, nres: int, delta: int, minpos: int, matched_old: &int >> _
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(cur, len) then cur
    else let
      val le = line_end(d, cur)
      val nxt = line_next(d, cur)
      val p = line_content_start(d,cur,le)
    in
      if ige(p, le) then parse_lines_resync_with_fuel(recfuel - 1, d, nxt, len, stk, resync, nres, delta, minpos, matched_old)
      else let
        val hit = check_resync_hit(resync, nres, cur, minpos, delta)
      in
        if ige(hit, 0) then (matched_old := hit; cur)
        else let
          val next_pos = dispatch_line(d, stk, cur, le, nxt, len, p)
        in
          parse_lines_resync_with_fuel(recfuel - 1, d, next_pos, len, stk, resync, nres, delta, minpos, matched_old)
        end
      end
    end
  ) else parse_lines_fuel_exhausted(d, cur, len, stk)

implement blk_parse_until(d, from, resync, nres, delta, minpos, stk, matched_old) = let
  val len = doc_len(d)
in
  parse_lines_resync_with_fuel(airlock_nat(MAX_REC_FUEL), d, from, len, stk, resync, nres, delta, minpos, matched_old)
end

implement ast_parse_all(d) = let
  val is_md = doc_is_md(d)
in
  if is_off(is_md) then (doc_clear_nodes(d); doc_set_span(d, 0))
  else let
    val () = doc_clear_nodes(d)
    var stk = buf_make(imul(64, 20))
    var res = buf_make(AST_PARSE_ALL_RES_INITIAL_BYTES)
    var matched_old: int = ~1
    val _ = blk_parse_until(d, 0, res, 0, 0, 0, stk, matched_old)
    val () = buf_free(res)
    val () = buf_free(stk)
    val () = doc_set_span(d, doc_len(d))
  in
  end
end

fun buf_push32(b: &Buf >> _, v: int): void = let
  val n = buf_len(b)
  val idx = idiv(n, 4)
  val need = iadd(n, 4)
  val () = if buf_cap(b) < need then buf_resize(b, imax(16, imul(need, 2))) else ()
  val () = buf_set_len(b, need)
  val () = buf_set32(b, idx, v)
in
end

fun save_node_flds1(d: !Doc, dst: &Buf >> _, cur: int): void = (
  buf_push32(dst, doc_get(d, cur, 0));
  buf_push32(dst, doc_get(d, cur, 1));
  buf_push32(dst, doc_get(d, cur, 2));
  buf_push32(dst, doc_get(d, cur, 3));
  buf_push32(dst, doc_get(d, cur, 4));
  buf_push32(dst, doc_get(d, cur, 5));
  buf_push32(dst, doc_get(d, cur, 6));
  buf_push32(dst, doc_get(d, cur, 7))
)

fun save_node_flds2(d: !Doc, dst: &Buf >> _, cur: int): void = (
  buf_push32(dst, doc_get(d, cur, 8));
  buf_push32(dst, doc_get(d, cur, 9));
  buf_push32(dst, doc_get(d, cur, 10));
  buf_push32(dst, doc_get(d, cur, 11));
  buf_push32(dst, doc_get(d, cur, 12));
  buf_push32(dst, doc_get(d, cur, 13));
  buf_push32(dst, doc_get(d, cur, 14));
  buf_push32(dst, doc_get(d, cur, 15))
)

fun save_old_nodes_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, dst: &Buf >> _, cur: int, total: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ige(cur, total) then ()
    else let
      val () = save_node_flds1(d, dst, cur)
      val () = save_node_flds2(d, dst, cur)
    in
      save_old_nodes_with_fuel(recfuel - 1, d, dst, iadd(cur, 1), total)
    end
  ) else ()

fun set_node_extra1(
  d: !Doc, old_b: !Buf, base: int, new_i: int, idxdelta: int
): void = let
  val dep = buf_get32(old_b, iadd(base, 3))
  val col = buf_get32(old_b, iadd(base, 4))
  val h = buf_get32(old_b, iadd(base, 5))
  val sib0 = buf_get32(old_b, iadd(base, 7))
  val sib = (if ige(sib0, 0) then iadd(sib0, idxdelta) else ~1)
  val fc0 = buf_get32(old_b, iadd(base, 8))
  val fc = (if ige(fc0, 0) then iadd(fc0, idxdelta) else ~1)
in
  doc_set(d, new_i, NF_DEPTH, dep);
  doc_set(d, new_i, NF_COLLAPSED, col);
  doc_set(d, new_i, NF_HEIGHT, h);
  doc_set(d, new_i, NF_NEXT_SIB, sib);
  doc_set(d, new_i, NF_FIRST_CHILD, fc)
end

fun set_node_extra2(
  d: !Doc, old_b: !Buf, base: int, new_i: int, delta: int, idxdelta: int
): void = let
  val hid = buf_get32(old_b, iadd(base, 9))
  val cs0 = buf_get32(old_b, iadd(base, 11))
  val cs = (if ige(cs0, 0) then iadd(cs0, delta) else cs0)
  val ce0 = buf_get32(old_b, iadd(base, 12))
  val ce = (if ige(ce0, 0) then iadd(ce0, delta) else ce0)
  val y = buf_get32(old_b, iadd(base, 13))
  val sub0 = buf_get32(old_b, iadd(base, 14))
  val sub = (if ige(sub0, 0) then iadd(sub0, idxdelta) else sub0)
in
  doc_set(d, new_i, NF_HIDDEN, hid);
  doc_set(d, new_i, NF_CSTART, cs);
  doc_set(d, new_i, NF_CEND, ce);
  doc_set(d, new_i, NF_Y, y);
  doc_set(d, new_i, NF_SUBEND, sub)
end

fun copy_one_node(
  d: !Doc, old_b: !Buf, idx: int, delta: int, idxdelta: int
): void = let
  val base = imul(idx, 16)
  val k_code = buf_get32(old_b, iadd(base, 0))
  val k = kind_of(k_code)
  val st = iadd(buf_get32(old_b, iadd(base, 1)), delta)
  val en = iadd(buf_get32(old_b, iadd(base, 2)), delta)
  val par0 = buf_get32(old_b, iadd(base, 6))
  val par = (if ige(par0, 0) then iadd(par0, idxdelta) else ~1)
  val aux = buf_get32(old_b, iadd(base, 10))
  val flg = buf_get32(old_b, iadd(base, 15))
  val new_i = doc_node_add(d, k, st, en, par, ~1, aux, flg)
in
  if ige(new_i, 0) then (
    set_node_extra1(d, old_b, base, new_i, idxdelta);
    set_node_extra2(d, old_b, base, new_i, delta, idxdelta)
  ) else ()
end

fun copy_tail_nodes_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, old_b: !Buf, cur: int, total: int, delta: int, idxdelta: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ige(cur, total) then ()
    else let
      val () = copy_one_node(d, old_b, cur, delta, idxdelta)
    in
      copy_tail_nodes_with_fuel(recfuel - 1, d, old_b, iadd(cur, 1), total, delta, idxdelta)
    end
  ) else ()

fun copy_head_nodes_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, old_b: !Buf, cur: int, n: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ige(cur, n) then ()
    else let
      val () = copy_one_node(d, old_b, cur, 0, 0)
    in
      copy_head_nodes_with_fuel(recfuel - 1, d, old_b, iadd(cur, 1), n)
    end
  ) else ()

extern fun find_last_top_fuel_exhausted(d: !Doc, cur: int, to_i: int, last: int): int = "mac#anth_die_int"

fun find_last_top_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, cur: int, to_i: int, last: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(cur, to_i) then last
    else let
      val sub = doc_node_subend(d, cur)
      val next_i = (if igt(sub, cur) then sub else iadd(cur, 1))
    in
      find_last_top_with_fuel(recfuel - 1, d, next_i, to_i, cur)
    end
  ) else find_last_top_fuel_exhausted(d, cur, to_i, last)
