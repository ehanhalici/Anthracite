#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "os/fs.sats"
staload "data_ast/doc.sats"
staload "data_ast/doc_parse.sats"

fun npush(d: !Doc, kind: int, st: int, en: int, depth: int, aux: int): void =
  doc_push_node(d, kind, st, en, depth, aux)

fun at_end(d: !Doc, i: int, re: int): int = if ige(i, re) then re else if ieq(doc_byte(d, i), 10) then i else at_end(d, iadd(i, 1), re)

fun skip_sp(d: !Doc, i: int, re: int): int =
  if ige(i, re) then i
  else if ieq(doc_byte(d, i), 32) orelse ieq(doc_byte(d, i), 9) then skip_sp(d, iadd(i, 1), re)
  else i

fun starts_go(d: !Doc, i: int, re: int, s: string, k: int, n: int): int =
  if ige(k, n) then 1
  else if ige(iadd(i, k), re) then 0
  else if ine(doc_byte(d, iadd(i, k)), c_str_byte(s, k)) then 0
  else starts_go(d, i, re, s, iadd(k, 1), n)

fun starts_at(d: !Doc, i: int, re: int, s: string): int =
  starts_go(d, i, re, s, 0, c_strlen(s))

fun blank_line(d: !Doc, i: int, re: int): int = let
  val j = skip_sp(d, i, re)
in
  if ige(j, re) orelse ieq(doc_byte(d, j), 10) then 1 else 0
end

fun count_hash(d: !Doc, i: int, re: int, n: int): int =
  if n >= 6 orelse ige(i, re) orelse ine(doc_byte(d, i), 35) then n
  else count_hash(d, iadd(i, 1), re, iadd(n, 1))

fun is_heading(d: !Doc, i: int, re: int): int = let
  val sp = skip_sp(d, i, re)
  val hashes = count_hash(d, sp, re, 0)
in
  if igt(hashes, 0) andalso ilt(iadd(sp, hashes), re) andalso ieq(doc_byte(d, iadd(sp, hashes)), 32) then 1 else 0
end

fun forward(d: !Doc, i: int, re: int, en: int): int =
  if igt(en, i) then en
  else let
    val e = at_end(d, i, re)
  in
    if ilt(e, re) then iadd(e, 1) else re
  end

fun hr_go(d: !Doc, re: int, c: int, k: int, n: int): int =
  if ige(k, re) orelse ieq(doc_byte(d, k), 10) then iif(igt(n, 2), 1, 0)
  else if ieq(doc_byte(d, k), c) orelse ieq(doc_byte(d, k), 32) then hr_go(d, re, c, iadd(k, 1), iif(ieq(doc_byte(d, k), c), iadd(n, 1), n))
  else 0

fun is_hr(d: !Doc, i: int, re: int): int = let
  val j = skip_sp(d, i, re)
  val c = if ilt(j, re) then doc_byte(d, j) else 0
in
  if ieq(c, 45) orelse ieq(c, 42) orelse ieq(c, 95) then hr_go(d, re, c, j, 0) else 0
end

fun is_fence(d: !Doc, i: int, re: int): int = let
  val j = skip_sp(d, i, re)
in
  if isub(j, i) > 3 then 0 else starts_at(d, j, re, "```")
end

fun is_task(d: !Doc, i: int, re: int): int = let
  val j = skip_sp(d, i, re)
  val c = if ilt(j, re) then doc_byte(d, j) else 0
  val k = skip_sp(d, iadd(j, 1), re)
in
  if (ieq(c, 45) orelse ieq(c, 42) orelse ieq(c, 43)) andalso ilt(iadd(k, 2), re) andalso ieq(doc_byte(d, k), 91) andalso ieq(doc_byte(d, iadd(k, 2)), 93) then 1 else 0
end

fun task_aux(d: !Doc, i: int, re: int): int = let
  val j = skip_sp(d, i, re)
  val k = skip_sp(d, iadd(j, 1), re)
  val c = doc_byte(d, iadd(k, 1))
in
  if ieq(c, 120) orelse ieq(c, 88) then 1 else if ieq(c, 47) then 2 else 0
end

fun is_ul(d: !Doc, i: int, re: int): int = let
  val j = skip_sp(d, i, re)
  val c = if ilt(j, re) then doc_byte(d, j) else 0
  val n = if ilt(iadd(j, 1), re) then doc_byte(d, iadd(j, 1)) else 0
