#include "font/glyph/position/glyph_position_context_test.hats"
fun layered(): int = let
  var errors: int=0
  val b=position_context_fixture("0007 0000 0001 0008 0003 0002 0002 0012 0018 0001 0002 0000 0001 0001 0001 0005 0001 0001 0006",
    "0007 0000 0001 0008 0003 0001 0001 000C 0000 0002 0001 0001 0005",
    "0001 0000 0001 0008 0001 0008 0001 0040 0001 0001 0005")
  val m=position_test_metadata(b) val g=position_context_parse(b,m)
  val p=position_test_take(glyph_position_lookup_graph_lookup(b,g,m,position_test_run("0005 0006",errors),0,
    position_test_all(),PositionLTR()),2,1,errors)
  val checked=position_test_values(p,0,1024,0,64,0)+position_test_values(p,1,0,0,0,0)
  val ()=glyph_position_dispose(p) and ()=ot_position_graph_dispose(g)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in iadd(errors,checked) end
fun continuation(): int = let
  var errors: int=0
  val b=position_context_fixture("0007 0000 0001 0008 0003 0002 0002 0012 001A 0000 0001 0001 0002 0001 0002 0005 0007 0001 0002 0006 0008",
    "0001 0000 0001 0008 0001 0008 0001 0020 0001 0002 0005 0007",
    "0002 0000 0001 0008 0001 0014 0001 0001 0001 000C 0001 0007 0003 0004 0001 0001 0006")
  val m=position_test_metadata(b) val g=position_context_parse(b,m)
  val p=position_test_take(glyph_position_lookup_graph_lookup(b,g,m,position_test_run("0005 0006 0007 0008",errors),0,
    position_test_all(),PositionLTR()),4,2,errors)
  val checked=position_test_values(p,0,1024,0,32,0)+position_test_values(p,1,0,0,3,0)
    +position_test_values(p,2,0,0,36,0)+position_test_values(p,3,0,0,0,0)
  val ()=glyph_position_dispose(p) and ()=ot_position_graph_dispose(g)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in iadd(errors,checked) end
implement position_context_nested() = layered()+continuation()
