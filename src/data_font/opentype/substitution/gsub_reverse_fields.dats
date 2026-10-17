#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/coverage/ot_cov_cache_types.sats"
staload "data_font/opentype/substitution/gsub_reverse_types.sats"
staload "data_font/opentype/substitution/gsub_reverse_work.sats"
fun fields {n:nat} .<n>. (n: int(n),output: !Buf,slot: int,at: int): void =
  if n = 0 then () else let val ()=buf_set32(output,slot,at) in
    fields(n-1,output,iadd(slot,1),iadd(at,2)) end
implement gsub_reverse_fields(info) = let
  val total=iadd(iadd(info.back,info.look),1)
  val output=buf_make(imul(total,4))
  val ()=buf_set32(output,0,2)
  val ()=fields(info.back,output,1,6)
  val ()=fields(info.look,output,iadd(info.back,1),iadd(8,imul(info.back,2)))
  val ()=buf_set_len(output,imul(total,4))
in output end
