#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/substitution/gsub_sequence_work.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_work.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup.sats"
fun multiple{n,k:nat} .<k>. (left: int(k),b: !Buf,t: !OtSequenceTables(n,n),glyph: int,i: int): GsubSequenceView =
  if left = 0 then @{matched=false,span= @{offset=0,length=0},count=0} else let
    val v=gsub_sequences_query_info(b,ot_sequence_tables_get(t,i),glyph)
  in if v.matched then v else multiple(left-1,b,t,glyph,iadd(i,1)) end
fun alternate{n,k:nat} .<k>. (left: int(k),b: !Buf,t: !OtSequenceTables(n,n),glyph: int,choice: int,i: int): GsubSingleResult =
  if left = 0 then @{matched=false,glyph=glyph} else let
    val v=gsub_alternate_select_info(b,ot_sequence_tables_get(t,i),glyph,choice)
  in if v.matched then v else alternate(left-1,b,t,glyph,choice,iadd(i,1)) end
implement ot_multiple_lookup_query(b,lookup,glyph) = let val+ OtSequenceLookup(h,glyphs,t)=lookup in
  if ilt(glyph,0) orelse ige(glyph,glyphs) then @{matched=false,span= @{offset=0,length=0},count=0}
  else multiple(airlock_nat(h.count),b,t,glyph,0) end
implement ot_alternate_lookup_query(b,lookup,glyph,choice) = let val+ OtSequenceLookup(h,glyphs,t)=lookup in
  if ilt(glyph,0) orelse ige(glyph,glyphs) orelse ile(choice,0) then @{matched=false,glyph=glyph}
  else alternate(airlock_nat(h.count),b,t,glyph,choice,0) end
implement ot_sequence_lookup_header(t) = let val+ OtSequenceLookup(h,glyphs,tables)=t in h end
implement ot_sequence_lookup_glyphs(t) = let val+ OtSequenceLookup(h,glyphs,tables)=t in glyphs end
implement ot_sequence_lookup_dispose(t) = let val+ ~OtSequenceLookup(h,glyphs,tables)=t in ot_sequence_tables_dispose(tables) end
