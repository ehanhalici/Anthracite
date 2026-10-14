#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_values.sats"
staload "data_font/gpos_value_cache_types.sats"
staload "data_font/gpos_value_cache.sats"
staload "data_font/gpos_pair_types.sats"
staload "data_font/gpos_pair_work.sats"
fun rows {n:nat} .<n>. (n: int(n),b: !Buf,s: OtSpan,stride: int,glyphs: int,i: int,previous: int): bool =
  if n = 0 then true else let val gid=ot_u16(b,s,iadd(2,imul(i,stride))) in
    if ile(gid,previous) orelse ige(gid,glyphs) then false
    else rows(n-1,b,s,stride,glyphs,iadd(i,1),gid) end
implement gpos_pair_set_glyphs(b,s,count,stride,glyphs) = rows(airlock_nat(count),b,s,stride,glyphs,0,~1)
