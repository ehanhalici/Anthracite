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
staload "data_font/opentype/substitution/gsub_ligature_info.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup.sats"
fun query{n,i:nat | i <= n} .<n-i>. (index: int(i),b: !Buf,t: !OtLigationTables(n,n),input: !Buf,
  count: int,start: int,remaining: &int >> _): GsubLigatureMatch = let val+ OtLigationTables(rows,n,filled)=t
in if index = n then @{status=LigatureMiss(),result= @{matched=false,glyph=0,components=0,rule=0}}
  else if ile(remaining,0) then @{status=LigatureBudget(),result= @{matched=false,glyph=0,components=0,rule=0}} else let
  val ()=remaining := isub(remaining,1)
  val info=ot_ligation_tables_get(t,index)
  val r=gsub_ligature_info_query(b,info,input,count,start,remaining)
in case+ r.status of | LigatureHit() => r | LigatureBudget() => r
  | LigatureMiss() => query(index+1,b,t,input,count,start,remaining) end end
implement ot_ligation_tables_query(b,t,input,count,start,remaining) = query(0,b,t,input,count,start,remaining)
implement ot_ligation_lookup_query(b,t,input,count,start,remaining) = let val+ OtLigationLookup(h,glyphs,maximum,rows)=t
in ot_ligation_tables_query(b,rows,input,count,start,remaining) end
implement ot_ligation_lookup_info(t) = let val+ OtLigationLookup(h,glyphs,maximum,rows)=t in h end
implement ot_ligation_lookup_glyphs(t) = let val+ OtLigationLookup(h,glyphs,maximum,rows)=t in glyphs end
implement ot_ligation_lookup_maximum(t) = let val+ OtLigationLookup(h,glyphs,maximum,rows)=t in maximum end
implement ot_ligation_lookup_dispose(t) = let val+ ~OtLigationLookup(h,glyphs,maximum,rows)=t in ot_ligation_tables_dispose(rows) end
