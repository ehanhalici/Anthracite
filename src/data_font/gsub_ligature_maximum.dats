#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/gsub_ligature_work.sats"
fun rules{n:nat} .<n>. (left: int(n),b: !Buf,s: OtSpan,i: int,maximum: int): int =
  if left = 0 then maximum else let val child=gsub_ligature_rule(b,s,i)
  in rules(left-1,b,s,iadd(i,1),imax(maximum,ot_u16(b,child.span,2))) end
fun sets{n:nat} .<n>. (left: int(n),b: !Buf,info: GsubLigatureInfo,i: int,maximum: int): int =
  if left = 0 then maximum else let val child=gsub_ligature_set(b,info,i)
    val value=rules(airlock_nat(ot_u16(b,child.span,0)),b,child.span,0,maximum)
  in sets(left-1,b,info,iadd(i,1),value) end
implement gsub_ligature_maximum(b,info) = sets(airlock_nat(info.count),b,info,0,0)