in
  if is_task(d, i, re) = 1 then 0
  else if (ieq(c, 45) orelse ieq(c, 42) orelse ieq(c, 43)) andalso (ieq(n, 32) orelse ieq(n, 9)) then 1 else 0
end

fun ol_digs(d: !Doc, re: int, k: int): int =
  if ige(k, re) then 0
  else if ige(doc_byte(d, k), 48) andalso ile(doc_byte(d, k), 57) then ol_digs(d, re, iadd(k, 1))
  else if ieq(doc_byte(d, k), 46) andalso ilt(iadd(k, 1), re) andalso ieq(doc_byte(d, iadd(k, 1)), 32) then 1
  else 0

fun is_ol(d: !Doc, i: int, re: int): int = let
  val j = skip_sp(d, i, re)
in
  if ilt(j, re) andalso ige(doc_byte(d, j), 48) andalso ile(doc_byte(d, j), 57) then ol_digs(d, re, j) else 0
end

fun is_quote(d: !Doc, i: int, re: int): int = let
  val j = skip_sp(d, i, re)
in
  if isub(j, i) > 3 then 0 else if ilt(j, re) andalso ieq(doc_byte(d, j), 62) then 1 else 0
end

fun table_bar(d: !Doc, e: int, k: int): int =
  if ige(k, e) then 0
  else if ieq(doc_byte(d, k), 124) then 1
  else table_bar(d, e, iadd(k, 1))

fun is_table(d: !Doc, i: int, re: int): int = let
  val j = skip_sp(d, i, re)
in
  if ilt(j, re) andalso ieq(doc_byte(d, j), 124) then 1 else 0
end

fun fndef_colon(d: !Doc, e: int, k: int): int =
  if ige(iadd(k, 1), e) then 0
  else if ieq(doc_byte(d, k), 93) andalso ieq(doc_byte(d, iadd(k, 1)), 58) then 1
  else fndef_colon(d, e, iadd(k, 1))

fun is_fndef(d: !Doc, i: int, re: int): int = let
  val j = skip_sp(d, i, re)
in
  if starts_at(d, j, re, "[^") = 0 then 0
  else fndef_colon(d, at_end(d, j, re), j)
end

fun ext_tail(d: !Doc, a: int, b: int, s: string): int = let
  val n = c_strlen(s)
  val p = isub(b, n)
in
  if ilt(p, a) then 0 else starts_at(d, p, b, s)
end

fun ext_image(d: !Doc, a: int, b: int): int =
  if ext_tail(d, a, b, ".png") = 1 orelse ext_tail(d, a, b, ".jpg") = 1 orelse ext_tail(d, a, b, ".jpeg") = 1 orelse ext_tail(d, a, b, ".bmp") = 1 then 1 else 0

fun find_close(d: !Doc, i: int, re: int, a: int, b: int): int =
  if iadd(i, 1) >= re then ~1
  else if ieq(doc_byte(d, i), 10) then ~1
  else if ieq(doc_byte(d, i), a) andalso ieq(doc_byte(d, iadd(i, 1)), b) then i
  else find_close(d, iadd(i, 1), re, a, b)

fun find_one(d: !Doc, i: int, re: int, a: int): int =
  if ige(i, re) then ~1
  else if ieq(doc_byte(d, i), 10) then ~1
  else if ieq(doc_byte(d, i), a) then i
  else find_one(d, iadd(i, 1), re, a)

fun special_at(d: !Doc, i: int, re: int): int =
  if ige(i, re) then 0
  else if ieq(doc_byte(d, i), 36) orelse ieq(doc_byte(d, i), 35) orelse ieq(doc_byte(d, i), 91) orelse ieq(doc_byte(d, i), 42) orelse ieq(doc_byte(d, i), 126) then 1
  else if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, i), 33) andalso ieq(doc_byte(d, iadd(i, 1)), 91) then 1
  else if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, i), 61) andalso ieq(doc_byte(d, iadd(i, 1)), 61) then 1
  else 0

fun text_nxt(d: !Doc, re: int, k: int): int =
  if ige(k, re) then k
  else if special_at(d, k, re) = 1 orelse ieq(doc_byte(d, k), 10) then k
  else text_nxt(d, re, iadd(k, 1))

