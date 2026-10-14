#include "glyph_position_context_test.hats"
extern fun position_context_failed(): OtPositionGraph = "mac#anth_die_box"
fun append_buffer(b: &Buf >> Buf,child: !Buf,index: int): void = let
  val at=isub(buf_len(b),8)
  val ()=ot_fixture_put16(b,iadd(16,imul(index,2)),isub(at,14))
in buf_append_at(b,child,8,isub(buf_len(child),8)) end
fun append(b: &Buf >> Buf,words: string,index: int): void = let val child=ot_fixture_words(words)
  val ()=append_buffer(b,child,index)
in buf_free(child) end
fun build(first: !Buf,second: string,third: string): Buf = let
  var b: Buf=ot_fixture_words("0001 0000 000A 000C 000E 0000 0000 0003 0000 0000 0000")
  val ()=append_buffer(b,first,0) and ()=append(b,second,1) and ()=append(b,third,2)
  val length=isub(buf_len(b),8)
  val g=position_test_fixture("",TestBaseClasses())
  val ()=buf_set32(b,0,length)
  val ()=buf_append_at(b,g,8,isub(buf_len(g),8))
  val ()=buf_free(g)
in b end
implement position_context_fixture(first,second,third) = let val root=ot_fixture_words(first)
  val b=build(root,second,third) val ()=buf_free(root)
in b end
implement position_context_program(which) = let
  val child=context_fixture(which)
  val words=case+ context_fixture_mode(which) of | ContextPlain() => "0007 0000 0001 0008"
    | ContextChained() => "0008 0000 0001 0008"
  var root: Buf=ot_fixture_words(words)
  val ()=buf_append_at(root,child,8,isub(buf_len(child),8))
  val b=build(root,"0001 0000 0001 0008 0001 0008 0001 0020 0001 0001 0005",
    "0001 0000 0001 0008 0001 0008 0001 0040 0001 0001 0006")
  val ()=buf_free(root) and ()=buf_free(child)
in b end
implement position_context_parse(b,m) = case+ ot_layout_parse(b,position_test_span(b),OtPositioning(),glyph_metadata_capabilities(m)) of
  | ~LayoutRejected(e) => position_context_failed() | ~LayoutAccepted(t) => let
    val result=ot_position_graph_parse(b,t,3,128) val ()=ot_layout_dispose(t)
  in case+ result of | ~PositionGraphRejected(e) => position_context_failed() | ~PositionGraphAccepted(g) => g end
