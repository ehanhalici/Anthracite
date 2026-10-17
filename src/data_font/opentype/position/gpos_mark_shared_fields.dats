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
staload "data_font/opentype/position/gpos_anchor_cache_types.sats"
staload "data_font/opentype/position/gpos_anchor_cache.sats"
staload "data_font/opentype/position/gpos_mark_shared_types.sats"
staload "data_font/opentype/position/gpos_mark_shared.sats"
fun field(index: int,role: GposMarkFields): int = case+ role of
  | MarkRecordFields() => iadd(4,imul(index,4)) | AttachmentFields() => iadd(2,imul(index,2))
fun fill {n:nat} .<n>. (n: int(n),b: !Buf,index: int,role: GposMarkFields): void =
  if n = 0 then () else let val ()=buf_set32(b,index,field(index,role))
  in fill(n-1,b,iadd(index,1),role) end
implement gpos_mark_fields(count,role) = let
  val b=buf_make(imul(count,4)) val ()=buf_set_len(b,imul(count,4))
  val ()=fill(airlock_nat(count),b,0,role)
in b end
