extern fun find_one_fuel_exhausted(d: !Doc, i: int, re: int, a: int): int = "mac#anth_die_int"

fun find_one_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, a: int): int =
  if recfuel > 0 then (
    if ige(i, re) then ~1
    else if ieq(doc_byte(d, i), CHAR_LF) then ~1
    else if ieq(doc_byte(d, i), a) then i
    else find_one_with_fuel(recfuel - 1, d, iadd(i, 1), re, a)
  ) else find_one_fuel_exhausted(d, i, re, a)

fun find_one(d: !Doc, i: int, re: int, a: int): int = find_one_with_fuel(airlock_nat(MAX_REC_FUEL), d, i, re, a)

fun special_at(d: !Doc, i: int, re: int): bool =
  if ige(i, re) then false
  else if ieq(doc_byte(d, i), CHAR_DOLLAR) orelse ieq(doc_byte(d, i), CHAR_HASH) orelse ieq(doc_byte(d, i), CHAR_LBRACKET) orelse ieq(doc_byte(d, i), CHAR_STAR) orelse ieq(doc_byte(d, i), CHAR_TILDE) then true
  else if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, i), CHAR_EXCL) andalso ieq(doc_byte(d, iadd(i, 1)), CHAR_LBRACKET) then true
  else if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, i), CHAR_EQUAL) andalso ieq(doc_byte(d, iadd(i, 1)), CHAR_EQUAL) then true
  else false

extern fun text_nxt_fuel_exhausted(d: !Doc, re: int, k: int): int = "mac#anth_die_int"

fun text_nxt_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, re: int, k: int): int =
  if recfuel > 0 then (
    if ige(k, re) then k
    else if special_at(d, k, re) orelse ieq(doc_byte(d, k), CHAR_LF) then k
    else text_nxt_with_fuel(recfuel - 1, d, re, iadd(k, 1))
  ) else text_nxt_fuel_exhausted(d, re, k)

fun text_nxt(d: !Doc, re: int, k: int): int = text_nxt_with_fuel(airlock_nat(MAX_REC_FUEL), d, re, k)

extern fun tag_end_fuel_exhausted(d: !Doc, i: int, re: int): int = "mac#anth_die_int"

fun tag_end_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int): int =
  if recfuel > 0 then (
    if ige(i, re) then i
    else let
      val c = doc_byte(d, i)
    in
      if ieq(c, CHAR_SPACE) orelse ieq(c, CHAR_LF) orelse ieq(c, CHAR_TAB) then i
      else tag_end_with_fuel(recfuel - 1, d, iadd(i, 1), re)
    end
  ) else tag_end_fuel_exhausted(d, i, re)

fun tag_end(d: !Doc, i: int, re: int): int = tag_end_with_fuel(airlock_nat(MAX_REC_FUEL), d, i, re)

fun emit_double_inline(d: !Doc, i: int, re: int, depth: int, kind: NodeKind, ch: int): int = let
  val c = find_close(d, iadd(i, 2), re, ch, ch)
in
  if c < 0 then ~1
  else let
    val () = node_append(d, kind, i, iadd(c, 2), depth, 0)
  in
    iadd(c, 2)
  end
end

fun emit_single_inline(d: !Doc, i: int, re: int, depth: int, kind: NodeKind, ch: int): int = let
  val c = find_one(d, iadd(i, 1), re, ch)
in
  if c < 0 then ~1
  else let
    val () = node_append(d, kind, i, iadd(c, 1), depth, 0)
  in
    iadd(c, 1)
  end
end

fun emit_embed_inline(d: !Doc, i: int, re: int, depth: int): int = let
  val c = find_close(d, iadd(i, 2), re, CHAR_RBRACKET, CHAR_RBRACKET)
in
  if c < 0 then ~1
  else let
    val en = iadd(c, 2)
    val kind = if ext_image(d, iadd(i, 3), c) then KImage else KEmbed
    val () = node_append(d, kind, i, en, depth, 0)
  in
    en
  end
end

fun emit_image_inline(d: !Doc, i: int, re: int, depth: int): int = let
  val c = find_one(d, iadd(i, 4), re, CHAR_RPAREN)
in
  if c < 0 then ~1
  else let
    val () = node_append(d, KImage, i, iadd(c, 1), depth, 1)
  in
    iadd(c, 1)
  end
end

fun emit_fn_inline(d: !Doc, i: int, re: int, depth: int): int = let
  val c = find_one(d, iadd(i, 2), re, CHAR_RBRACKET)
in
  if c < 0 then ~1
  else let
    val () = node_append(d, KFn, i, iadd(c, 1), depth, 0)
  in
    iadd(c, 1)
  end
end

fun emit_link_inline(d: !Doc, i: int, re: int, depth: int): int = let
  val c_bracket = find_one(d, iadd(i, 1), re, CHAR_RBRACKET)
in
  if c_bracket < 0 orelse ige(iadd(c_bracket, 2), re) orelse ine(doc_byte(d, iadd(c_bracket, 1)), CHAR_LPAREN) then ~1
  else let
    val c_paren = find_one(d, iadd(c_bracket, 2), re, CHAR_RPAREN)
  in
    if c_paren < 0 then ~1
    else let
      val en = iadd(c_paren, 1)
      val () = node_append(d, KLink, i, en, depth, c_bracket)
    in
      en
    end
  end
