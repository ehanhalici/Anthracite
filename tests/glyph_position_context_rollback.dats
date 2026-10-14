#include "glyph_position_context_test.hats"
fun rejected(p: GlyphPositioned(0),result: GlyphPositionStatus,v: int,m: int,errors: &int >> int): GlyphPositioned(0) = let
  val ()=if glyph_position_ready(result) orelse ine(v,0) orelse ine(m,0) then errors := iadd(errors,1) else ()
in p end
fun overflow(): int = let
  var errors: int=0
  val b=position_context_fixture("0007 0000 0001 0008 0003 0002 0002 0012 0018 0001 0002 0000 0001 0001 0001 0005 0001 0001 0006",
    "0001 0000 0001 0008 0001 0008 0001 0020 0001 0001 0005",
    "0001 0000 0001 0008 0001 0008 0001 0040 0001 0001 0006")
  val m=position_test_metadata(b) val g=position_context_parse(b,m)
  val p=position_test_run("0005 0006",errors)
  val ()=position_test_set(p,0,@{xAdvance=1024,yAdvance=0,xOffset=2147483631,yOffset=0,
    attachment=AttachmentNone(),parent= ~1,anchorX=0,anchorY=0})
  val+ ~GlyphPositionResult(p,status,v,matches)=glyph_position_lookup_graph_lookup(b,g,m,p,0,position_test_all(),PositionLTR())
  val p=rejected(p,status,v,matches,errors)
  val kind: int=case+ status of | PositionOverflow() => 0 | PositionReady() => 1 | PositionDomain() => 1
    | PositionReference() => 1 | PositionCapacity() => 1 | PositionVariation() => 1
  val checked=position_test_values(p,0,1024,0,2147483631,0)+position_test_values(p,1,0,0,0,0)
  val ()=glyph_position_dispose(p) and ()=ot_position_graph_dispose(g)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in iadd(iadd(errors,kind),checked) end
fun cycle(): int = let
  var errors: int=0
  val b=position_context_fixture("0007 0000 0001 0008 0003 0001 0002 0010 0000 0001 0000 0000 0001 0001 0005",
    "0001 0000 0001 0008 0001 0008 0001 0020 0001 0001 0005","0001 0000 0000")
  val m=position_test_metadata(b) val g=position_context_parse(b,m)
  val+ ~GlyphPositionResult(p,status,v,matches)=glyph_position_lookup_graph_lookup(b,g,m,
    position_test_run("0005",errors),0,position_test_all(),PositionLTR())
  val p=rejected(p,status,v,matches,errors)
  val kind: int=case+ status of | PositionReference() => 0 | PositionReady() => 1 | PositionDomain() => 1
    | PositionOverflow() => 1 | PositionCapacity() => 1 | PositionVariation() => 1
  val checked=position_test_values(p,0,1024,0,0,0)
  val ()=glyph_position_dispose(p) and ()=ot_position_graph_dispose(g)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in iadd(iadd(errors,kind),checked) end
implement position_context_rollback() = overflow()+cycle()
