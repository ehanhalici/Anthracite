#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/substitution/gsub_single_work.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_types.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_work.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup.sats"
fun query{n,k:nat} .<k>. (left: int(k),b: !Buf,t: !OtSingleTables(n,n),glyph: int,i: int): GsubSingleResult =
  if left = 0 then @{matched=false,glyph=glyph} else let
    val result=gsub_single_query_info(b,ot_single_tables_get(t,i),glyph)
  in if result.matched then result else query(left-1,b,t,glyph,iadd(i,1)) end
implement ot_single_lookup_query(b,lookup,glyph) = let val+ OtSingleLookup(h,glyphs,t)=lookup in
  if ilt(glyph,0) orelse ige(glyph,glyphs) then @{matched=false,glyph=glyph}
  else query(airlock_nat(h.count),b,t,glyph,0) end
implement ot_single_lookup_header(lookup) = let val+ OtSingleLookup(h,glyphs,t)=lookup in h end
implement ot_single_lookup_glyphs(lookup) = let val+ OtSingleLookup(h,glyphs,t)=lookup in glyphs end
implement ot_single_lookup_dispose(lookup) = let val+ ~OtSingleLookup(h,glyphs,t)=lookup in
  ot_single_tables_dispose(t) end
