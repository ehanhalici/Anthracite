#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/parser/block/blk_parse.sats"
staload "data_ast/syntax/ast_dump.sats"
staload "data_ast/syntax/ast_verify.sats"

datatype EditCase = InsertText | InsertLine | DeleteByte | ReplaceByte
macdef FIXTURE_COUNT = 6

fun fixture(index: int): string =
  if ieq(index, 0) then "# Baslik\nTurkce İı\n"
  else if ieq(index, 1) then "- Ana\n  - Alt\n- Son\n"
  else if ieq(index, 2) then "# Heading **bold**\n\n[link](target)\n\n## Tail\nlast\n"
  else if ieq(index, 3) then "> [!NOTE] Title\n> one\n> two\n\n# Tail\n"
  else if ieq(index, 4) then "- first\n\n- second **strong**\n\ntext\n"
  else "# İ🙂\n\n```txt\nraw\n```\n\n# Son\n"

fun field_equal(a: !Doc, b: !Doc, index: int, field: int): bool = let
  val actual = doc_get(a,index,field)
  val expected = doc_get(b,index,field)
  val ok = ieq(actual,expected)
  val () = if ok then () else println!("event=field_mismatch node=",index," field=",field," actual=",actual," expected=",expected)
in ok end

fun node_equal(a: !Doc, b: !Doc, index: int): bool =
  field_equal(a,b,index,NF_KIND) andalso field_equal(a,b,index,NF_START)
  andalso field_equal(a,b,index,NF_END) andalso field_equal(a,b,index,NF_DEPTH)
  andalso field_equal(a,b,index,NF_PARENT)
  (* Roots are traversed by SUBEND; NEXT_SIB is optional for parent=-1.
     Child sibling links, in contrast, are part of the traversal contract. *)
  andalso (ilt(doc_node_parent(a,index),0) orelse field_equal(a,b,index,NF_NEXT_SIB))
  andalso field_equal(a,b,index,NF_FIRST_CHILD) andalso field_equal(a,b,index,NF_SUBEND)
  andalso field_equal(a,b,index,NF_CSTART) andalso field_equal(a,b,index,NF_CEND)
  andalso field_equal(a,b,index,NF_AUX)

fun nodes_equal{n:nat} .<n>. (left: int(n), a: !Doc, b: !Doc, index: int): bool =
  if left > 0 then node_equal(a,b,index) andalso nodes_equal(left-1,a,b,iadd(index,1)) else true

fun compare(d: !Doc, position: int, mode: int): int = let
  val length = doc_len(d)
  val source = buf_make(length)
  val copied = doc_slice_buf(d, 0, length, source, length)
  val reference = doc_open()
  val () = doc_insert_buf(reference, source, copied)
  val () = ast_parse_all(reference)
  val count = doc_nnodes(d)
  val ok = ieq(count,doc_nnodes(reference)) andalso nodes_equal(airlock_nat(count),d,reference,0)
    andalso ieq(ast_verify(d),0) andalso ieq(ast_verify(reference),0)
  val () = if ok then () else println!("event=incremental_mismatch position=",position," mode=",mode)
  val () = buf_free(source)
  val () = doc_free(reference)
in if ok then 0 else 1 end

fun insert_range(d: !Doc, text: string, start: int, length: int): void =
  if igt(length,0) then doc_insert(d,mem_ptr_at(c_str_ptr(text),c_strlen(text),start),length) else ()

fun split_case(text: string, split: int): int = let
  val d = doc_open()
  val () = insert_range(d,text,0,split)
  val () = insert_range(d,text,split,isub(c_strlen(text),split))
  val errors = compare(d,split,0)
  val () = doc_free(d)
in errors end

fun apply_edit(d: !Doc, position: int, mode: EditCase): void = let
  val () = doc_set_caret_move(d,position)
in case+ mode of
  | InsertText() => doc_insert(d,c_str_ptr("x"),1)
  | InsertLine() => doc_insert(d,c_str_ptr("\n"),1)
  | DeleteByte() => doc_delete_range(d,position,iadd(position,1))
  | ReplaceByte() => let
      val () = doc_set_caret_extend(d,iadd(position,1))
    in doc_insert(d,c_str_ptr("x"),1) end
end

fun edit_case(text: string, position: int, mode: EditCase, code: int): int = let
  val d = doc_open()
  val () = doc_insert(d,c_str_ptr(text),c_strlen(text))
  val () = apply_edit(d,position,mode)
  val errors = compare(d,position,code)
  val () = doc_free(d)
in errors end

fun positions{n:nat} .<n>. (left: int(n), text: string, position: int): int =
  if left > 0 then let
    val split = split_case(text,position)
    val inserted = iadd(edit_case(text,position,InsertText(),1),edit_case(text,position,InsertLine(),2))
    val removed = iadd(edit_case(text,position,DeleteByte(),3),edit_case(text,position,ReplaceByte(),4))
  in iadd(iadd(split,iadd(inserted,removed)),positions(left-1,text,iadd(position,1))) end else 0

fun fixtures{n:nat} .<n>. (left: int(n), index: int): int =
  if left > 0 then let
    val text = fixture(index)
    val errors = positions(airlock_nat(iadd(c_strlen(text),1)),text,0)
    val () = println!("event=incremental_fixture index=",index," errors=",errors)
  in iadd(errors,fixtures(left-1,iadd(index,1))) end else 0

implement main0() = let
  val before = mem_live()
  val errors = fixtures(FIXTURE_COUNT,0)
  val ok = ieq(errors,0) andalso ieq(before,mem_live())
  val () = println!("event=incremental_parser_contracts ok=",ok)
in if ok then () else exit(1) end
