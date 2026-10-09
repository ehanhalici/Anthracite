#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_ast/doc.sats"
staload "data_ast/doc_parse.sats"

fun npush(d: !Doc, kind: NodeKind, st: int, en: int, depth: int, aux: int): void =
  doc_push_node(d, kind, st, en, depth, aux)

extern fun at_end_exh(d: !Doc, i: int, re: int): int = "mac#anth_die_int"

fun at_end_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int): int =
  if recfuel > 0 then (
    if ige(i, re) then re
    else if ieq(doc_byte(d, i), CHAR_LF) then i
    else at_end_m(recfuel - 1, d, iadd(i, 1), re)
  ) else at_end_exh(d, i, re)

fun at_end(d: !Doc, i: int, re: int): int = at_end_m(airlock_nat(MAX_REC_FUEL), d, i, re)

extern fun skip_sp_exh(d: !Doc, i: int, re: int): int = "mac#anth_die_int"

fun skip_sp_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int): int =
  if recfuel > 0 then (
    if ige(i, re) then i
    else if ieq(doc_byte(d, i), CHAR_SPACE) orelse ieq(doc_byte(d, i), CHAR_TAB) then skip_sp_m(recfuel - 1, d, iadd(i, 1), re)
    else i
  ) else skip_sp_exh(d, i, re)

fun skip_sp(d: !Doc, i: int, re: int): int = skip_sp_m(airlock_nat(MAX_REC_FUEL), d, i, re)

extern fun starts_go_exh(d: !Doc, i: int, re: int, s: string, k: int, n: int): int = "mac#anth_die_int"

fun starts_go_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, s: string, k: int, n: int): int =
  if recfuel > 0 then (
    if ige(k, n) then 1
    else if ige(iadd(i, k), re) then 0
    else if ine(doc_byte(d, iadd(i, k)), c_str_byte(s, k)) then 0
    else starts_go_m(recfuel - 1, d, i, re, s, iadd(k, 1), n)
  ) else starts_go_exh(d, i, re, s, k, n)

fun starts_go(d: !Doc, i: int, re: int, s: string, k: int, n: int): int = starts_go_m(airlock_nat(MAX_REC_FUEL), d, i, re, s, k, n)

fun starts_at(d: !Doc, i: int, re: int, s: string): int =
  starts_go(d, i, re, s, 0, c_strlen(s))

fun blank_line(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
in
  ige(j, re) orelse ieq(doc_byte(d, j), CHAR_LF)
end

extern fun count_hash_exh(d: !Doc, i: int, re: int, n: int): int = "mac#anth_die_int"

fun count_hash_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, n: int): int =
  if recfuel > 0 then (
    if n >= 6 orelse ige(i, re) orelse ine(doc_byte(d, i), CHAR_HASH) then n
    else count_hash_m(recfuel - 1, d, iadd(i, 1), re, iadd(n, 1))
  ) else count_hash_exh(d, i, re, n)

fun count_hash(d: !Doc, i: int, re: int, n: int): int = count_hash_m(airlock_nat(MAX_REC_FUEL), d, i, re, n)

fun is_heading(d: !Doc, i: int, re: int): bool = let
  val sp = skip_sp(d, i, re)
  val hashes = count_hash(d, sp, re, 0)
in
  igt(hashes, 0) andalso ilt(iadd(sp, hashes), re) andalso ieq(doc_byte(d, iadd(sp, hashes)), CHAR_SPACE)
end

fun forward(d: !Doc, i: int, re: int, en: int): int =
  if igt(en, i) then en
  else let
    val e = at_end(d, i, re)
  in
    if ilt(e, re) then iadd(e, 1) else re
  end

extern fun hr_go_exh(d: !Doc, re: int, c: int, k: int, n: int): int = "mac#anth_die_int"

fun hr_go_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, re: int, c: int, k: int, n: int): int =
  if recfuel > 0 then (
    if ige(k, re) orelse ieq(doc_byte(d, k), CHAR_LF) then (if igt(n, 2) then 1 else 0)
    else if ieq(doc_byte(d, k), c) orelse ieq(doc_byte(d, k), CHAR_SPACE) then hr_go_m(recfuel - 1, d, re, c, iadd(k, 1), (if ieq(doc_byte(d, k), c) then iadd(n, 1) else n))
    else 0
  ) else hr_go_exh(d, re, c, k, n)

