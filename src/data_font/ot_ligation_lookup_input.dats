#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/gsub_ligature_info.sats"
staload "data_font/ot_ligation_lookup_types.sats"
staload "data_font/ot_ligation_lookup_work.sats"
fun walk{n,i:nat | i <= n} .<n-i>. (index: int(i),b: !Buf,t: !OtLigationTables(n,n),glyph: int,maximum: int,
  remaining: &int >> _): GsubLigatureInputBound = let val+ OtLigationTables(rows,count,filled)=t
in if index = count then @{maximum=maximum,status=LigationInputReady()}
  else if ile(remaining,0) then @{maximum=0,status=LigationInputBudget()} else let
    val ()=remaining := isub(remaining,1)
    val r=gsub_ligature_info_input(b,ot_ligation_tables_get(t,index),glyph,remaining)
  in case+ r.status of | LigationInputBudget() => r
    | LigationInputReady() => walk(index+1,b,t,glyph,imax(maximum,r.maximum),remaining) end end
implement ot_ligation_tables_input(b,t,glyph,remaining) = walk(0,b,t,glyph,0,remaining)