end

fun emit_tag_inline(d: !Doc, i: int, re: int, depth: int): int = let
  val e = tag_end(d, iadd(i, 1), re)
in
  if ile(e, iadd(i, 1)) then ~1
  else let
    val () = node_append(d, KTag, i, e, depth, 0)
  in
    e
  end
end

fun emit_bang_inline(d: !Doc, i: int, re: int, depth: int): int =
  if ilt(iadd(i, 2), re) andalso ieq(doc_byte(d, i), CHAR_EXCL) andalso ieq(doc_byte(d, iadd(i, 1)), CHAR_LBRACKET) andalso ieq(doc_byte(d, iadd(i, 2)), CHAR_LBRACKET) then emit_embed_inline(d, i, re, depth)
  else if ilt(iadd(i, 3), re) andalso ieq(doc_byte(d, i), CHAR_EXCL) andalso ieq(doc_byte(d, iadd(i, 1)), CHAR_LBRACKET) andalso ieq(doc_byte(d, iadd(i, 2)), CHAR_RBRACKET) andalso ieq(doc_byte(d, iadd(i, 3)), CHAR_LPAREN) then emit_image_inline(d, i, re, depth)
  else ~1

fun emit_bracket_inline(d: !Doc, i: int, re: int, depth: int): int =
  if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, iadd(i, 1)), CHAR_LBRACKET) then emit_double_inline(d, i, re, depth, KWiki, CHAR_RBRACKET)
  else if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, iadd(i, 1)), CHAR_CARET) then emit_fn_inline(d, i, re, depth)
  else emit_link_inline(d, i, re, depth)

fun emit_star_inline(d: !Doc, i: int, re: int, depth: int): int =
  if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, iadd(i, 1)), CHAR_STAR) then emit_double_inline(d, i, re, depth, KBold, CHAR_STAR)
  else emit_single_inline(d, i, re, depth, KItalic, CHAR_STAR)

fun emit_strike_inline(d: !Doc, i: int, re: int, depth: int): int =
  if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, iadd(i, 1)), CHAR_TILDE) then emit_double_inline(d, i, re, depth, KStrike, CHAR_TILDE)
  else ~1

fun emit_high_inline(d: !Doc, i: int, re: int, depth: int): int =
  if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, iadd(i, 1)), CHAR_EQUAL) then emit_double_inline(d, i, re, depth, KHigh, CHAR_EQUAL)
  else ~1

fun emit_math_inline(d: !Doc, i: int, re: int, depth: int): int =
  if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, iadd(i, 1)), CHAR_DOLLAR) then emit_double_inline(d, i, re, depth, KMathb, CHAR_DOLLAR)
  else emit_single_inline(d, i, re, depth, KMath, CHAR_DOLLAR)

(* Emits the inline construct starting at i (if any); returns its end, or ~1 when none applies. *)
fun emit_construct(d: !Doc, i: int, re: int, depth: int): int =
  if ieq(doc_byte(d, i), CHAR_EXCL) then emit_bang_inline(d, i, re, depth)
  else if ieq(doc_byte(d, i), CHAR_LBRACKET) then emit_bracket_inline(d, i, re, depth)
  else if ieq(doc_byte(d, i), CHAR_STAR) then emit_star_inline(d, i, re, depth)
  else if ieq(doc_byte(d, i), CHAR_TILDE) then emit_strike_inline(d, i, re, depth)
  else if ieq(doc_byte(d, i), CHAR_EQUAL) then emit_high_inline(d, i, re, depth)
  else if ieq(doc_byte(d, i), CHAR_DOLLAR) then emit_math_inline(d, i, re, depth)
  else if ieq(doc_byte(d, i), CHAR_HASH) then emit_tag_inline(d, i, re, depth)
  else ~1

extern fun emit_inlines_fuel_exhausted(d: !Doc, i: int, re: int, depth: int): void = "mac#anth_die_void"

fun emit_inlines_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, depth: int): void =
  if recfuel > 0 then (
    if ige(i, re) then ()
    else if ieq(doc_byte(d, i), CHAR_LF) then emit_inlines_with_fuel(recfuel - 1, d, iadd(i, 1), re, depth)
    else let
      val en = emit_construct(d, i, re, depth)
    in
      if en < 0 then emit_text_or(recfuel - 1, d, i, re, depth)
      else emit_inlines_with_fuel(recfuel - 1, d, en, re, depth)
    end
  ) else emit_inlines_fuel_exhausted(d, i, re, depth)

and emit_text_or {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, depth: int): void =
  if recfuel > 0 then let
    val e = text_nxt(d, re, iadd(i, 1))
    val () = if igt(e, i) then node_append(d, KText, i, e, depth, 0) else ()
  in
    emit_inlines_with_fuel(recfuel - 1, d, e, re, depth)
  end else ()

fun emit_inlines(d: !Doc, i: int, re: int, depth: int): void = emit_inlines_with_fuel(airlock_nat(MAX_REC_FUEL), d, i, re, depth)

datatype Gather = GatherAny | GatherQuote | GatherTable

fun gather_code(g: Gather): int = case+ g of
  | GatherAny() => 0
  | GatherQuote() => 1
  | GatherTable() => 2

fun is_gather(a: Gather, b: Gather): bool = ieq(gather_code(a), gather_code(b))

