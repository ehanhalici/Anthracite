#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_values.sats"
staload "data_font/opentype/tables/opentype_device.sats"
implement ot_adjustment_sample(b,a,ppem) = case+ a.kind of
  | AdjustmentAbsent() => @{kind=PixelResolved(),pixels=0,outer=0,inner=0}
  | AdjustmentDevice() => @{kind=PixelResolved(),pixels=ot_device_pixels(b,a.device,ppem),outer=0,inner=0}
  | AdjustmentVariation() => @{kind=PixelVariation(),pixels=0,outer=a.outer,inner=a.inner}
implement ot_value_sample(b,v,ppem) = @{units=v.units,
  xPlace=ot_adjustment_sample(b,v.xPlace,ppem),yPlace=ot_adjustment_sample(b,v.yPlace,ppem),
  xAdvance=ot_adjustment_sample(b,v.xAdvance,ppem),yAdvance=ot_adjustment_sample(b,v.yAdvance,ppem)}
implement ot_value_zero() = let val a=ot_adjustment_absent() in
  @{units= @{xPlace=0,yPlace=0,xAdvance=0,yAdvance=0},xPlace=a,yPlace=a,xAdvance=a,yAdvance=a} end