fun emit_inlines(d: !Doc, i: int, re: int, depth: int): void =
  if ige(i, re) then ()
  else if ieq(doc_byte(d, i), 10) then emit_inlines(d, iadd(i, 1), re, depth)
  else if ilt(iadd(i, 2), re) andalso ieq(doc_byte(d, i), 33) andalso ieq(doc_byte(d, iadd(i, 1)), 91) andalso ieq(doc_byte(d, iadd(i, 2)), 91) then let
    val c = find_close(d, iadd(i, 2), re, 93, 93)
  in
    if c < 0 then emit_text_or(d, i, re, depth)
    else let
      val en = iadd(c, 2)
      val kind = if ext_image(d, iadd(i, 3), c) = 1 then NK_IMAGE else NK_EMBED
      val () = npush(d, kind, i, en, depth, 0)
    in
      emit_inlines(d, en, re, depth)
    end
  end else if ieq(doc_byte(d, i), 91) then (
    if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, iadd(i, 1)), 91) then let
      val c = find_close(d, iadd(i, 2), re, 93, 93)
    in
      if c < 0 then emit_text_or(d, i, re, depth)
      else let
        val () = npush(d, NK_WIKI, i, iadd(c, 2), depth, 0)
      in
        emit_inlines(d, iadd(c, 2), re, depth)
      end
    end else if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, iadd(i, 1)), 94) then let
      val c = find_one(d, iadd(i, 2), re, 93)
    in
      if c < 0 then emit_text_or(d, i, re, depth)
      else let
        val () = npush(d, NK_FN, i, iadd(c, 1), depth, 0)
      in
        emit_inlines(d, iadd(c, 1), re, depth)
      end
    end else let
      val c_bracket = find_one(d, iadd(i, 1), re, 93)
    in
      if c_bracket < 0 orelse ige(iadd(c_bracket, 2), re) orelse ine(doc_byte(d, iadd(c_bracket, 1)), 40) then
        emit_text_or(d, i, re, depth)
      else let
        val c_paren = find_one(d, iadd(c_bracket, 2), re, 41)
      in
        if c_paren < 0 then emit_text_or(d, i, re, depth)
        else let
          val en = iadd(c_paren, 1)
          val () = npush(d, NK_LINK, i, en, depth, c_bracket)
        in
          emit_inlines(d, en, re, depth)
        end
      end
    end
  ) else if ilt(iadd(i, 3), re) andalso ieq(doc_byte(d, i), 33) andalso ieq(doc_byte(d, iadd(i, 1)), 91) andalso ieq(doc_byte(d, iadd(i, 2)), 93) andalso ieq(doc_byte(d, iadd(i, 3)), 40) then let
    val c = find_one(d, iadd(i, 4), re, 41)
  in
    if c < 0 then emit_text_or(d, i, re, depth)
    else let
      val () = npush(d, NK_IMAGE, i, iadd(c, 1), depth, 1)
    in
      emit_inlines(d, iadd(c, 1), re, depth)
    end
  end else if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, i), 42) andalso ieq(doc_byte(d, iadd(i, 1)), 42) then let
    val c = find_close(d, iadd(i, 2), re, 42, 42)
  in
    if c < 0 then emit_text_or(d, i, re, depth)
    else let
      val () = npush(d, NK_BOLD, i, iadd(c, 2), depth, 0)
    in
      emit_inlines(d, iadd(c, 2), re, depth)
    end
  end else if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, i), 126) andalso ieq(doc_byte(d, iadd(i, 1)), 126) then let
    val c = find_close(d, iadd(i, 2), re, 126, 126)
  in
    if c < 0 then emit_text_or(d, i, re, depth)
    else let
      val () = npush(d, NK_STRIKE, i, iadd(c, 2), depth, 0)
    in
      emit_inlines(d, iadd(c, 2), re, depth)
    end
  end else if ieq(doc_byte(d, i), 42) then let
    val c = find_one(d, iadd(i, 1), re, 42)
  in
    if c < 0 then emit_text_or(d, i, re, depth)
    else let
      val () = npush(d, NK_ITALIC, i, iadd(c, 1), depth, 0)
    in
      emit_inlines(d, iadd(c, 1), re, depth)
    end
  end else if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, i), 61) andalso ieq(doc_byte(d, iadd(i, 1)), 61) then let
    val c = find_close(d, iadd(i, 2), re, 61, 61)
  in
    if c < 0 then emit_text_or(d, i, re, depth)
    else let
      val () = npush(d, NK_HIGH, i, iadd(c, 2), depth, 0)
    in
      emit_inlines(d, iadd(c, 2), re, depth)
    end
  end else if ilt(iadd(i, 1), re) andalso ieq(doc_byte(d, i), 36) andalso ieq(doc_byte(d, iadd(i, 1)), 36) then let
    val c = find_close(d, iadd(i, 2), re, 36, 36)
  in
    if c < 0 then emit_text_or(d, i, re, depth)
    else let
      val () = npush(d, NK_MATHB, i, iadd(c, 2), depth, 0)
    in
      emit_inlines(d, iadd(c, 2), re, depth)
    end
  end else if ieq(doc_byte(d, i), 36) then let
    val c = find_one(d, iadd(i, 1), re, 36)
  in
    if c < 0 then emit_text_or(d, i, re, depth)
    else let
      val () = npush(d, NK_MATH, i, iadd(c, 1), depth, 0)
    in
      emit_inlines(d, iadd(c, 1), re, depth)
    end
  end else if ieq(doc_byte(d, i), 35) then let
    val e = tag_end(d, iadd(i, 1), re)
  in
    if ile(e, iadd(i, 1)) then emit_text_or(d, i, re, depth)
    else let
      val () = npush(d, NK_TAG, i, e, depth, 0)
    in
      emit_inlines(d, e, re, depth)
    end
  end else emit_text_or(d, i, re, depth)

