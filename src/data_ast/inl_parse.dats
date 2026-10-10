#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_ast/ast.sats"
staload "data_ast/doc.sats"
staload "data_ast/inl_parse.sats"

fun is_space_tab(b: int): bool = ieq(b, 32) orelse ieq(b, 9)

fun is_ascii_punct(b: int): bool =
  (ige(b, 33) andalso ile(b, 47)) orelse
  (ige(b, 58) andalso ile(b, 64)) orelse
  (ige(b, 91) andalso ile(b, 96)) orelse
  (ige(b, 123) andalso ile(b, 126))

fun emit_text(
  d: !Doc, parent: int, last_sib: &int >> _, st: int, en: int
): void =
  if igt(en, st) then let
    val node = doc_node_add(d, KText, st, en, parent, last_sib, 0, 0)
  in
    if ige(node, 0) then last_sib := node else ()
  end else ()

extern fun find_char_exh(d: !Doc, p: int, en: int, ch: int): int = "mac#anth_die_int"

fun find_char_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, ch: int
): int =
  if recfuel > 0 then (
    if ige(p, en) then ~1
    else if ieq(doc_byte(d, p), ch) then p
    else find_char_m(recfuel - 1, d, iadd(p, 1), en, ch)
  ) else find_char_exh(d, p, en, ch)

fun find_char(d: !Doc, p: int, en: int, ch: int): int =
  find_char_m(airlock_nat(MAX_REC_FUEL), d, p, en, ch)

extern fun find_pair_exh(d: !Doc, p: int, en: int, b1: int, b2: int): int = "mac#anth_die_int"

fun find_pair_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, b1: int, b2: int
): int =
  if recfuel > 0 then (
    if ige(iadd(p, 1), en) then ~1
    else if ieq(doc_byte(d, p), b1) andalso ieq(doc_byte(d, iadd(p, 1)), b2) then p
    else find_pair_m(recfuel - 1, d, iadd(p, 1), en, b1, b2)
  ) else find_pair_exh(d, p, en, b1, b2)

fun find_pair(d: !Doc, p: int, en: int, b1: int, b2: int): int =
  find_pair_m(airlock_nat(MAX_REC_FUEL), d, p, en, b1, b2)

extern fun count_char_run_exh(d: !Doc, p: int, en: int, ch: int, c: int): int = "mac#anth_die_int"

fun count_char_run_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, ch: int, c: int
): int =
  if recfuel > 0 then (
    if ige(p, en) then c
    else if ieq(doc_byte(d, p), ch) then count_char_run_m(recfuel - 1, d, iadd(p, 1), en, ch, iadd(c, 1))
    else c
  ) else count_char_run_exh(d, p, en, ch, c)

fun count_char_run(d: !Doc, p: int, en: int, ch: int): int =
  count_char_run_m(airlock_nat(MAX_REC_FUEL), d, p, en, ch, 0)

extern fun find_bt_run_exh(d: !Doc, p: int, en: int, n: int): int = "mac#anth_die_int"

fun find_bt_run_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, n: int
): int =
  if recfuel > 0 then (
    if ige(p, en) then ~1
    else if ieq(doc_byte(d, p), 96) then let
      val c = count_char_run(d, p, en, 96)
    in
      if ieq(c, n) then p else find_bt_run_m(recfuel - 1, d, iadd(p, c), en, n)
    end else find_bt_run_m(recfuel - 1, d, iadd(p, 1), en, n)
  ) else find_bt_run_exh(d, p, en, n)

fun try_codespan(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int
): int = let
  val n = count_char_run(d, p, en, 96)
  val c_pos = find_bt_run_m(airlock_nat(MAX_REC_FUEL), d, iadd(p, n), en, n)
in
  if igt(c_pos, 0) then let
    val () = emit_text(d, parent, last_sib, txt_st, p)
    val span_end = iadd(c_pos, n)
    val cs = doc_node_add(d, KCodeSpan, p, span_end, parent, last_sib, 0, 0)
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
  end else ~1
end

