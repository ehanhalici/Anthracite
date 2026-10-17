#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "os/fs.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/parser/block/blk_parse.sats"
staload "data_ast/folding/fold_region.sats"
staload "data_ast/syntax/ast_verify.sats"

fun verify(text: string, body_lines: int, end_line: int): int = let
  val before = mem_live()
  val d = doc_open()
  val () = doc_insert(d, c_str_ptr(text), c_strlen(text))
  val () = ast_parse_all(d)
  var regions: Buf = buf_make(1)
  val count = fold_region_build(d, regions)
  val boundary = if igt(body_lines, 0) then
    ieq(count, 1) andalso ieq(fold_region_owner(regions, 0), 0)
      andalso ieq(fold_region_end(regions, 0), end_line)
    else ieq(count, 0)
  val ok = boundary andalso is_kind(doc_node_kind(d, 0), KCallout) andalso ieq(ast_verify(d), 0)
  val () = buf_free(regions)
  val () = doc_free(d)
in if ok andalso ieq(before, mem_live()) then 0 else 1 end

implement main0() = let
  val no_body = verify("> [!NOTE] title\nnormal\n", 0, 1)
  val one = verify("> [!NOTE] title\n> one\nnormal\n", 1, 2)
  val many = verify("> [!NOTE] title\n> one\n> two\n> three\n\nnormal\n", 3, 4)
  val no_final_lf = verify("> [!NOTE] title\n> one\n> two", 2, 3)
  val empty_body = verify("> [!NOTE] title\n>\n> two\n>\nnormal\n", 3, 4)
  val indented = verify("  > [!NOTE] title\n  > one\n\t> two\nnormal\n", 2, 3)
  val errors = iadd(iadd(no_body, one), iadd(iadd(many, no_final_lf), iadd(empty_body, indented)))
  val () = println!("event=callout_contracts errors=", errors)
in if igt(errors, 0) then exit(1) else () end
