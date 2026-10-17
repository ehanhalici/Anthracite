fun is_space_tab(b: int): bool = ieq(b, CHAR_SPACE) orelse ieq(b, CHAR_TAB)

fun is_ascii_punct(b: int): bool =
  (ige(b, CHAR_EXCL) andalso ile(b, CHAR_SLASH)) orelse
  (ige(b, CHAR_COLON) andalso ile(b, CHAR_AT)) orelse
  (ige(b, CHAR_LBRACKET) andalso ile(b, CHAR_BACKTICK)) orelse
  (ige(b, CHAR_LBRACE) andalso ile(b, CHAR_TILDE))

fun emit_text(
  d: !Doc, parent: int, last_sib: &int >> _, st: int, en: int
): void =
  if igt(en, st) then let
    val node = doc_node_add(d, KText, st, en, parent, last_sib, 0, 0)
  in
    if ige(node, 0) then last_sib := node else ()
  end else ()

extern fun find_char_fuel_exhausted(d: !Doc, p: int, en: int, ch: int): int = "mac#anth_die_int"

fun find_char_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, ch: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(p, en) then ~1
    else if ieq(doc_byte(d, p), ch) then p
    else find_char_with_fuel(recfuel - 1, d, iadd(p, 1), en, ch)
  ) else find_char_fuel_exhausted(d, p, en, ch)

fun find_char(d: !Doc, p: int, en: int, ch: int): int =
  find_char_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, en, ch)

extern fun find_pair_fuel_exhausted(d: !Doc, p: int, en: int, b1: int, b2: int): int = "mac#anth_die_int"

fun find_pair_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, b1: int, b2: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(iadd(p, 1), en) then ~1
    else if ieq(doc_byte(d, p), b1) andalso ieq(doc_byte(d, iadd(p, 1)), b2) then p
    else find_pair_with_fuel(recfuel - 1, d, iadd(p, 1), en, b1, b2)
  ) else find_pair_fuel_exhausted(d, p, en, b1, b2)

fun find_pair(d: !Doc, p: int, en: int, b1: int, b2: int): int =
  find_pair_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, en, b1, b2)

extern fun count_char_run_fuel_exhausted(d: !Doc, p: int, en: int, ch: int, c: int): int = "mac#anth_die_int"

fun count_char_run_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, ch: int, c: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(p, en) then c
    else if ieq(doc_byte(d, p), ch) then count_char_run_with_fuel(recfuel - 1, d, iadd(p, 1), en, ch, iadd(c, 1))
    else c
  ) else count_char_run_fuel_exhausted(d, p, en, ch, c)

fun count_char_run(d: !Doc, p: int, en: int, ch: int): int =
  count_char_run_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, en, ch, 0)

extern fun find_bt_run_fuel_exhausted(d: !Doc, p: int, en: int, n: int): int = "mac#anth_die_int"

fun find_bt_run_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, n: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(p, en) then ~1
    else if ieq(doc_byte(d, p), CHAR_BACKTICK) then let
      val c = count_char_run(d, p, en, 96)
    in
      if ieq(c, n) then p else find_bt_run_with_fuel(recfuel - 1, d, iadd(p, c), en, n)
    end else find_bt_run_with_fuel(recfuel - 1, d, iadd(p, 1), en, n)
  ) else find_bt_run_fuel_exhausted(d, p, en, n)

fun codespan_unclosed(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int, n: int
): int = let
  val () = emit_text(d, parent, last_sib, txt_st, p)
  val cs = doc_node_add(d, KCodeSpan, p, en, parent, last_sib, 0, FL_ERROR)
in
  if ige(cs, 0) then let
    val m1 = doc_node_add(d, KMark, p, iadd(p, n), cs, ~1, 0, FL_ERROR)
    val raw = (if igt(en, iadd(p, n)) then doc_node_add(d, KRaw, iadd(p, n), en, cs, m1, 0, FL_ERROR) else m1)
    val () = doc_node_close(d, cs, en, iadd(p, n), en)
    val () = last_sib := cs
  in
    en
  end else ~1
end

fun try_codespan(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int
): int = let
  val n = count_char_run(d, p, en, 96)
  val c_pos = find_bt_run_with_fuel(airlock_nat(MAX_REC_FUEL), d, iadd(p, n), en, n)
in
  if igt(c_pos, 0) then let
    val () = emit_text(d, parent, last_sib, txt_st, p)
    val span_end = iadd(c_pos, n)
    val cs = doc_node_add(d, KCodeSpan, p, span_end, parent, last_sib, 0, FL_CLOSED)
  in
    if ige(cs, 0) then let
      val m1 = doc_node_add(d, KMark, p, iadd(p, n), cs, ~1, 0, 0)
      val raw = (if igt(c_pos, iadd(p, n)) then doc_node_add(d, KRaw, iadd(p, n), c_pos, cs, m1, 0, 0) else m1)
      val _ = doc_node_add(d, KMark, c_pos, span_end, cs, raw, 0, 0)
      val () = doc_node_close(d, cs, span_end, iadd(p, n), c_pos)
      val () = last_sib := cs
    in
      span_end
    end else ~1
  end else if igt(en, iadd(p, n)) then codespan_unclosed(d, parent, last_sib, p, en, txt_st, n)
  else ~1