fun wiki_add_parts(
  d: !Doc, wiki_node: int, m1: int, st: int, en: int, pipe: int
): int =
  if ige(pipe, st) then let
    val t = doc_node_add(d, KWikiTarget, st, pipe, wiki_node, m1, 0, 0)
    val m_mid = doc_node_add(d, KMark, pipe, iadd(pipe, 1), wiki_node, t, 0, 0)
    val al = doc_node_add(d, KWikiAlias, iadd(pipe, 1), en, wiki_node, m_mid, 0, 0)
  in
    al
  end else doc_node_add(d, KWikiTarget, st, en, wiki_node, m1, 0, 0)

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
    val k = (if is_embed then KEmbed else KWiki)
    val w_node = doc_node_add(d, k, p, w_end, parent, last_sib, 0, 0)
  in
    if ige(w_node, 0) then let
      val m1 = doc_node_add(d, KMark, p, inner_st, w_node, ~1, 0, 0)
      val pipe = find_char(d, inner_st, c_pos, 124)
      val last_ch = wiki_add_parts(d, w_node, m1, inner_st, c_pos, pipe)
      val _ = doc_node_add(d, KMark, c_pos, w_end, w_node, last_ch, 0, 0)
      val () = doc_node_close(d, w_node, w_end, inner_st, c_pos)
      val () = last_sib := w_node
    in
      w_end
    end else ~1
  end else ~1
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

fun try_link_or_image(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int, depth: int, is_img: bool
): int = let
  val l_st = (if is_img then iadd(p, 2) else iadd(p, 1))
  val r_b = find_char(d, l_st, en, 93)
in
  if ige(r_b, l_st) andalso ilt(iadd(r_b, 1), en) andalso ieq(doc_byte(d, iadd(r_b, 1)), 40) then let
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
    end else ~1
  end else ~1
end

fun try_math(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int
): int =
  if ilt(iadd(p, 1), en) andalso ieq(doc_byte(d, iadd(p, 1)), 36) then let
    val c_pos = find_pair(d, iadd(p, 2), en, 36, 36)
  in
    if igt(c_pos, iadd(p, 1)) then let
      val () = emit_text(d, parent, last_sib, txt_st, p)
      val m_end = iadd(c_pos, 2)
      val m_node = doc_node_add(d, KMathb, p, m_end, parent, last_sib, 0, 0)
    in
      if ige(m_node, 0) then let
        val m1 = doc_node_add(d, KMark, p, iadd(p, 2), m_node, ~1, 0, 0)
        val raw = (if igt(c_pos, iadd(p, 2)) then doc_node_add(d, KRaw, iadd(p, 2), c_pos, m_node, m1, 0, 0) else m1)
        val _ = doc_node_add(d, KMark, c_pos, m_end, m_node, raw, 0, 0)
        val () = doc_node_close(d, m_node, m_end, iadd(p, 2), c_pos)
        val () = last_sib := m_node
      in
        m_end
      end else ~1
    end else ~1
  end else let
    val c_pos = find_char(d, iadd(p, 1), en, 36)
  in
    if igt(c_pos, p) then let
      val () = emit_text(d, parent, last_sib, txt_st, p)
      val m_end = iadd(c_pos, 1)
      val m_node = doc_node_add(d, KMath, p, m_end, parent, last_sib, 0, 0)
    in
      if ige(m_node, 0) then let
        val m1 = doc_node_add(d, KMark, p, iadd(p, 1), m_node, ~1, 0, 0)
        val raw = (if igt(c_pos, iadd(p, 1)) then doc_node_add(d, KRaw, iadd(p, 1), c_pos, m_node, m1, 0, 0) else m1)
        val _ = doc_node_add(d, KMark, c_pos, m_end, m_node, raw, 0, 0)
        val () = doc_node_close(d, m_node, m_end, iadd(p, 1), c_pos)
        val () = last_sib := m_node
      in
        m_end
      end else ~1
    end else ~1
  end

fun is_tag_char(b: int): bool =
  (ige(b, 65) andalso ile(b, 90)) orelse (ige(b, 97) andalso ile(b, 122)) orelse
  (ige(b, 48) andalso ile(b, 57)) orelse ieq(b, 95) orelse ieq(b, 45) orelse ieq(b, 47)

