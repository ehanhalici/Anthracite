#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_anchor.sats"
fun attached(old: GlyphPosition,parent: int,x: int,y: int): GlyphPosition =
  @{xAdvance=old.xAdvance,yAdvance=old.yAdvance,xOffset=x,yOffset=y,
    attachment=AttachmentMark(),parent=parent,anchorX=0,anchorY=0}
implement glyph_position_anchor_attach(b,s,c,cross,node,parent,mark,target) =
  case+ mark.kind of | AnchorMissing() => PositionReference()
  | AnchorPresent() => (case+ target.kind of | AnchorMissing() => PositionReference()
    | AnchorPresent() => let
      val delta=glyph_position_anchor_delta(b,s,mark.anchor,target.anchor)
      val old=glyph_position_cache_get(c,node)
      val y=glyph_position_sum(delta.y,cross.value)
      val status=if not(glyph_position_ready(cross.status)) then cross.status
        else if glyph_position_ready(delta.status) then y.status else delta.status
      val ()=if glyph_position_ready(status) then glyph_position_cache_set(c,node,attached(old,parent,delta.x,y.value)) else ()
    in status end)