fun hr_go(d: !Doc, re: int, c: int, k: int, n: int): int = hr_go_m(airlock_nat(MAX_REC_FUEL), d, re, c, k, n)

fun is_hr(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
  val c = if ilt(j, re) then doc_byte(d, j) else 0
in
  if ieq(c, CHAR_MINUS) orelse ieq(c, CHAR_STAR) orelse ieq(c, CHAR_UNDERSCORE) then ieq(hr_go(d, re, c, j, 0), 1) else false
end

fun is_fence(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
in
  if isub(j, i) > 3 then false else ieq(starts_at(d, j, re, "```"), 1)
end

fun is_task(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
  val c = if ilt(j, re) then doc_byte(d, j) else 0
  val k = skip_sp(d, iadd(j, 1), re)
in
  (ieq(c, CHAR_MINUS) orelse ieq(c, CHAR_STAR) orelse ieq(c, CHAR_PLUS)) andalso ilt(iadd(k, 2), re) andalso ieq(doc_byte(d, k), CHAR_LBRACKET) andalso ieq(doc_byte(d, iadd(k, 2)), CHAR_RBRACKET)
end

fun task_aux(d: !Doc, i: int, re: int): int = let
  val j = skip_sp(d, i, re)
  val k = skip_sp(d, iadd(j, 1), re)
  val c = doc_byte(d, iadd(k, 1))
in
  task_aux_code(task_mark_of(c))
end

fun is_ul(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
  val c = if ilt(j, re) then doc_byte(d, j) else 0
  val n = if ilt(iadd(j, 1), re) then doc_byte(d, iadd(j, 1)) else 0
in
  if is_task(d, i, re) then false
  else (ieq(c, CHAR_MINUS) orelse ieq(c, CHAR_STAR) orelse ieq(c, CHAR_PLUS)) andalso (ieq(n, CHAR_SPACE) orelse ieq(n, CHAR_TAB))
end

extern fun ol_digs_exh(d: !Doc, re: int, k: int): int = "mac#anth_die_int"

fun ol_digs_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, re: int, k: int): int =
  if recfuel > 0 then (
    if ige(k, re) then 0
    else if ige(doc_byte(d, k), CHAR_ZERO) andalso ile(doc_byte(d, k), CHAR_NINE) then ol_digs_m(recfuel - 1, d, re, iadd(k, 1))
    else if ieq(doc_byte(d, k), CHAR_DOT) andalso ilt(iadd(k, 1), re) andalso ieq(doc_byte(d, iadd(k, 1)), CHAR_SPACE) then 1
    else 0
  ) else ol_digs_exh(d, re, k)

fun ol_digs(d: !Doc, re: int, k: int): int = ol_digs_m(airlock_nat(MAX_REC_FUEL), d, re, k)

fun is_ol(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
in
  ilt(j, re) andalso ige(doc_byte(d, j), CHAR_ZERO) andalso ile(doc_byte(d, j), CHAR_NINE) andalso ieq(ol_digs(d, re, j), 1)
end

fun is_quote(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
in
  if isub(j, i) > 3 then false else ilt(j, re) andalso ieq(doc_byte(d, j), CHAR_GT)
end

extern fun table_bar_exh(d: !Doc, e: int, k: int): int = "mac#anth_die_int"

fun table_bar_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, e: int, k: int): int =
  if recfuel > 0 then (
    if ige(k, e) then 0
    else if ieq(doc_byte(d, k), CHAR_PIPE) then 1
    else table_bar_m(recfuel - 1, d, e, iadd(k, 1))
  ) else table_bar_exh(d, e, k)

fun table_bar(d: !Doc, e: int, k: int): int = table_bar_m(airlock_nat(MAX_REC_FUEL), d, e, k)

fun is_table(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
in
  ilt(j, re) andalso ieq(doc_byte(d, j), CHAR_PIPE)
end

extern fun fndef_colon_exh(d: !Doc, e: int, k: int): int = "mac#anth_die_int"

fun fndef_colon_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, e: int, k: int): int =
  if recfuel > 0 then (
    if ige(iadd(k, 1), e) then 0
    else if ieq(doc_byte(d, k), CHAR_RBRACKET) andalso ieq(doc_byte(d, iadd(k, 1)), CHAR_COLON) then 1
    else fndef_colon_m(recfuel - 1, d, e, iadd(k, 1))
  ) else fndef_colon_exh(d, e, k)

fun fndef_colon(d: !Doc, e: int, k: int): int = fndef_colon_m(airlock_nat(MAX_REC_FUEL), d, e, k)

fun is_fndef(d: !Doc, i: int, re: int): bool = let
  val j = skip_sp(d, i, re)
in
  ieq(starts_at(d, j, re, "[^"), 1) andalso ieq(fndef_colon(d, at_end(d, j, re), j), 1)
end

fun ext_tail(d: !Doc, a: int, b: int, s: string): int = let
  val n = c_strlen(s)
  val p = isub(b, n)
in
  if ilt(p, a) then 0 else starts_at(d, p, b, s)
end

fun ext_image(d: !Doc, a: int, b: int): bool =
  ieq(ext_tail(d, a, b, ".png"), 1) orelse ieq(ext_tail(d, a, b, ".jpg"), 1) orelse ieq(ext_tail(d, a, b, ".jpeg"), 1) orelse ieq(ext_tail(d, a, b, ".bmp"), 1)

extern fun find_close_exh(d: !Doc, i: int, re: int, a: int, b: int): int = "mac#anth_die_int"

fun find_close_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, a: int, b: int): int =
  if recfuel > 0 then (
    if iadd(i, 1) >= re then ~1
    else if ieq(doc_byte(d, i), CHAR_LF) then ~1
    else if ieq(doc_byte(d, i), a) andalso ieq(doc_byte(d, iadd(i, 1)), b) then i
    else find_close_m(recfuel - 1, d, iadd(i, 1), re, a, b)
  ) else find_close_exh(d, i, re, a, b)

fun find_close(d: !Doc, i: int, re: int, a: int, b: int): int = find_close_m(airlock_nat(MAX_REC_FUEL), d, i, re, a, b)

extern fun find_one_exh(d: !Doc, i: int, re: int, a: int): int = "mac#anth_die_int"

fun find_one_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, a: int): int =
  if recfuel > 0 then (
    if ige(i, re) then ~1
    else if ieq(doc_byte(d, i), CHAR_LF) then ~1
    else if ieq(doc_byte(d, i), a) then i
    else find_one_m(recfuel - 1, d, iadd(i, 1), re, a)
  ) else find_one_exh(d, i, re, a)

fun find_one(d: !Doc, i: int, re: int, a: int): int = find_one_m(airlock_nat(MAX_REC_FUEL), d, i, re, a)

fun special_at(d: !Doc, i: int, re: int): int =
  if ige(i, re) then 0
  else if ieq(doc_byte(d, i), CHAR_DOLLAR) orelse ieq(doc_byte(d, i), CHAR_HASH) orelse ieq(doc_byte(d, i), CHAR_LBRACKET) orelse ieq(doc_byte(d, i), CHAR_STAR) orelse ieq(doc_byte(d, i), CHAR_TILDE) then 1
  else if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, i), CHAR_EXCL) andalso ieq(doc_byte(d, iadd(i, 1)), CHAR_LBRACKET) then 1
  else if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, i), CHAR_EQUAL) andalso ieq(doc_byte(d, iadd(i, 1)), CHAR_EQUAL) then 1
  else 0

