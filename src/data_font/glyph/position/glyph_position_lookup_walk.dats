#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_work.sats"
staload "data_font/glyph/position/glyph_position_filter.sats"
staload "data_font/glyph/position/glyph_position_pair_work.sats"
staload "data_font/glyph/position/glyph_position_mark_work.sats"
staload "data_font/glyph/position/glyph_position_lookup_work.sats"
fun candidate{n,m,k:nat}(b: !Buf,t: !OtPositionTables(k,k),metadata: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(m),h: OtLookupInfo(2),selection: GlyphSelection,d: GlyphPositionDirection,
  node: int,bases: !GlyphPositionBases(k)): GlyphPairStep = let val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node) in
  if glyph_position_eligible(b,metadata,h.flags,h.markSet,selection,core)
  then glyph_position_lookup_tables(b,t,metadata,s,meta,scale,c,h.flags,h.markSet,selection,d,node,bases)
  else @{status=PositionReady(),next=links.next,matched=false} end
fun walk{n,m,k,r:nat} .<r>. (left: int(r),b: !Buf,t: !OtPositionTables(k,k),metadata: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,scale: GlyphScale,c: !GlyphPositionCache(m),h: OtLookupInfo(2),selection: GlyphSelection,d: GlyphPositionDirection,
  node: int,bases: !GlyphPositionBases(k),matches: &int >> _): GlyphPositionStatus =
  if ieq(node,~1) then PositionReady() else if left = 0 then PositionReference()
  else if not(glyph_run_node(s,meta,node)) then PositionReference() else let
    val result=candidate(b,t,metadata,s,meta,scale,c,h,selection,d,node,bases)
    val ()=glyph_position_lookup_refresh(b,t,metadata,s,node,selection,bases)
    val ()=if result.matched then matches := iadd(matches,1) else ()
  in if not(glyph_position_ready(result.status)) then result.status
    else walk(left-1,b,t,metadata,s,meta,scale,c,h,selection,d,result.next,bases,matches) end
implement glyph_position_lookup_walk(b,t,m,s,meta,scale,c,selection,d,matches) = let
  val+ OtPositionLookup(h,a,glyphs,tables)=t val+ OtPositionTables(pf,gc | rows,count,filled)=tables
  val bases=glyph_position_bases_make(count)
  val status=walk(airlock_nat(meta.live),b,tables,m,s,meta,scale,c,h,selection,d,meta.head,bases,matches)
  val ()=glyph_position_bases_dispose(bases)
in status end
