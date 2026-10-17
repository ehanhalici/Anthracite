fun try_math(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int
): int =
  if ilt(iadd(p, 1), en) andalso ieq(doc_byte(d, iadd(p, 1)), CHAR_DOLLAR)
  then try_mathb(d, parent, last_sib, p, en, txt_st)
  else try_math_single(d, parent, last_sib, p, en, txt_st)

fun is_tag_char(b: int): bool =
  (ige(b, CHAR_UPPER_A) andalso ile(b, CHAR_UPPER_Z)) orelse (ige(b, CHAR_LOWER_A) andalso ile(b, CHAR_LOWER_Z)) orelse
  (ige(b, CHAR_ZERO) andalso ile(b, CHAR_NINE)) orelse ieq(b, CHAR_UNDERSCORE) orelse ieq(b, CHAR_MINUS) orelse ieq(b, CHAR_SLASH)

fun is_tag_start(b: int): bool =
  (ige(b, CHAR_UPPER_A) andalso ile(b, CHAR_UPPER_Z)) orelse (ige(b, CHAR_LOWER_A) andalso ile(b, CHAR_LOWER_Z)) orelse ieq(b, CHAR_UNDERSCORE)

extern fun scan_tag_end_fuel_exhausted(d: !Doc, p: int, en: int): int = "mac#anth_die_int"

fun scan_tag_end_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(p, en) then p
    else if is_tag_char(doc_byte(d, p)) then scan_tag_end_with_fuel(recfuel - 1, d, iadd(p, 1), en)
    else p
  ) else scan_tag_end_fuel_exhausted(d, p, en)

fun try_tag(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int, orig_st: int
): int =
  if ilt(iadd(p, 1), en) andalso is_tag_start(doc_byte(d, iadd(p, 1))) andalso (
    ieq(p, orig_st) orelse is_space_tab(doc_byte(d, isub(p, 1)))
  ) then let
    val t_end = scan_tag_end_with_fuel(airlock_nat(MAX_REC_FUEL), d, iadd(p, 2), en)
    val () = emit_text(d, parent, last_sib, txt_st, p)
    val tag = doc_node_add(d, KTag, p, t_end, parent, last_sib, 0, 0)
  in
    if ige(tag, 0) then (last_sib := tag; t_end) else ~1
  end else ~1

fun is_url_char(b: int): bool =
  not(is_space_tab(b)) andalso ine(b, CHAR_LF) andalso ine(b, CHAR_CR) andalso ine(b, CHAR_LT) andalso ine(b, CHAR_GT)

extern fun scan_url_end_fuel_exhausted(d: !Doc, p: int, en: int): int = "mac#anth_die_int"

fun scan_url_end_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(p, en) then p
    else if is_url_char(doc_byte(d, p)) then scan_url_end_with_fuel(recfuel - 1, d, iadd(p, 1), en)
    else p
  ) else scan_url_end_fuel_exhausted(d, p, en)

fun check_url_prefix(d: !Doc, p: int, en: int): int =
  if ilt(iadd(p, 7), en) andalso ieq(doc_byte(d, p), 104) andalso ieq(doc_byte(d, iadd(p, 1)), 116)
     andalso ieq(doc_byte(d, iadd(p, 2)), 116) andalso ieq(doc_byte(d, iadd(p, 3)), 112) then (
    if ieq(doc_byte(d, iadd(p, 4)), 115) andalso ieq(doc_byte(d, iadd(p, 5)), CHAR_COLON)
       andalso ieq(doc_byte(d, iadd(p, 6)), CHAR_SLASH) andalso ieq(doc_byte(d, iadd(p, 7)), CHAR_SLASH) then 8
    else if ieq(doc_byte(d, iadd(p, 4)), CHAR_COLON) andalso ieq(doc_byte(d, iadd(p, 5)), CHAR_SLASH)
       andalso ieq(doc_byte(d, iadd(p, 6)), CHAR_SLASH) then 7
    else 0
  ) else 0

fun try_bare_url(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int
): int = let
  val pre = check_url_prefix(d, p, en)
in
  if igt(pre, 0) then let
    val u_end = scan_url_end_with_fuel(airlock_nat(MAX_REC_FUEL), d, iadd(p, pre), en)
    val () = emit_text(d, parent, last_sib, txt_st, p)
    val url = doc_node_add(d, KUrl, p, u_end, parent, last_sib, 0, FL_BARE)
  in
    if ige(url, 0) then (last_sib := url; u_end) else ~1
  end else ~1
end

