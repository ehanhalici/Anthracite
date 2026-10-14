#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position.sats"
staload "glyph_position_contracts.sats"
fun cursive(parent: int,y: int): GlyphPosition = @{xAdvance=0,yAdvance=0,xOffset=0,yOffset=y,
  attachment=AttachmentCursive(),parent=parent,anchorX=0,anchorY=0}
fun forward(): int = let
  var errors: int=0 val p=position_test_run("0005 0005 0005",errors)
  val ()=position_test_set(p,0,cursive(2,1)) and ()=position_test_set(p,1,cursive(0,2))
  val ()=position_test_set(p,2,@{xAdvance=0,yAdvance=0,xOffset=0,yOffset=3,
    attachment=AttachmentNone(),parent= ~1,anchorX=0,anchorY=0})
  val p=position_test_frozen(glyph_position_finish(p,PositionLTR()),errors)
  val ()=errors := errors+position_test_values(p,0,0,0,0,4)+position_test_values(p,1,0,0,0,6)
  val ()=glyph_position_dispose(p)
in errors end
fun cyclic(): int = let
  var errors: int=0 val p=position_test_run("0005 0005",errors)
  val ()=position_test_set(p,0,cursive(1,1)) and ()=position_test_set(p,1,cursive(0,2))
in case+ glyph_position_finish(p,PositionRTL()) of | ~PositionFinished(p) => let val ()=glyph_position_dispose(p) in errors+1 end
  | ~PositionUnfinished(p,status) => let
    val valid=case+ status of | PositionReference() => true | PositionDomain() => false | PositionCapacity() => false
      | PositionOverflow() => false | PositionReady() => false | PositionVariation() => false
    val e=iadd(iadd(position_test_values(p,0,0,0,0,1),position_test_values(p,1,0,0,0,2)),if valid then 0 else 1)
    val ()=glyph_position_dispose(p)
  in errors+e end end
implement position_test_graph_cases() = forward()+cyclic()