and tag_end(d: !Doc, i: int, re: int): int =
  if ige(i, re) then i
  else let
    val c = doc_byte(d, i)
  in
    if ieq(c, 32) orelse ieq(c, 10) orelse ieq(c, 9) then i
    else tag_end(d, iadd(i, 1), re)
  end

and emit_text_or(d: !Doc, i: int, re: int, depth: int): void = let
  val e = text_nxt(d, re, iadd(i, 1))
  val () = if igt(e, i) then npush(d, NK_TEXT, i, e, depth, 0) else ()
in
  emit_inlines(d, e, re, depth)
end

fun gather(d: !Doc, i: int, re: int, pred: int): int =
  if ige(i, re) then i
  else if blank_line(d, i, re) = 1 then i
  else if pred = 1 andalso is_quote(d, i, re) = 0 then i
  else if pred = 2 andalso is_table(d, i, re) = 0 then i
  else if pred = 0 andalso (is_fence(d, i, re) = 1 orelse is_heading(d, i, re) = 1 orelse is_hr(d, i, re) = 1 orelse is_ul(d, i, re) = 1 orelse is_ol(d, i, re) = 1 orelse is_task(d, i, re) = 1 orelse is_quote(d, i, re) = 1 orelse is_table(d, i, re) = 1 orelse is_fndef(d, i, re) = 1) then i
  else let
    val e = at_end(d, i, re)
    val n = if ilt(e, re) andalso ieq(doc_byte(d, e), 10) then iadd(e, 1) else e
  in
    gather(d, n, re, pred)
  end

fun fm_close(d: !Doc, re: int, k: int): int =
  if ige(k, re) then re
  else if starts_at(d, skip_sp(d, k, re), re, "---") = 1 then let
    val e = at_end(d, k, re)
  in
    if ilt(e, re) then iadd(e, 1) else e
  end else fm_close(d, re, if ilt(at_end(d, k, re), re) then iadd(at_end(d, k, re), 1) else re)

fun fence_close(d: !Doc, re: int, k: int): int =
  if ige(k, re) then re
  else if is_fence(d, k, re) = 1 then let
    val e = at_end(d, k, re)
  in
    if ilt(e, re) then iadd(e, 1) else e
  end else let
    val e = at_end(d, k, re)
  in
    fence_close(d, re, if ilt(e, re) then iadd(e, 1) else re)
  end

