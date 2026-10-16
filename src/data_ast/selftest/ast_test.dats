#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef AST_EXPECT_DST_INITIAL_BYTES = 256
macdef FUZZ_CHECK_EQ_BUFFER_INITIAL_BYTES = 256
macdef FUZZ_STEP_EDIT_BUFFER_INITIAL_BYTES = 4


staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/syntax/ast_dump.sats"
staload "data_ast/syntax/ast_verify.sats"
staload "data_ast/parser/block/blk_parse.sats"
staload "data_ast/selftest/ast_test.sats"

implement ast_expect(src, want) = let
  val d = doc_open()
  val () = doc_insert(d, c_str_ptr(src), c_strlen(src))
  val () = ast_parse_all(d)
  var dst = buf_make(AST_EXPECT_DST_INITIAL_BYTES)
  val () = ast_dump(d, dst)
  val got = buf_cstr(dst)
  val eq = (c_strcmp(got, want) = 0)
  val v = ast_verify(d)
  val ok = eq andalso (v = 0)
  val () = if not(ok) then let
    val () = println! ("ast_fail=golden got=[", got, "] want=[", want, "] verify=", v)
  in
  end else ()
  val () = buf_free(dst)
  val () = doc_free(d)
in
  ok
end

fun fuzz_rand(s: &int >> _): int = let
  val r = anth_iand(iadd(imul(s, 1103515245), 12345), SIGNED_INT_MAX_VALUE)
  val () = s := r
in
  r
end

fun put_str(d: !Doc, str: string): void =
  doc_insert(d, c_str_ptr(str), c_strlen(str))

fun fuzz_check_eq(d1: !Doc): bool = let
  var b1 = buf_make(FUZZ_CHECK_EQ_BUFFER_INITIAL_BYTES)
  val () = ast_dump(d1, b1)
  val s1 = buf_cstr(b1)
  val v1 = ast_verify(d1)
  val d2 = doc_open()
  var txt = buf_make(imax(16, doc_len(d1)))
  val () = doc_text(d1, txt)
  val () = doc_insert(d2, buf_ptr(txt), buf_len(txt))
  val () = ast_parse_all(d2)
  var b2 = buf_make(FUZZ_CHECK_EQ_BUFFER_INITIAL_BYTES)
  val () = ast_dump(d2, b2)
  val s2 = buf_cstr(b2)
  val eq = (c_strcmp(s1, s2) = 0)
  val () = buf_free(b1)
  val () = buf_free(b2)
  val () = buf_free(txt)
  val () = doc_free(d2)
in
  eq andalso (v1 = 0)
end

fun fuzz_insert_tok(d: !Doc, k: int): void =
  if ieq(k, 0) then put_str(d, "```\nx\n```\n")
  else if ieq(k, 1) then put_str(d, "$$x$$\n")
  else if ieq(k, 2) then put_str(d, "---\n")
  else if ieq(k, 3) then put_str(d, "> q\n")
  else if ieq(k, 4) then put_str(d, "- [ ] t\n")
  else if ieq(k, 5) then put_str(d, "|a|b|\n|-|-|\n|1|2|\n")
  else if ieq(k, 6) then put_str(d, "[[w]] ")
  else put_str(d, "**b** ")

fun fuzz_step_edit(d: !Doc, s: &int >> _): void = let
  val opk = anth_iand(fuzz_rand(s), 7)
  val len = doc_len(d)
in
  if ieq(opk, 0) then let
    val ch = iadd(97, imod(fuzz_rand(s), 26))
    var b = buf_make(FUZZ_STEP_EDIT_BUFFER_INITIAL_BYTES)
    val () = buf_set(b, 0, ch)
    val () = doc_insert_buf(d, b, 1)
    val () = buf_free(b)
  in end
  else if ieq(opk, 1) then fuzz_insert_tok(d, imod(fuzz_rand(s), 8))
  else if ieq(opk, 2) then (if len > 0 then doc_set_caret_move(d, imod(fuzz_rand(s), iadd(len, 1))) else ())
  else if ieq(opk, 3) then doc_backspace(d)
  else if ieq(opk, 4) then put_str(d, "\n")
  else if ieq(opk, 5) then doc_delete(d)
  else if ieq(opk, 6) then put_str(d, "abc ")
  else (if anth_iand(fuzz_rand(s), 1) = 0 then doc_undo(d) else doc_redo(d))
end

extern fun fuzz_loop_fuel_exhausted(d: !Doc, s: &int >> _, step: int, max_steps: int): bool = "mac#anth_die_int"

