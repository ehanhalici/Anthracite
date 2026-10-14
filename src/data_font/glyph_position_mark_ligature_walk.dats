#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_mark_matrix_types.sats"
staload "data_font/gpos_mark_ligature_types.sats"
staload "data_font/gpos_mark_ligature.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_work.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_filter.sats"
staload "data_font/glyph_position_mark_work.sats"
fun candidate{n,m:nat}(b: !Buf,t: !GposMarkLigature,metadata: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,f: OtLookupFlags,set: int,selection: GlyphSelection,c: !GlyphPositionCache(m),
  node: int,base: int,core: GlyphCore): GlyphMarkStep =
  if glyph_position_eligible(b,metadata,f,set,selection,core)
  then glyph_position_mark_ligature_step(b,t,s,meta,scale,c,node,base) else @{status=PositionReady(),matched=false}
fun next_base(b: !Buf,t: !GposMarkLigature,metadata: !GlyphMetadata,selection: GlyphSelection,node: int,base: int,core: GlyphCore): int =
  if glyph_position_is_mark(metadata,core) then base
  else if not(glyph_pass_selected(selection,core.mask)) then base
  else if not(core.multiplied) orelse ieq(core.component,0) orelse igt(gpos_mark_ligature_components(b,t,core.glyph),0) then node
  else base
fun walk{n,m,k:nat} .<k>. (left: int(k),b: !Buf,t: !GposMarkLigature,metadata: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,scale: GlyphScale,f: OtLookupFlags,set: int,selection: GlyphSelection,c: !GlyphPositionCache(m),
  node: int,base: int,matches: &int >> _): GlyphPositionStatus =
  if ieq(node,~1) then PositionReady()
  else if left = 0 then PositionReference()
  else if not(glyph_run_node(s,meta,node)) then PositionReference() else let
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
    val step=candidate(b,t,metadata,s,meta,scale,f,set,selection,c,node,base,core)
    val ()=if step.matched then matches := iadd(matches,1) else ()
    val next=next_base(b,t,metadata,selection,node,base,core)
  in if not(glyph_position_ready(step.status)) then step.status
    else walk(left-1,b,t,metadata,s,meta,scale,f,set,selection,c,links.next,next,matches) end
implement glyph_position_mark_ligature_walk(b,t,m,s,meta,scale,f,set,selection,c,matches) =
  walk(airlock_nat(meta.live),b,t,m,s,meta,scale,f,set,selection,c,meta.head,~1,matches)