fun parse_blocks(d: !Doc, i: int, re: int, depth: int): void =
  if ige(i, re) then ()
  else if blank_line(d, i, re) = 1 then let
    val e = at_end(d, i, re)
  in
    parse_blocks(d, if ilt(e, re) then iadd(e, 1) else e, re, depth)
  end else if ieq(i, 0) andalso starts_at(d, skip_sp(d, i, re), re, "---") = 1 then let
    val e1 = at_end(d, i, re)
    val n1 = if ilt(e1, re) then iadd(e1, 1) else e1
  in
    let
      val en = fm_close(d, re, n1)
      val () = npush(d, NK_FM, i, en, depth, 0)
    in
      parse_blocks(d, en, re, depth)
    end
  end else if is_fence(d, i, re) = 1 then let
    val e1 = at_end(d, i, re)
    val n1 = if ilt(e1, re) then iadd(e1, 1) else e1
    val en = fence_close(d, re, n1)
    val () = npush(d, NK_CODE, i, en, depth, 0)
  in
    parse_blocks(d, en, re, depth)
  end else if is_hr(d, i, re) = 1 then let
    val e = at_end(d, i, re)
    val n = if ilt(e, re) then iadd(e, 1) else e
    val () = npush(d, NK_HR, i, n, depth, 0)
  in
    parse_blocks(d, n, re, depth)
  end else let
    val sp = skip_sp(d, i, re)
    val hashes = count_hash(d, sp, re, 0)
  in
    if is_heading(d, i, re) = 1 then let
      val e = at_end(d, i, re)
      val n = if ilt(e, re) then iadd(e, 1) else e
      val kind = iadd(NK_H1, isub(hashes, 1))
      val () = npush(d, kind, i, n, depth, hashes)
      val () = emit_inlines(d, i, e, iadd(depth, 1))
    in
      parse_blocks(d, n, re, depth)
    end else if is_fndef(d, i, re) = 1 then let
      val e = at_end(d, i, re)
      val n = if ilt(e, re) then iadd(e, 1) else e
      val () = npush(d, NK_FNDEF, i, n, depth, 0)
    in
      parse_blocks(d, n, re, depth)
    end else if is_task(d, i, re) = 1 then let
      val e = at_end(d, i, re)
      val n = if ilt(e, re) then iadd(e, 1) else e
      val () = npush(d, NK_TASK, i, n, iadd(depth, idiv(isub(sp, i), 2)), task_aux(d, i, re))
      val () = emit_inlines(d, i, e, iadd(depth, 1))
    in
      parse_blocks(d, n, re, depth)
    end else if is_ul(d, i, re) = 1 then let
      val e = at_end(d, i, re)
      val n = if ilt(e, re) then iadd(e, 1) else e
      val () = npush(d, NK_LI, i, n, iadd(depth, idiv(isub(sp, i), 2)), 0)
      val () = npush(d, NK_UL, i, n, depth, 0)
      val () = emit_inlines(d, i, e, iadd(depth, 1))
    in
      parse_blocks(d, n, re, depth)
    end else if is_ol(d, i, re) = 1 then let
      val e = at_end(d, i, re)
      val n = if ilt(e, re) then iadd(e, 1) else e
      val () = npush(d, NK_LI, i, n, iadd(depth, idiv(isub(sp, i), 2)), 1)
      val () = npush(d, NK_OL, i, n, depth, 0)
    in
      parse_blocks(d, n, re, depth)
    end else if is_quote(d, i, re) = 1 then let
      val en = gather(d, i, re, 1)
      val () = npush(d, NK_QUOTE, i, en, depth, 0)
      val () = emit_inlines(d, i, en, iadd(depth, 1))
    in
      parse_blocks(d, forward(d, i, re, en), re, depth)
    end else if is_table(d, i, re) = 1 then let
      val en = gather(d, i, re, 2)
      val () = npush(d, NK_TABLE, i, en, depth, 0)
      val () = npush(d, NK_TD, i, en, iadd(depth, 1), 0)
    in
      parse_blocks(d, forward(d, i, re, en), re, depth)
    end else let
      val en = gather(d, i, re, 0)
      val () = npush(d, NK_PARA, i, en, depth, 0)
      val () = emit_inlines(d, i, en, iadd(depth, 1))
    in
      parse_blocks(d, forward(d, i, re, en), re, depth)
    end
  end

implement doc_parse_range(d, rs, re) =
  parse_blocks(d, rs, re, 0)