fun is_tag_start(b: int): bool =
  (ige(b, 65) andalso ile(b, 90)) orelse (ige(b, 97) andalso ile(b, 122)) orelse ieq(b, 95)

extern fun scan_tag_end_exh(d: !Doc, p: int, en: int): int = "mac#anth_die_int"

fun scan_tag_end_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int
): int =
  if recfuel > 0 then (
    if ige(p, en) then p
    else if is_tag_char(doc_byte(d, p)) then scan_tag_end_m(recfuel - 1, d, iadd(p, 1), en)
    else p
  ) else scan_tag_end_exh(d, p, en)

fun try_tag(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int, orig_st: int
): int =
  if ilt(iadd(p, 1), en) andalso is_tag_start(doc_byte(d, iadd(p, 1))) andalso (
    ieq(p, orig_st) orelse is_space_tab(doc_byte(d, isub(p, 1)))
  ) then let
    val t_end = scan_tag_end_m(airlock_nat(MAX_REC_FUEL), d, iadd(p, 2), en)
    val () = emit_text(d, parent, last_sib, txt_st, p)
    val tag = doc_node_add(d, KTag, p, t_end, parent, last_sib, 0, 0)
  in
    if ige(tag, 0) then (last_sib := tag; t_end) else ~1
  end else ~1

fun is_url_char(b: int): bool =
  not(is_space_tab(b)) andalso ine(b, 10) andalso ine(b, 13) andalso ine(b, 60) andalso ine(b, 62)

extern fun scan_url_end_exh(d: !Doc, p: int, en: int): int = "mac#anth_die_int"

fun scan_url_end_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int
): int =
  if recfuel > 0 then (
    if ige(p, en) then p
    else if is_url_char(doc_byte(d, p)) then scan_url_end_m(recfuel - 1, d, iadd(p, 1), en)
    else p
  ) else scan_url_end_exh(d, p, en)

fun check_url_prefix(d: !Doc, p: int, en: int): int =
  if ilt(iadd(p, 7), en) andalso ieq(doc_byte(d, p), 104) andalso ieq(doc_byte(d, iadd(p, 1)), 116)
     andalso ieq(doc_byte(d, iadd(p, 2)), 116) andalso ieq(doc_byte(d, iadd(p, 3)), 112) then (
    if ieq(doc_byte(d, iadd(p, 4)), 115) andalso ieq(doc_byte(d, iadd(p, 5)), 58)
       andalso ieq(doc_byte(d, iadd(p, 6)), 47) andalso ieq(doc_byte(d, iadd(p, 7)), 47) then 8
    else if ieq(doc_byte(d, iadd(p, 4)), 58) andalso ieq(doc_byte(d, iadd(p, 5)), 47)
       andalso ieq(doc_byte(d, iadd(p, 6)), 47) then 7
    else 0
  ) else 0

fun try_bare_url(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int
): int = let
  val pre = check_url_prefix(d, p, en)
in
  if igt(pre, 0) then let
    val u_end = scan_url_end_m(airlock_nat(MAX_REC_FUEL), d, iadd(p, pre), en)
    val () = emit_text(d, parent, last_sib, txt_st, p)
    val url = doc_node_add(d, KUrl, p, u_end, parent, last_sib, 0, FL_BARE)
  in
    if ige(url, 0) then (last_sib := url; u_end) else ~1
  end else ~1
end

fun dispatch_punct1(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int, depth: int, b: int
): int =
  if ieq(b, 92) andalso ilt(iadd(p, 1), en) andalso is_ascii_punct(doc_byte(d, iadd(p, 1))) then let
    val () = emit_text(d, parent, last_sib, txt_st, p)
    val esc = doc_node_add(d, KEscape, p, iadd(p, 2), parent, last_sib, 0, 0)
    val () = if ige(esc, 0) then last_sib := esc else ()
  in
    iadd(p, 2)
  end
  else if ieq(b, 96) then try_codespan(d, parent, last_sib, p, en, txt_st)
  else if ieq(b, 33) andalso ilt(iadd(p, 2), en) andalso ieq(doc_byte(d, iadd(p, 1)), 91)
          andalso ieq(doc_byte(d, iadd(p, 2)), 91) then
    try_wiki(d, parent, last_sib, p, en, txt_st, true)
  else if ieq(b, 91) andalso ilt(iadd(p, 1), en) andalso ieq(doc_byte(d, iadd(p, 1)), 91) then
    try_wiki(d, parent, last_sib, p, en, txt_st, false)
  else if ieq(b, 33) andalso ilt(iadd(p, 1), en) andalso ieq(doc_byte(d, iadd(p, 1)), 91) then
    try_link_or_image(d, parent, last_sib, p, en, txt_st, depth, true)
  else if ieq(b, 91) then
    try_link_or_image(d, parent, last_sib, p, en, txt_st, depth, false)
  else ~1