extern fun text_nxt_exh(d: !Doc, re: int, k: int): int = "mac#anth_die_int"

fun text_nxt_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, re: int, k: int): int =
  if recfuel > 0 then (
    if ige(k, re) then k
    else if special_at(d, k, re) = 1 orelse ieq(doc_byte(d, k), CHAR_LF) then k
    else text_nxt_m(recfuel - 1, d, re, iadd(k, 1))
  ) else text_nxt_exh(d, re, k)

fun text_nxt(d: !Doc, re: int, k: int): int = text_nxt_m(airlock_nat(MAX_REC_FUEL), d, re, k)

extern fun tag_end_exh(d: !Doc, i: int, re: int): int = "mac#anth_die_int"

fun tag_end_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int): int =
  if recfuel > 0 then (
    if ige(i, re) then i
    else let
      val c = doc_byte(d, i)
    in
      if ieq(c, CHAR_SPACE) orelse ieq(c, CHAR_LF) orelse ieq(c, CHAR_TAB) then i
      else tag_end_m(recfuel - 1, d, iadd(i, 1), re)
    end
  ) else tag_end_exh(d, i, re)

fun tag_end(d: !Doc, i: int, re: int): int = tag_end_m(airlock_nat(MAX_REC_FUEL), d, i, re)

fun emit_double_inline(d: !Doc, i: int, re: int, depth: int, kind: NodeKind, ch: int): int = let
  val c = find_close(d, iadd(i, 2), re, ch, ch)