fun dispatch_punct1(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int, depth: int, b: int
): int =
  if ieq(b, CHAR_BACKSLASH) andalso ilt(iadd(p, 1), en) andalso is_ascii_punct(doc_byte(d, iadd(p, 1))) then let
    val () = emit_text(d, parent, last_sib, txt_st, p)
    val esc = doc_node_add(d, KEscape, p, iadd(p, 2), parent, last_sib, 0, 0)
    val () = if ige(esc, 0) then last_sib := esc else ()
  in
    iadd(p, 2)
  end
  else if ieq(b, CHAR_BACKTICK) then try_codespan(d, parent, last_sib, p, en, txt_st)
  else if ieq(b, CHAR_EXCL) andalso ilt(iadd(p, 2), en) andalso ieq(doc_byte(d, iadd(p, 1)), CHAR_LBRACKET)
          andalso ieq(doc_byte(d, iadd(p, 2)), CHAR_LBRACKET) then
    try_wiki(d, parent, last_sib, p, en, txt_st, true)
  else if ieq(b, CHAR_LBRACKET) andalso ilt(iadd(p, 1), en) andalso ieq(doc_byte(d, iadd(p, 1)), CHAR_LBRACKET) then
    try_wiki(d, parent, last_sib, p, en, txt_st, false)
  else if ieq(b, CHAR_EXCL) andalso ilt(iadd(p, 1), en) andalso ieq(doc_byte(d, iadd(p, 1)), CHAR_LBRACKET) then
    try_link_or_image(d, parent, last_sib, p, en, txt_st, depth, true)
  else if ieq(b, CHAR_LBRACKET) then
    try_link_or_image(d, parent, last_sib, p, en, txt_st, depth, false)
  else ~1

fun dispatch_punct2(
  d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, txt_st: int, orig_st: int, depth: int, b: int
): int =
  if ieq(b, CHAR_STAR) then (
    if ilt(iadd(p, 1), en) andalso ieq(doc_byte(d, iadd(p, 1)), CHAR_STAR)
    then parse_delim2(d, parent, last_sib, p, en, txt_st, depth, 42, KBold, 0)
    else parse_delim1(d, parent, last_sib, p, en, txt_st, depth, 42, KItalic, 0)
  )
  else if ieq(b, CHAR_UNDERSCORE) then (
    if ilt(iadd(p, 1), en) andalso ieq(doc_byte(d, iadd(p, 1)), CHAR_UNDERSCORE)
    then parse_delim2(d, parent, last_sib, p, en, txt_st, depth, 95, KBold, FL_UNDERSCORE)
    else parse_delim1(d, parent, last_sib, p, en, txt_st, depth, 95, KItalic, FL_UNDERSCORE)
  )
  else if ieq(b, CHAR_TILDE) andalso ilt(iadd(p, 1), en) andalso ieq(doc_byte(d, iadd(p, 1)), CHAR_TILDE) then
    parse_delim2(d, parent, last_sib, p, en, txt_st, depth, 126, KStrike, 0)
  else if ieq(b, CHAR_EQUAL) andalso ilt(iadd(p, 1), en) andalso ieq(doc_byte(d, iadd(p, 1)), CHAR_EQUAL) then
    parse_delim2(d, parent, last_sib, p, en, txt_st, depth, 61, KHigh, 0)
  else if ieq(b, CHAR_DOLLAR) then try_math(d, parent, last_sib, p, en, txt_st)
  else if ieq(b, CHAR_HASH) then try_tag(d, parent, last_sib, p, en, txt_st, orig_st)
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

extern fun scan_inlines_fuel_exhausted(d: !Doc, parent: int, last_sib: &int >> _, p: int, en: int, depth: int, txt_st: int, orig_st: int): void = "mac#anth_die_void"

fun scan_inlines_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, parent: int, last_sib: &int >> _,
  p: int, en: int, depth: int, txt_st: int, orig_st: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ige(p, en) then emit_text(d, parent, last_sib, txt_st, en)
    else let
      val next_p = dispatch_syntax(d, parent, last_sib, p, en, depth, txt_st, orig_st)
    in
      if igt(next_p, p) then
        scan_inlines_with_fuel(recfuel - 1, d, parent, last_sib, next_p, en, depth, next_p, orig_st)
      else
        scan_inlines_with_fuel(recfuel - 1, d, parent, last_sib, iadd(p, 1), en, depth, txt_st, orig_st)
    end
  ) else scan_inlines_fuel_exhausted(d, parent, last_sib, p, en, depth, txt_st, orig_st)

implement inl_parse_depth(d, parent, st, en, depth, last_sib) =
  if ige(st, en) then ()
  else if ige(depth, MAX_INLINE_DEPTH) then
    emit_text(d, parent, last_sib, st, en)
  else
    scan_inlines_with_fuel(airlock_nat(MAX_REC_FUEL), d, parent, last_sib, st, en, depth, st, st)

implement inl_parse(d, blk_idx, st, en) = let
  var last_sib: int = ~1
in
  inl_parse_depth(d, blk_idx, st, en, 0, last_sib)
end
