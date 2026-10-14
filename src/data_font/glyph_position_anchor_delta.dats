#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_values.sats"
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_anchor.sats"
fun field(b: !Buf,units: int,ppem: int,design: int,mark: OtAdjustment,target: OtAdjustment): GlyphCoordinate = let
  val a=ot_adjustment_sample(b,mark,ppem) and c=ot_adjustment_sample(b,target,ppem)
in case+ a.kind of
  | PixelVariation() => @{status=PositionVariation(),value=0}
  | PixelResolved() => (case+ c.kind of | PixelVariation() => @{status=PositionVariation(),value=0}
    | PixelResolved() => glyph_position_coordinate(units,ppem,design,isub(c.pixels,a.pixels))) end
implement glyph_position_anchor_delta(b,s,a,c) = let
  val x=field(b,s.units,s.xPpem,isub(c.x,a.x),a.dx,c.dx)
  val y=field(b,s.units,s.yPpem,isub(c.y,a.y),a.dy,c.dy)
in @{status=if glyph_position_ready(x.status) then y.status else x.status,x=x.value,y=y.value} end
implement glyph_position_anchor_sample(b,s,a) = let val none=ot_adjustment_absent()
  val zero: OtAnchorInfo= @{kind=AnchorCoordinates(),x=0,y=0,point=0,dx=none,dy=none}
in glyph_position_anchor_delta(b,s,zero,a) end
