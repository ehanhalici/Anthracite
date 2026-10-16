#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
staload "data_font/opentype/substitution/gsub_ligature_info.sats"
staload "data_font/opentype/substitution/gsub_ligature_work.sats"
fun rules{n:nat} .<n>. (left: int(n),b: !Buf,s: OtSpan,i: int,maximum: int,remaining: &int >> _): GsubLigatureInputBound =
  if left = 0 then @{maximum=maximum,status=LigationInputReady()} else if ile(remaining,0) then @{maximum=0,status=LigationInputBudget()}
  else let val ()=remaining := isub(remaining,1) val rule=gsub_ligature_rule(b,s,i)
  in rules(left-1,b,s,iadd(i,1),imax(maximum,ot_u16(b,rule.span,2)),remaining) end
implement gsub_ligature_info_input(b,info,glyph,remaining) = let
  val c=ot_coverage_index(b,info.coverage,glyph)
in if not(c.found) then @{maximum=0,status=LigationInputReady()} else let val child=gsub_ligature_set(b,info,c.index)
  in rules(airlock_nat(ot_u16(b,child.span,0)),b,child.span,0,0,remaining) end end