in
  if c < 0 then ~1
  else let
    val () = npush(d, kind, i, iadd(c, 2), depth, 0)
  in
    iadd(c, 2)
  end
end

fun emit_single_inline(d: !Doc, i: int, re: int, depth: int, kind: NodeKind, ch: int): int = let
  val c = find_one(d, iadd(i, 1), re, ch)
in
  if c < 0 then ~1
  else let
    val () = npush(d, kind, i, iadd(c, 1), depth, 0)
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
    val () = npush(d, kind, i, en, depth, 0)
  in
    en
  end
end

fun emit_image_inline(d: !Doc, i: int, re: int, depth: int): int = let
  val c = find_one(d, iadd(i, 4), re, CHAR_RPAREN)
in
  if c < 0 then ~1
  else let
    val () = npush(d, KImage, i, iadd(c, 1), depth, 1)
  in
    iadd(c, 1)
  end
end

fun emit_fn_inline(d: !Doc, i: int, re: int, depth: int): int = let
  val c = find_one(d, iadd(i, 2), re, CHAR_RBRACKET)
in
  if c < 0 then ~1
  else let
    val () = npush(d, KFn, i, iadd(c, 1), depth, 0)
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
      val () = npush(d, KLink, i, en, depth, c_bracket)
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
    val () = npush(d, KTag, i, e, depth, 0)
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

extern fun emit_inlines_exh(d: !Doc, i: int, re: int, depth: int): void = "mac#anth_die_void"

fun emit_inlines_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, depth: int): void =
  if recfuel > 0 then (
    if ige(i, re) then ()
    else if ieq(doc_byte(d, i), CHAR_LF) then emit_inlines_m(recfuel - 1, d, iadd(i, 1), re, depth)
    else let
      val en = emit_construct(d, i, re, depth)
    in
      if en < 0 then emit_text_or(recfuel - 1, d, i, re, depth)
      else emit_inlines_m(recfuel - 1, d, en, re, depth)
    end
  ) else emit_inlines_exh(d, i, re, depth)

and emit_text_or {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, depth: int): void =
  if recfuel > 0 then let
    val e = text_nxt(d, re, iadd(i, 1))
    val () = if igt(e, i) then npush(d, KText, i, e, depth, 0) else ()
  in
    emit_inlines_m(recfuel - 1, d, e, re, depth)
  end else ()

fun emit_inlines(d: !Doc, i: int, re: int, depth: int): void = emit_inlines_m(airlock_nat(MAX_REC_FUEL), d, i, re, depth)

datatype Gather = GatherAny | GatherQuote | GatherTable

fun gather_code(g: Gather): int = case+ g of
  | GatherAny() => 0
  | GatherQuote() => 1
  | GatherTable() => 2

fun is_gather(a: Gather, b: Gather): bool = ieq(gather_code(a), gather_code(b))

extern fun gather_exh(d: !Doc, i: int, re: int, pred: Gather): int = "mac#anth_die_int"

