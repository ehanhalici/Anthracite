#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_value_work.sats"
implement ot_value_signed16(raw) = if ige(raw,32768) then isub(raw,65536) else raw
fun units(b: !Buf,s: OtSpan,at: int,field: int): int =
  if ilt(field,0) then 0 else ot_value_signed16(ot_u16(b,s,iadd(at,field)))
implement ot_value_units(b,s,at,f) = @{xPlace=units(b,s,at,f.xp),yPlace=units(b,s,at,f.yp),
  xAdvance=units(b,s,at,f.xa),yAdvance=units(b,s,at,f.ya)}
implement ot_value_device_offset(b,s,at,field) = if ilt(field,0) then 0 else ot_u16(b,s,iadd(at,field))
