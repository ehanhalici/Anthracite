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
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_cursive_work.sats"
fun fill {n:nat} .<n>. (n: int(n),fields: !Buf,index: int): void =
  if n = 0 then () else let val ()=buf_set32(fields,index,iadd(6,imul(index,2)))
  in fill(n-1,fields,iadd(index,1)) end
implement gpos_cursive_fields(count) = let
  val slots=imul(count,2) val b=buf_make(imul(slots,4))
  val ()=buf_set_len(b,imul(slots,4))
  val ()=fill(airlock_nat(slots),b,0)
in b end