end

fun wiki_add_anchor(
  d: !Doc, wiki_node: int, m_prev: int, hash: int, en: int, hide_flag: int
): int = let
  val is_block = ilt(iadd(hash, 1), en) andalso ieq(doc_byte(d, iadd(hash, 1)), CHAR_CARET)
  val ak = (if is_block then KWikiBlock else KWikiHeading)
in
  doc_node_add(d, ak, hash, en, wiki_node, m_prev, 0, hide_flag)
end

fun wiki_add_target(
  d: !Doc, wiki_node: int, m_prev: int, st: int, en: int, hide_flag: int
): int = let
  val hash = find_char(d, st, en, 35)
in
  if ige(hash, st) then let
    val t = (if igt(hash, st) then doc_node_add(d, KWikiTarget, st, hash, wiki_node, m_prev, 0, hide_flag) else m_prev)
  in
    wiki_add_anchor(d, wiki_node, t, hash, en, hide_flag)
  end else doc_node_add(d, KWikiTarget, st, en, wiki_node, m_prev, 0, hide_flag)
end

fun wiki_add_parts(
  d: !Doc, wiki_node: int, m1: int, st: int, en: int, pipe: int
): int =
  if ige(pipe, st) then let
    val t = wiki_add_target(d, wiki_node, m1, st, pipe, FL_READ_HIDDEN)
    val m_mid = doc_node_add(d, KMark, pipe, iadd(pipe, 1), wiki_node, t, 0, 0)
    val al = doc_node_add(d, KWikiAlias, iadd(pipe, 1), en, wiki_node, m_mid, 0, 0)
  in
    al
  end else wiki_add_target(d, wiki_node, m1, st, en, 0)

fun doc_to_lower(c: int): int =
  if c >= 65 andalso c <= 90 then iadd(c, 32) else c

fun doc_ends_ext4(d: !Doc, en: int, c1: int, c2: int, c3: int, c4: int): bool =
  ieq(doc_to_lower(doc_byte(d, isub(en, 4))), c1) andalso
  ieq(doc_to_lower(doc_byte(d, isub(en, 3))), c2) andalso
  ieq(doc_to_lower(doc_byte(d, isub(en, 2))), c3) andalso
  ieq(doc_to_lower(doc_byte(d, isub(en, 1))), c4)

fun doc_is_image_target(d: !Doc, st: int, en: int): bool =
  if isub(en, st) >= 4 andalso (
    doc_ends_ext4(d, en, 46, 112, 110, 103) orelse
    doc_ends_ext4(d, en, 46, 106, 112, 103) orelse
    doc_ends_ext4(d, en, 46, 98, 109, 112)  orelse
    doc_ends_ext4(d, en, 46, 119, 101, 98)
  ) then true
  else if isub(en, st) >= 5 andalso ieq(doc_to_lower(doc_byte(d, isub(en, 5))), 46)
       andalso ieq(doc_to_lower(doc_byte(d, isub(en, 4))), 106)
       andalso ieq(doc_to_lower(doc_byte(d, isub(en, 3))), 112)
       andalso ieq(doc_to_lower(doc_byte(d, isub(en, 2))), 101)
       andalso ieq(doc_to_lower(doc_byte(d, isub(en, 1))), 103) then true
  else false

fun wiki_attach_children(
  d: !Doc, w_node: int, p: int, inner_st: int, c_pos: int, w_end: int, pipe: int
): void = let
  val m1 = doc_node_add(d, KMark, p, inner_st, w_node, ~1, 0, 0)
  val last_ch = wiki_add_parts(d, w_node, m1, inner_st, c_pos, pipe)
  val _ = doc_node_add(d, KMark, c_pos, w_end, w_node, last_ch, 0, 0)
  val () = doc_node_close(d, w_node, w_end, inner_st, c_pos)
in
end

fun wiki_node_kind(is_embed: bool, d: !Doc, st: int, en: int): NodeKind =
  if is_embed andalso doc_is_image_target(d, st, en) then KImage
  else (if is_embed then KEmbed else KWiki)

fun wiki_unclosed(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int, is_embed: bool
): int = let
  val () = emit_text(d, parent, last_sib, txt_st, p)
  val mlen = (if is_embed then 3 else 2)
  val k = (if is_embed then KEmbed else KWiki)
  val w_node = doc_node_add(d, k, p, en, parent, last_sib, 0, FL_ERROR)
in
  if ige(w_node, 0) then let
    val m1 = doc_node_add(d, KMark, p, iadd(p, mlen), w_node, ~1, 0, FL_ERROR)
    val raw = (if igt(en, iadd(p, mlen)) then doc_node_add(d, KRaw, iadd(p, mlen), en, w_node, m1, 0, FL_ERROR) else m1)
    val () = doc_node_close(d, w_node, en, iadd(p, mlen), en)
    val () = last_sib := w_node
  in
    en
  end else ~1
end
