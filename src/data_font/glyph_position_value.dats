#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_values.sats"
fun field(b: !Buf,units: int,ppem: int,design: int,device: OtAdjustment,old: int): GlyphCoordinate = let
  val sample=ot_adjustment_sample(b,device,ppem)
in case+ sample.kind of
  | PixelVariation() => @{status=PositionVariation(),value=0}
  | PixelResolved() => let val delta=glyph_position_coordinate(units,ppem,design,sample.pixels) in
    if glyph_position_ready(delta.status) then glyph_position_sum(old,delta.value) else delta end end
implement glyph_position_value(b,scale,v,old) =
  glyph_position_change(field(b,scale.units,scale.xPpem,v.units.xAdvance,v.xAdvance,old.xAdvance),
    field(b,scale.units,scale.yPpem,v.units.yAdvance,v.yAdvance,old.yAdvance),
    field(b,scale.units,scale.xPpem,v.units.xPlace,v.xPlace,old.xOffset),
    field(b,scale.units,scale.yPpem,v.units.yPlace,v.yPlace,old.yOffset),old)
