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
staload "data_font/opentype/substitution/gsub_ligatures.sats"
staload "data_font/opentype/substitution/gsub_ligature_work.sats"
staload "data_font/opentype/substitution/gsub_ligature_info.sats"
fun missing(): GsubLigatureResult = @{matched=false,glyph=0,components=0,rule=0}
fun components {n:nat} .<n>. (n: int(n),b: !Buf,s: OtSpan,input: !Buf,start: int,i: int,remaining: &int >> _): GsubLigatureMatchStatus =
  if n = 0 then LigatureHit() else if ile(remaining,0) then LigatureBudget() else let
    val ()=remaining := isub(remaining,1)
  in if ine(ot_u16(b,s,iadd(4,imul(i,2))),buf_get32(input,iadd(start,i))) then LigatureMiss()
    else components(n-1,b,s,input,start,iadd(i,1),remaining) end
fun checked(b: !Buf,s: OtSpan,input: !Buf,count: int,start: int,size: int,remaining: &int >> _): GsubLigatureMatchStatus =
  if igt(size,isub(count,start)) then LigatureMiss()
  else components(airlock_nat(isub(size,1)),b,s,input,iadd(start,1),0,remaining)
fun rules {n:nat} .<n>. (n: int(n),b: !Buf,set: OtSpan,input: !Buf,count: int,start: int,index: int,remaining: &int >> _): GsubLigatureMatch =
  if n = 0 then @{status=LigatureMiss(),result=missing()} else if ile(remaining,0) then @{status=LigatureBudget(),result=missing()} else let
    val ()=remaining := isub(remaining,1)
    val child=gsub_ligature_rule(b,set,index)
    val size=ot_u16(b,child.span,2)
  in case+ checked(b,child.span,input,count,start,size,remaining) of
    | LigatureHit() => @{status=LigatureHit(),result= @{matched=true,glyph=ot_u16(b,child.span,0),components=size,rule=index}}
    | LigatureBudget() => @{status=LigatureBudget(),result=missing()}
    | LigatureMiss() => rules(n-1,b,set,input,count,start,iadd(index,1),remaining) end
implement gsub_ligature_info_query(b,info,input,count,start,remaining) =
  if ilt(count,0) orelse igt(count,idiv(buf_cap(input),4)) orelse ilt(start,0) orelse ige(start,count)
  then @{status=LigatureMiss(),result=missing()} else let
    val index=ot_coverage_index(b,info.coverage,buf_get32(input,start))
  in if not(index.found) then @{status=LigatureMiss(),result=missing()} else let val child=gsub_ligature_set(b,info,index.index) in
    rules(airlock_nat(ot_u16(b,child.span,0)),b,child.span,input,count,start,0,remaining) end end
implement gsub_ligatures_query(b,table,input,count,start,remaining) = let val+ GsubLigatures(info)=table
in gsub_ligature_info_query(b,info,input,count,start,remaining) end
extern fun ligature_budget_failed(): int = "mac#anth_die_int"
implement gsub_ligatures_match(b,table,input,count,start) = let var remaining: int=MAX_REC_FUEL
  val query=gsub_ligatures_query(b,table,input,count,start,remaining)
in case+ query.status of | LigatureHit() => query.result | LigatureMiss() => query.result
  | LigatureBudget() => let val failed=ligature_budget_failed() in missing() end end
implement gsub_ligatures_dispose(table) = let val+ ~GsubLigatures(info)=table in () end
