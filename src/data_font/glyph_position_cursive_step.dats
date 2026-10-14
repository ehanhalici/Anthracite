#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_cursive_types.sats"
staload "data_font/gpos_cursive.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_anchor.sats"
staload "data_font/glyph_position_cursive_work.sats"
fun apply{n,m:nat}(b: !Buf,s: !GlyphStorage(n),meta: GlyphRunMeta,scale: GlyphScale,c: !GlyphPositionCache(m),
  f: OtLookupFlags,d: GlyphPositionDirection,first: int,second: int,query: GposCursivePair): GlyphCursiveStep = let
  val exit=glyph_position_anchor_sample(b,scale,query.exit.anchor) and entry=glyph_position_anchor_sample(b,scale,query.entry.anchor)
  val delta=glyph_position_anchor_delta(b,scale,query.exit.anchor,query.entry.anchor)
  val main=glyph_position_cursive_main(d,glyph_position_cache_get(c,first),glyph_position_cache_get(c,second),exit,entry)
  val status=if glyph_position_ready(main.status) then delta.status else main.status
in if not(glyph_position_ready(status)) then @{status=status,matched=true} else let
  val ()=glyph_position_cache_set(c,first,main.first) and ()=glyph_position_cache_set(c,second,main.second)
in @{status=glyph_position_cursive_connect(s,meta,c,f,first,second,delta),matched=true} end end
implement glyph_position_cursive_step(b,t,s,meta,scale,c,f,d,first,second) = let
  val a=glyph_storage_core(s,first) and e=glyph_storage_core(s,second)
  val query=gpos_cursive_pair(b,t,a.glyph,e.glyph)
in if not(query.matched) then @{status=PositionReady(),matched=false}
  else apply(b,s,meta,scale,c,f,d,first,second,query) end
