#include "font/glyph/position/glyph_position_context_test.hats"
fun invalid(first: string,second: string,third: string): int = let
  val b=position_context_fixture(first,second,third)
  val m=position_test_metadata(b)
  val error: int=case+ ot_layout_parse(b,position_test_span(b),OtPositioning(),glyph_metadata_capabilities(m)) of
    | ~LayoutRejected(e) => 0 | ~LayoutAccepted(t) => let
      val result=ot_position_graph_parse(b,t,3,128) val ()=ot_layout_dispose(t)
    in case+ result of | ~PositionGraphRejected(e) => 0 | ~PositionGraphAccepted(g) => let val ()=ot_position_graph_dispose(g) in 1 end end
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in error end
fun empty(): int = let
  var errors: int=0
  val b=position_context_fixture("0007 0000 0000","0008 0000 0000","0009 0000 0000")
  val m=position_test_metadata(b) val g=position_context_parse(b,m)
  val p=position_test_take(glyph_position_lookup_graph_lookup(b,g,m,position_test_run("0005 0006",errors),0,
    position_test_all(),PositionLTR()),2,0,errors)
  val p=position_test_take(glyph_position_lookup_graph_lookup(b,g,m,p,1,position_test_all(),PositionLTR()),2,0,errors)
  val p=position_test_take(glyph_position_lookup_graph_lookup(b,g,m,p,2,position_test_all(),PositionLTR()),2,0,errors)
  val ()=glyph_position_dispose(p) and ()=ot_position_graph_dispose(g)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
fun noop(): int = let
  var errors: int=0
  val b=position_context_fixture("0007 0000 0002 000A 0020 0003 0002 0000 000A 0010 0001 0001 0005 0001 0001 0006 0003 0002 0002 0012 0018 0001 0002 0000 0001 0001 0001 0005 0001 0001 0006",
    "0001 0000 0001 0008 0001 0008 0001 0020 0001 0001 0005","0001 0000 0000")
  val m=position_test_metadata(b) val g=position_context_parse(b,m)
  val p=position_test_take(glyph_position_lookup_graph_lookup(b,g,m,position_test_run("0005 0006",errors),0,
    position_test_all(),PositionLTR()),2,1,errors)
  val checked=position_test_values(p,0,1024,0,0,0)
  val ()=glyph_position_dispose(p) and ()=ot_position_graph_dispose(g)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors+checked end
implement position_context_cache() = empty()+noop()
  +invalid("0007 0000 0001 0008 0003 0001 0001 000C 0000 0003 0001 0001 0005","0001 0000 0000","0001 0000 0000")
  +invalid("0007 0000 0001 0008 FFFF","0001 0000 0001 0008 0001 0008 0001 0020 0001 0001 0005","0001 0000 0000")