fun fuzz_loop_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, s: &int >> _, step: int, max_steps: int
): bool =
  if recfuel > 0 then (
    if ige(step, max_steps) then true
    else let
      val () = fuzz_step_edit(d, s)
      val ok = fuzz_check_eq(d)
    in
      if not(ok) then let
        val () = println! ("ast_fail=fuzz seed=", s, " step=", step)
      in
        false
      end
      else fuzz_loop_with_fuel(recfuel - 1, d, s, iadd(step, 1), max_steps)
    end
  ) else fuzz_loop_fuel_exhausted(d, s, step, max_steps)

implement ast_fuzz(seed, steps) = let
  var s: int = (if ieq(seed, 0) then 12345 else seed)
  val d = doc_open()
  val ok = fuzz_loop_with_fuel(airlock_nat(MAX_REC_FUEL), d, s, 0, steps)
  val () = doc_free(d)
in
  ok
end

fun test_fuzz_seeds_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), cur_seed: int, count: int, steps: int
): bool =
  if recfuel > 0 then (
    if ige(count, 20) then true
    else let
      val ok = ast_fuzz(cur_seed, steps)
    in
      if not(ok) then false
      else test_fuzz_seeds_with_fuel(recfuel - 1, iadd(cur_seed, 777), iadd(count, 1), steps)
    end
  ) else true

fun test_atx1(): bool = ast_expect("# Hi", "H1[0,4](Mark[0,2] Text[2,4])")
fun test_atx2(): bool = ast_expect("## Title", "H2[0,8](Mark[0,3] Text[3,8])")
fun test_hr1(): bool = ast_expect("---", "Hr[0,3]")
fun test_para1(): bool = ast_expect("hello", "Para[0,5](Text[0,5])")
fun test_gold_code(): bool = ast_expect("```js\nx\n```", "Code[0,11](Mark[0,3] Info[3,5] Raw[6,7] Mark[8,11])")
fun test_gold_quote(): bool = ast_expect("> a", "Quote[0,3](Para[2,3](Text[2,3]))")
fun test_gold_table(): bool = ast_expect("|a|b|\n|-|-|\n|1|2|", "Table[0,17](Row[0,5](Mark[0,1] Cell[1,2](Text[1,2]) Mark[2,3] Cell[3,4](Text[3,4]) Mark[4,5]) Delim[6,11] Row[12,17](Mark[12,13] Cell[13,14](Text[13,14]) Mark[14,15] Cell[15,16](Text[15,16]) Mark[16,17]))")
fun test_gold_callout(): bool = ast_expect("> [!note]- T\n> body", "Callout[0,19](CalloutHead[2,12](Mark[2,4] Info[4,8] Mark[8,11] Text[11,12]) Para[15,19](Text[15,19]))")
fun test_gold_task(): bool = ast_expect("- [ ] x", "Ul[0,7](Li[0,7](Mark[0,2] Task[2,6] Para[6,7](Text[6,7])))")

fun test_gold_bold(): bool = ast_expect("**a**", "Para[0,5](Bold[0,5](Mark[0,2] Text[2,3] Mark[3,5]))")
fun test_gold_wiki(): bool = ast_expect("[[a|b]]", "Para[0,7](Wiki[0,7](Mark[0,2] WikiTarget[2,3] Mark[3,4] WikiAlias[4,5] Mark[5,7]))")
fun test_gold_codespan(): bool = ast_expect("`x`", "Para[0,3](CodeSpan[0,3](Mark[0,1] Raw[1,2] Mark[2,3]))")
fun test_gold_link(): bool = ast_expect("[x](y)", "Para[0,6](Link[0,6](Mark[0,1] Text[1,2] Mark[2,4] LinkDest[4,5] Mark[5,6]))")

fun test_crlf(): bool = let
  val d1 = doc_open()
  val () = doc_insert(d1, c_str_ptr("# Hi\r\nHello\r\n"), c_strlen("# Hi\r\nHello\r\n"))
  val () = ast_parse_all(d1)
  val v1 = ast_verify(d1)
  val ok = (v1 = 0)
  val () = doc_free(d1)
in
  ok
end

fun tests_basic(): bool =
  test_atx1() andalso test_atx2() andalso test_hr1() andalso test_para1() andalso test_crlf()

fun tests_gold(): bool =
  test_gold_code() andalso test_gold_quote() andalso test_gold_table() andalso
  test_gold_callout() andalso test_gold_task() andalso test_gold_bold() andalso
  test_gold_wiki() andalso test_gold_codespan() andalso test_gold_link()

implement ast_selftest() = let
  val b_ok = tests_basic()
  val g_ok = tests_gold()
  val f_ok = test_fuzz_seeds_with_fuel(airlock_nat(MAX_REC_FUEL), 101, 0, 50)
  val ok = b_ok andalso g_ok andalso f_ok
in
  if ok then 1 else 0
end
