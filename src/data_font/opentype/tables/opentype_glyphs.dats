#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/tables/opentype_glyphs.sats"
fun valid {n:nat} .<n>. (n: int(n),b: !Buf,s: OtSpan,header: int,glyphs: int,i: int): bool =
  if n = 0 then true else if ige(ot_u16(b,s,iadd(header,imul(i,2))),glyphs) then false
  else valid(n-1,b,s,header,glyphs,iadd(i,1))
implement ot_glyph_array_valid(b,s,header,count,glyphs) = valid(airlock_nat(count),b,s,header,glyphs,0)
