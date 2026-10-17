#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "os/fs.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/source/text_source.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/bidi/bidi_bracket_data.sats"
staload "data_text/bidi/bidi_document.sats"
staload "data_text/bidi/bidi_line.sats"
staload "data_text/bidi/bidi_runs.sats"
staload "data_text/bidi/bidi_sequence.sats"
staload "data_text/bidi/bidi_status.sats"
staload "text/bidi/bidi_fixture.sats"

fun fixture(value: string): ScalarText = let
  val size = c_strlen(value)
  var source = buf_make(iadd(size,1))
  val () = buf_append(source,c_str_ptr(value),size)
  val text = bidi_fixture_text(source,0,size)
  val () = buf_free(source)
in text end

fun paragraph_checks(document: !BidiDocument): int = let
  val valid = ieq(bidi_document_count(document),12)
    andalso ieq(bidi_document_paragraph_end(document,0),4)
    andalso ieq(bidi_document_paragraph_end(document,4),11)
    andalso ieq(bidi_document_paragraph_end(document,11),12)
    andalso ieq(bidi_document_base(document,0),1)
    andalso ieq(bidi_document_base(document,4),0)
    andalso ieq(bidi_document_base(document,11),1)
in if valid then 0 else 1 end

fun check_paragraphs(map: !PropertyMap(2), brackets: !BidiBrackets): int = let
  val text = fixture("05D0 0020 000D 000A 0061 0020 2067 05D1 2069 0020 000A 05D2")
  val document = bidi_document_make(map,text,brackets,AutoLtr())
  val errors = paragraph_checks(document)
  val () = bidi_document_dispose(document)
  val () = scalar_dispose(text)
in errors end

fun check_wrap(map: !PropertyMap(2), brackets: !BidiBrackets): int = let
  val text = fixture("0061 0020 05D0 0020 05D1 0020")
  val document = bidi_document_make(map,text,brackets,AutoLtr())
  val order = bidi_document_line(document,map,text,0,4)
  val valid = ieq(bidi_order_count(order),4) andalso ieq(bidi_order_index(order,0),0)
    andalso ieq(bidi_order_index(order,1),1) andalso ieq(bidi_order_index(order,2),2)
    andalso ieq(bidi_order_index(order,3),3) andalso ieq(bidi_document_level(document,3),1)
  val () = bidi_order_dispose(order)
  val () = bidi_document_dispose(document)
  val () = scalar_dispose(text)
in if valid then 0 else 1 end

fun check_offset(map: !PropertyMap(2), brackets: !BidiBrackets): int = let
  val text = fixture("000A 0061 0028 0062 0029 0331")
  val document = bidi_document_make(map,text,brackets,ForceRtl())
  val order = bidi_document_line(document,map,text,1,6)
  val valid = ieq(bidi_order_count(order),5) andalso ieq(bidi_order_index(order,0),1)
    andalso ieq(bidi_order_index(order,4),5) andalso ieq(bidi_document_level(document,2),2)
    andalso ieq(bidi_document_level(document,4),2) andalso ieq(bidi_document_level(document,5),2)
  val () = bidi_order_dispose(order)
  val () = bidi_document_dispose(document)
  val () = scalar_dispose(text)
in if valid then 0 else 1 end

fun check_empty(map: !PropertyMap(2), brackets: !BidiBrackets): int = let
  val text = fixture("")
  val document = bidi_document_make(map,text,brackets,AutoRtl())
  val order = bidi_document_line(document,map,text,0,0)
  val valid = ieq(bidi_document_count(document),0) andalso ieq(bidi_order_count(order),0)
  val () = bidi_order_dispose(order)
  val () = bidi_document_dispose(document)
  val () = scalar_dispose(text)
in if valid then 0 else 1 end

fun check_run_storage(map: !PropertyMap(2)): int = let
  val text = fixture("0061 202B 05D0 202C 0062")
  val work = bidi_make(map,text)
  val () = bidi_match_isolates(work)
  val () = bidi_explicit_levels(work,0)
  val runs = bidi_runs_make(bidi_count(work))
  val counts = bidi_runs_build(runs,work)
  val () = bidi_runs_link(runs,work,counts,0)
  val seq = bidi_runs_sequence(runs,work,0,bidi_count(work))
  val+ BidiSequence(indices,count,sos,eos,level) = seq
  val valid = ieq(count,1) andalso ieq(buf_cap(indices),4)
  val () = bidi_sequence_dispose(seq)
  val () = bidi_runs_dispose(runs)
  val () = bidi_dispose(work)
  val () = scalar_dispose(text)
in if valid then 0 else 1 end

fun check_all(map: !PropertyMap(2), brackets: !BidiBrackets): int = let
  val before = mem_live()
  val errors = check_paragraphs(map,brackets) + check_wrap(map,brackets)
    + check_offset(map,brackets) + check_empty(map,brackets) + check_run_storage(map)
  val () = println!("event=bidi_document_conformance errors=",errors)
in iadd(errors,if ieq(before,mem_live()) then 0 else 1) end

fun with_brackets(map: !PropertyMap(2)): int = case+ bidi_brackets_load(c_argv(2)) of
  | ~BracketsRejected(error) => 1
  | ~BracketsLoaded(brackets) => let
      val errors = check_all(map,brackets)
      val () = bidi_brackets_dispose(brackets)
    in errors end

fun run(): int = case+ property_load(c_argv(1),BidiProperty()) of
  | ~PropertyRejected(error) => 1
  | ~PropertyLoaded(map) => let val errors = with_brackets(map) val () = property_dispose(map) in errors end

implement main0() = if ine(c_argc(),3) then exit(2) else if igt(run(),0) then exit(1) else ()