fun dispatch_punct2(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int, orig_st: int, depth: int, b: int
): int =
  if ieq(b, 42) then (
    if ilt(iadd(p, 1), en) andalso ieq(doc_byte(d, iadd(p, 1)), 42)
    then parse_delim2(d, parent, last_sib, p, en, txt_st, depth, 42, KBold, 0)
    else parse_delim1(d, parent, last_sib, p, en, txt_st, depth, 42, KItalic, 0)
  )
  else if ieq(b, 95) then (
    if ilt(iadd(p, 1), en) andalso ieq(doc_byte(d, iadd(p, 1)), 95)
    then parse_delim2(d, parent, last_sib, p, en, txt_st, depth, 95, KBold, FL_UNDERSCORE)
    else parse_delim1(d, parent, last_sib, p, en, txt_st, depth, 95, KItalic, FL_UNDERSCORE)
  )
  else if ieq(b, 126) andalso ilt(iadd(p, 1), en) andalso ieq(doc_byte(d, iadd(p, 1)), 126) then
    parse_delim2(d, parent, last_sib, p, en, txt_st, depth, 126, KStrike, 0)
  else if ieq(b, 61) andalso ilt(iadd(p, 1), en) andalso ieq(doc_byte(d, iadd(p, 1)), 61) then
    parse_delim2(d, parent, last_sib, p, en, txt_st, depth, 61, KHigh, 0)
  else if ieq(b, 36) then try_math(d, parent, last_sib, p, en, txt_st)
  else if ieq(b, 35) then try_tag(d, parent, last_sib, p, en, txt_st, orig_st)
  else if ieq(b, 104) then try_bare_url(d, parent, last_sib, p, en, txt_st)
  else ~1

fun dispatch_syntax(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, depth: int, txt_st: int, orig_st: int
): int = let
  val b = doc_byte(d, p)
  val r1 = dispatch_punct1(d, parent, last_sib, p, en, txt_st, depth, b)
in
  if igt(r1, 0) then r1
  else dispatch_punct2(d, parent, last_sib, p, en, txt_st, orig_st, depth, b)
end

extern fun scan_inlines_exh(d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, depth: int, txt_st: int, orig_st: int): void = "mac#anth_die_void"

fun scan_inlines_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, parent: int, last_sib: &int >> _,
  p: int, en: int, depth: int, txt_st: int, orig_st: int
): void =
  if recfuel > 0 then (
    if ige(p, en) then emit_text(d, parent, last_sib, txt_st, en)
    else let
      val next_p = dispatch_syntax(d, parent, last_sib, p, en, depth, txt_st, orig_st)
    in
      if igt(next_p, p) then
        scan_inlines_m(recfuel - 1, d, parent, last_sib, next_p, en, depth, next_p, orig_st)
      else
        scan_inlines_m(recfuel - 1, d, parent, last_sib, iadd(p, 1), en, depth, txt_st, orig_st)
    end
  ) else scan_inlines_exh(d, parent, last_sib, p, en, depth, txt_st, orig_st)

implement inl_parse_depth(d, parent, st, en, depth, last_sib) =
  if ige(st, en) then ()
  else if ige(depth, MAX_INLINE_DEPTH) then
    emit_text(d, parent, last_sib, st, en)
  else
    scan_inlines_m(airlock_nat(MAX_REC_FUEL), d, parent, last_sib, st, en, depth, st, st)

implement inl_parse(d, blk_idx, st, en) = let
  var last_sib: int = ~1
in
  inl_parse_depth(d, blk_idx, st, en, 0, last_sib)
end
