#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_single_types.sats"
staload "data_font/gpos_single.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_filter.sats"
staload "data_font/glyph_position_single_work.sats"
extern fun single_position_graph_failed(): int = "mac#anth_die_int"
fun apply{n:nat}(b: !Buf,t: !GposSingle,scale: GlyphScale,cache: !GlyphPositionCache(n),
  node: int,core: GlyphCore,matches: &int >> _): GlyphPositionStatus = let val query=gpos_single_query(b,t,core.glyph)
in if not(query.matched) then PositionReady() else let
  val change=glyph_position_value(b,scale,query.value,glyph_position_cache_get(cache,node))
  val ()=if glyph_position_ready(change.status) then let
    val ()=glyph_position_cache_set(cache,node,change.value)
  in matches := iadd(matches,1) end else ()
in change.status end end
fun walk{n,m,k:nat} .<k>. (left: int(k),b: !Buf,t: !GposSingle,metadata: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,scale: GlyphScale,flags: OtLookupFlags,set: int,selection: GlyphSelection,
  cache: !GlyphPositionCache(m),node: int,matches: &int >> _): GlyphPositionStatus =
  if left = 0 then (if ieq(node,~1) then PositionReady() else let val failed=single_position_graph_failed() in PositionReference() end)
  else if not(glyph_run_node(s,meta,node)) then let val failed=single_position_graph_failed() in PositionReference() end else let
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
    val status=if glyph_position_eligible(b,metadata,flags,set,selection,core)
      then apply(b,t,scale,cache,node,core,matches) else PositionReady()
  in if not(glyph_position_ready(status)) then status
    else walk(left-1,b,t,metadata,s,meta,scale,flags,set,selection,cache,links.next,matches) end
implement glyph_position_single_walk(b,t,m,s,meta,scale,flags,set,selection,cache,matches) =
  walk(airlock_nat(meta.live),b,t,m,s,meta,scale,flags,set,selection,cache,meta.head,matches)
