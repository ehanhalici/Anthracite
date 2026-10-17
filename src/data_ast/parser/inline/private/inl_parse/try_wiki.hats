fun try_wiki(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int, is_embed: bool
): int = let
  val mlen = (if is_embed then 3 else 2)
  val inner_st = iadd(p, mlen)
  val c_pos = find_pair(d, inner_st, en, 93, 93)
in
  if igt(c_pos, 0) then let
    val () = emit_text(d, parent, last_sib, txt_st, p)
    val w_end = iadd(c_pos, 2)
    val pipe = find_char(d, inner_st, c_pos, 124)
    val tgt_en = (if ige(pipe, 0) then pipe else c_pos)
    val k = wiki_node_kind(is_embed, d, inner_st, tgt_en)
    val w_node = doc_node_add(d, k, p, w_end, parent, last_sib, 0, FL_CLOSED)
    val () = if ige(w_node, 0) then (wiki_attach_children(d, w_node, p, inner_st, c_pos, w_end, pipe); last_sib := w_node) else ()
  in
    if ige(w_node, 0) then w_end else ~1
  end else if igt(en, inner_st) then wiki_unclosed(d, parent, last_sib, p, en, txt_st, is_embed)
  else ~1
end

fun parse_delim2(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int,
  depth: int, ch: int, kind: NodeKind, flags: int
): int = let
  val inner_st = iadd(p, 2)
  val c_pos = find_pair(d, inner_st, en, ch, ch)
in
  if igt(c_pos, inner_st) then let
    val () = emit_text(d, parent, last_sib, txt_st, p)
    val d_end = iadd(c_pos, 2)
    val node = doc_node_add(d, kind, p, d_end, parent, last_sib, 0, flags)
  in
    if ige(node, 0) then let
      val m1 = doc_node_add(d, KMark, p, inner_st, node, ~1, 0, 0)
      var ch_sib: int = m1
      val () = inl_parse_depth(d, node, inner_st, c_pos, iadd(depth, 1), ch_sib)
      val _ = doc_node_add(d, KMark, c_pos, d_end, node, ch_sib, 0, 0)
      val () = doc_node_close(d, node, d_end, inner_st, c_pos)
      val () = last_sib := node
    in
      d_end
    end else ~1
  end else ~1
end

fun parse_delim1(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int,
  depth: int, ch: int, kind: NodeKind, flags: int
): int = let
  val inner_st = iadd(p, 1)
  val c_pos = find_char(d, inner_st, en, ch)
in
  if igt(c_pos, inner_st) then let
    val () = emit_text(d, parent, last_sib, txt_st, p)
    val d_end = iadd(c_pos, 1)
    val node = doc_node_add(d, kind, p, d_end, parent, last_sib, 0, flags)
  in
    if ige(node, 0) then let
      val m1 = doc_node_add(d, KMark, p, inner_st, node, ~1, 0, 0)
      var ch_sib: int = m1
      val () = inl_parse_depth(d, node, inner_st, c_pos, iadd(depth, 1), ch_sib)
      val _ = doc_node_add(d, KMark, c_pos, d_end, node, ch_sib, 0, 0)
      val () = doc_node_close(d, node, d_end, inner_st, c_pos)
      val () = last_sib := node
    in
      d_end
    end else ~1
  end else ~1
end

fun link_add_children(
  d: !Doc, lnk: int, p: int, l_st: int, r_b: int, r_p: int, depth: int
): void = let
  val m1 = doc_node_add(d, KMark, p, l_st, lnk, ~1, 0, 0)
  var ch_sib: int = m1
  val () = inl_parse_depth(d, lnk, l_st, r_b, iadd(depth, 1), ch_sib)
  val m2 = doc_node_add(d, KMark, r_b, iadd(r_b, 2), lnk, ch_sib, 0, 0)
  val dst = doc_node_add(d, KLinkDest, iadd(r_b, 2), r_p, lnk, m2, 0, 0)
  val _ = doc_node_add(d, KMark, r_p, iadd(r_p, 1), lnk, dst, 0, 0)
  val () = doc_node_close(d, lnk, iadd(r_p, 1), l_st, r_p)
in
end

fun link_unclosed(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int,
  l_st: int, r_b: int, depth: int, is_img: bool
): int = let
  val () = emit_text(d, parent, last_sib, txt_st, p)
  val k = (if is_img then KImage else KLink)
  val lnk = doc_node_add(d, k, p, en, parent, last_sib, 0, FL_ERROR)
in
  if ige(lnk, 0) then let
    val m1 = doc_node_add(d, KMark, p, l_st, lnk, ~1, 0, FL_ERROR)
    var ch_sib: int = m1
    val () = inl_parse_depth(d, lnk, l_st, r_b, iadd(depth, 1), ch_sib)
    val m2 = doc_node_add(d, KMark, r_b, iadd(r_b, 2), lnk, ch_sib, 0, FL_ERROR)
    val dst = (if igt(en, iadd(r_b, 2)) then doc_node_add(d, KLinkDest, iadd(r_b, 2), en, lnk, m2, 0, FL_ERROR) else m2)
    val () = doc_node_close(d, lnk, en, l_st, en)
    val () = last_sib := lnk
  in
    en
  end else ~1
