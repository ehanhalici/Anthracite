#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_graph_types.sats"
staload "data_font/glyph_position_graph.sats"
staload "data_font/glyph_position_graph_work.sats"
implement glyph_position_graph_parent(mode,p) = case+ p.attachment of
  | AttachmentNone() => ~1 | AttachmentCursive() => p.parent
  | AttachmentMark() => (case+ mode of | PositionCross() => ~1 | PositionFinal(d) => p.parent)
fun origin_delta(d: GlyphPositionDirection,own: GlyphPositionOrigin,base: GlyphPositionOrigin): GlyphPositionOrigin =
  case+ d of | PositionLTR() => @{x=base.x-own.x,y=base.y-own.y}
  | PositionRTL() => @{x=own.x-base.x,y=own.y-base.y}
fun mark{n:nat}(g: !GlyphPositionGraph(n),d: GlyphPositionDirection,node: int,
  p: GlyphPosition,parent: GlyphPosition): GlyphPositionChange = let
  val own=glyph_position_graph_origin(g,node) and base=glyph_position_graph_origin(g,p.parent)
  val delta=origin_delta(d,own,base)
  val xa: GlyphCoordinate= @{status=PositionReady(),value=p.xAdvance}
  val ya: GlyphCoordinate= @{status=PositionReady(),value=p.yAdvance}
  val x=glyph_position_checked(g0int2int_int_llint(p.xOffset)+g0int2int_int_llint(parent.xOffset)+delta.x)
  val y=glyph_position_checked(g0int2int_int_llint(p.yOffset)+delta.y)
in glyph_position_change(xa,ya,x,y,p) end
implement glyph_position_graph_change(g,mode,node,p,parent) = case+ p.attachment of
  | AttachmentNone() => @{status=PositionReady(),value=p}
  | AttachmentCursive() => glyph_position_change(@{status=PositionReady(),value=p.xAdvance},
    @{status=PositionReady(),value=p.yAdvance},@{status=PositionReady(),value=p.xOffset},
    glyph_position_sum(p.yOffset,parent.yOffset),p)
  | AttachmentMark() => (case+ mode of | PositionCross() => @{status=PositionReady(),value=p}
    | PositionFinal(d) => mark(g,d,node,p,parent))