fun gather_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, pred: Gather): int =
  if recfuel > 0 then (
    if ige(i, re) then i
    else if blank_line(d, i, re) then i
    else if is_gather(pred, GatherQuote) andalso not(is_quote(d, i, re)) then i
    else if is_gather(pred, GatherTable) andalso not(is_table(d, i, re)) then i
    else if is_gather(pred, GatherAny) andalso (is_fence(d, i, re) orelse is_heading(d, i, re) orelse is_hr(d, i, re) orelse is_ul(d, i, re) orelse is_ol(d, i, re) orelse is_task(d, i, re) orelse is_quote(d, i, re) orelse is_table(d, i, re) orelse is_fndef(d, i, re)) then i
    else let
      val e = at_end(d, i, re)
      val n = if ilt(e, re) andalso ieq(doc_byte(d, e), CHAR_LF) then iadd(e, 1) else e
    in
      gather_m(recfuel - 1, d, n, re, pred)
    end
  ) else gather_exh(d, i, re, pred)

fun gather(d: !Doc, i: int, re: int, pred: Gather): int = gather_m(airlock_nat(MAX_REC_FUEL), d, i, re, pred)

extern fun fm_close_exh(d: !Doc, re: int, k: int): int = "mac#anth_die_int"

fun fm_close_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, re: int, k: int): int =
  if recfuel > 0 then (
    if ige(k, re) then re
    else if starts_at(d, skip_sp(d, k, re), re, "---") = 1 then let
      val e = at_end(d, k, re)
    in
      if ilt(e, re) then iadd(e, 1) else e
    end else fm_close_m(recfuel - 1, d, re, if ilt(at_end(d, k, re), re) then iadd(at_end(d, k, re), 1) else re)
  ) else fm_close_exh(d, re, k)

fun fm_close(d: !Doc, re: int, k: int): int = fm_close_m(airlock_nat(MAX_REC_FUEL), d, re, k)

extern fun fence_close_exh(d: !Doc, re: int, k: int): int = "mac#anth_die_int"

fun fence_close_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, re: int, k: int): int =
  if recfuel > 0 then (
    if ige(k, re) then re
    else if is_fence(d, k, re) then let
      val e = at_end(d, k, re)
    in
      if ilt(e, re) then iadd(e, 1) else e
    end else let
      val e = at_end(d, k, re)
    in
      fence_close_m(recfuel - 1, d, re, if ilt(e, re) then iadd(e, 1) else re)
    end
  ) else fence_close_exh(d, re, k)

fun fence_close(d: !Doc, re: int, k: int): int = fence_close_m(airlock_nat(MAX_REC_FUEL), d, re, k)

fun parse_frontmatter(d: !Doc, i: int, re: int, depth: int): int = let
  val e1 = at_end(d, i, re)
  val n1 = if ilt(e1, re) then iadd(e1, 1) else e1
  val en = fm_close(d, re, n1)
  val () = npush(d, KFm, i, en, depth, 0)
in
  en
end

fun parse_fence(d: !Doc, i: int, re: int, depth: int): int = let
  val e1 = at_end(d, i, re)
  val n1 = if ilt(e1, re) then iadd(e1, 1) else e1
  val en = fence_close(d, re, n1)
  val () = npush(d, KCode, i, en, depth, 0)
in
  en
end

fun parse_hr(d: !Doc, i: int, re: int, depth: int): int = let
  val e = at_end(d, i, re)
  val n = if ilt(e, re) then iadd(e, 1) else e
  val () = npush(d, KHr, i, n, depth, 0)
in
  n
end

fun parse_heading(d: !Doc, i: int, re: int, depth: int, hashes: int): int = let
  val e = at_end(d, i, re)
  val n = if ilt(e, re) then iadd(e, 1) else e
  val kind = heading_kind(hashes)
  val () = npush(d, kind, i, n, depth, hashes)
  val () = emit_inlines(d, i, e, iadd(depth, 1))
in
  n
end

fun parse_fndef(d: !Doc, i: int, re: int, depth: int): int = let
  val e = at_end(d, i, re)
  val n = if ilt(e, re) then iadd(e, 1) else e
  val () = npush(d, KFndef, i, n, depth, 0)
in
  n
end

fun parse_task(d: !Doc, i: int, re: int, depth: int, sp: int): int = let
  val e = at_end(d, i, re)
  val n = if ilt(e, re) then iadd(e, 1) else e
  val () = npush(d, KTask, i, n, iadd(depth, idiv(isub(sp, i), 2)), task_aux(d, i, re))
  val () = emit_inlines(d, i, e, iadd(depth, 1))
