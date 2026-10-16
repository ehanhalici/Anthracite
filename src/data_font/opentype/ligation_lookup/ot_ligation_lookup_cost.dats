#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
staload "data_font/opentype/substitution/gsub_ligatures.sats"
staload "data_font/opentype/substitution/gsub_ligature_work.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup_types.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup_work.sats"
fun rules{n:nat} .<n>. (left: int(n),b: !Buf,s: OtSpan,i: int,total: llint): llint =
  if left = 0 then total else let val child=gsub_ligature_rule(b,s,i)
  in rules(left-1,b,s,iadd(i,1),total+g0int2int_int_llint(iadd(ot_u16(b,child.span,2),1))) end
fun sets{n:nat} .<n>. (left: int(n),b: !Buf,info: GsubLigatureInfo,i: int,total: llint): llint =
  if left = 0 then total else let val child=gsub_ligature_set(b,info,i)
    val count=ot_u16(b,child.span,0)
    val value=rules(airlock_nat(count),b,child.span,0,total+g0int2int_int_llint(iadd(count,1)))
  in sets(left-1,b,info,iadd(i,1),value) end
implement ot_ligation_charge(b,info,remaining) = let
  val floor=g0int2int_int_llint(iadd(info.count,info.coverage.count))+1024LL
  val cost=sets(airlock_nat(info.count),b,info,0,floor)
in if cost > g0int2int_int_llint(remaining) then false else let
  val ()=remaining := isub(remaining,airlock_i32(cost))
in true end end