end

fun img_unclosed(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int
): int = let
  val () = emit_text(d, parent, last_sib, txt_st, p)
  val lnk = doc_node_add(d, KImage, p, en, parent, last_sib, 0, FL_ERROR)
in
  if ige(lnk, 0) then let
    val m1 = doc_node_add(d, KMark, p, iadd(p, 2), lnk, ~1, 0, FL_ERROR)
    val raw = (if igt(en, iadd(p, 2)) then doc_node_add(d, KRaw, iadd(p, 2), en, lnk, m1, 0, FL_ERROR) else m1)
    val () = doc_node_close(d, lnk, en, iadd(p, 2), en)
    val () = last_sib := lnk
  in
    en
  end else ~1
end

fun try_link_or_image(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int, depth: int, is_img: bool
): int = let
  val l_st = (if is_img then iadd(p, 2) else iadd(p, 1))
  val r_b = find_char(d, l_st, en, 93)
in
  if ige(r_b, l_st) andalso ilt(iadd(r_b, 1), en) andalso ieq(doc_byte(d, iadd(r_b, 1)), CHAR_LPAREN) then let
    val r_p = find_char(d, iadd(r_b, 2), en, 41)
  in
    if igt(r_p, iadd(r_b, 1)) then let
      val () = emit_text(d, parent, last_sib, txt_st, p)
      val k = (if is_img then KImage else KLink)
      val lnk = doc_node_add(d, k, p, iadd(r_p, 1), parent, last_sib, 0, 0)
    in
      if ige(lnk, 0) then (
        link_add_children(d, lnk, p, l_st, r_b, r_p, depth);
        last_sib := lnk;
        iadd(r_p, 1)
      ) else ~1
    end else link_unclosed(d, parent, last_sib, p, en, txt_st, l_st, r_b, depth, is_img)
  end else if is_img andalso igt(en, l_st) then img_unclosed(d, parent, last_sib, p, en, txt_st)
  else ~1
end

fun mathb_unclosed(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int
): int = let
  val () = emit_text(d, parent, last_sib, txt_st, p)
  val m_node = doc_node_add(d, KMathb, p, en, parent, last_sib, 0, FL_ERROR)
in
  if ige(m_node, 0) then let
    val m1 = doc_node_add(d, KMark, p, iadd(p, 2), m_node, ~1, 0, FL_ERROR)
    val raw = (if igt(en, iadd(p, 2)) then doc_node_add(d, KRaw, iadd(p, 2), en, m_node, m1, 0, FL_ERROR) else m1)
    val () = doc_node_close(d, m_node, en, iadd(p, 2), en)
    val () = last_sib := m_node
  in
    en
  end else ~1
end

fun mathb_attach(d: !Doc, m_node: int, p: int, c_pos: int, m_end: int): void = let
  val m1 = doc_node_add(d, KMark, p, iadd(p, 2), m_node, ~1, 0, 0)
  val raw = (if igt(c_pos, iadd(p, 2)) then doc_node_add(d, KRaw, iadd(p, 2), c_pos, m_node, m1, 0, 0) else m1)
  val _ = doc_node_add(d, KMark, c_pos, m_end, m_node, raw, 0, 0)
  val () = doc_node_close(d, m_node, m_end, iadd(p, 2), c_pos)
in
end

fun try_mathb(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int
): int = let
  val c_pos = find_pair(d, iadd(p, 2), en, 36, 36)
in
  if igt(c_pos, iadd(p, 1)) then let
    val () = emit_text(d, parent, last_sib, txt_st, p)
    val m_end = iadd(c_pos, 2)
    val m_node = doc_node_add(d, KMathb, p, m_end, parent, last_sib, 0, 0)
    val () = if ige(m_node, 0) then (mathb_attach(d, m_node, p, c_pos, m_end); last_sib := m_node) else ()
  in
    if ige(m_node, 0) then m_end else ~1
  end else if igt(en, iadd(p, 2)) then mathb_unclosed(d, parent, last_sib, p, en, txt_st)
  else ~1
end

fun math_attach(d: !Doc, m_node: int, p: int, c_pos: int, m_end: int): void = let
  val m1 = doc_node_add(d, KMark, p, iadd(p, 1), m_node, ~1, 0, 0)
  val raw = (if igt(c_pos, iadd(p, 1)) then doc_node_add(d, KRaw, iadd(p, 1), c_pos, m_node, m1, 0, 0) else m1)
  val _ = doc_node_add(d, KMark, c_pos, m_end, m_node, raw, 0, 0)
  val () = doc_node_close(d, m_node, m_end, iadd(p, 1), c_pos)
in
end

fun try_math_single(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int
): int = let
  val c_pos = find_char(d, iadd(p, 1), en, 36)
in
  if igt(c_pos, p) then let
    val () = emit_text(d, parent, last_sib, txt_st, p)
    val m_end = iadd(c_pos, 1)
    val m_node = doc_node_add(d, KMath, p, m_end, parent, last_sib, 0, 0)
    val () = if ige(m_node, 0) then (math_attach(d, m_node, p, c_pos, m_end); last_sib := m_node) else ()
  in
    if ige(m_node, 0) then m_end else ~1
  end else ~1
end