in
  n
end

fun parse_ul(d: !Doc, i: int, re: int, depth: int, sp: int): int = let
  val e = at_end(d, i, re)
  val n = if ilt(e, re) then iadd(e, 1) else e
  val () = npush(d, KLi, i, n, iadd(depth, idiv(isub(sp, i), 2)), 0)
  val () = npush(d, KUl, i, n, depth, 0)
  val () = emit_inlines(d, i, e, iadd(depth, 1))
in
  n
end

fun parse_ol(d: !Doc, i: int, re: int, depth: int, sp: int): int = let
  val e = at_end(d, i, re)
  val n = if ilt(e, re) then iadd(e, 1) else e
  val () = npush(d, KLi, i, n, iadd(depth, idiv(isub(sp, i), 2)), 1)
  val () = npush(d, KOl, i, n, depth, 0)
  val () = emit_inlines(d, i, e, iadd(depth, 1))
in
  n
end

fun parse_quote(d: !Doc, i: int, re: int, depth: int): int = let
  val en = gather(d, i, re, GatherQuote)
  val () = npush(d, KQuote, i, en, depth, 0)
  val () = emit_inlines(d, i, en, iadd(depth, 1))
in
  forward(d, i, re, en)
end

fun parse_table(d: !Doc, i: int, re: int, depth: int): int = let
  val en = gather(d, i, re, GatherTable)
  val () = npush(d, KTable, i, en, depth, 0)
  val () = npush(d, KTd, i, en, iadd(depth, 1), 0)
in
  forward(d, i, re, en)
end

fun parse_para(d: !Doc, i: int, re: int, depth: int): int = let
  val en = gather(d, i, re, GatherAny)
  val () = npush(d, KPara, i, en, depth, 0)
  val () = emit_inlines(d, i, en, iadd(depth, 1))
in
  forward(d, i, re, en)
end

fun parse_line_block(d: !Doc, i: int, re: int, depth: int): int = let
  val sp = skip_sp(d, i, re)
  val hashes = count_hash(d, sp, re, 0)
in
  if is_heading(d, i, re) then parse_heading(d, i, re, depth, hashes)
  else if is_fndef(d, i, re) then parse_fndef(d, i, re, depth)
  else if is_task(d, i, re) then parse_task(d, i, re, depth, sp)
  else if is_ul(d, i, re) then parse_ul(d, i, re, depth, sp)
  else if is_ol(d, i, re) then parse_ol(d, i, re, depth, sp)
  else if is_quote(d, i, re) then parse_quote(d, i, re, depth)
  else if is_table(d, i, re) then parse_table(d, i, re, depth)
  else parse_para(d, i, re, depth)
end

extern fun parse_blocks_exh(d: !Doc, i: int, re: int, depth: int): void = "mac#anth_die_void"

fun parse_blocks_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, re: int, depth: int): void =
  if recfuel > 0 then (
    if ige(i, re) then ()
    else if blank_line(d, i, re) then let
      val e = at_end(d, i, re)
    in
      parse_blocks_m(recfuel - 1, d, if ilt(e, re) then iadd(e, 1) else e, re, depth)
    end
    else if ieq(i, 0) andalso starts_at(d, skip_sp(d, i, re), re, "---") = 1 then parse_blocks_m(recfuel - 1, d, parse_frontmatter(d, i, re, depth), re, depth)
    else if is_fence(d, i, re) then parse_blocks_m(recfuel - 1, d, parse_fence(d, i, re, depth), re, depth)
    else if is_hr(d, i, re) then parse_blocks_m(recfuel - 1, d, parse_hr(d, i, re, depth), re, depth)
    else parse_blocks_m(recfuel - 1, d, parse_line_block(d, i, re, depth), re, depth)
  ) else parse_blocks_exh(d, i, re, depth)

fun parse_blocks(d: !Doc, i: int, re: int, depth: int): void = parse_blocks_m(airlock_nat(MAX_REC_FUEL), d, i, re, depth)

implement doc_parse_range(d, rs, re) =
  parse_blocks(d, rs, re, 0)
