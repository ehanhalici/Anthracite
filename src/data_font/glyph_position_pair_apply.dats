#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_pair_types.sats"
staload "data_font/gpos_pairs.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_pair_work.sats"
fun change{n:nat}(b: !Buf,scale: GlyphScale,cache: !GlyphPositionCache(n),query: GposPairView,
  first: int,second: int,next: int): GlyphPairStep = let
  val a=glyph_position_value(b,scale,query.first,glyph_position_cache_get(cache,first))
  val c=glyph_position_value(b,scale,query.second,glyph_position_cache_get(cache,second))
  val status=if glyph_position_ready(a.status) then c.status else a.status
  val ()=if glyph_position_ready(status) then let val ()=glyph_position_cache_set(cache,first,a.value)
    in glyph_position_cache_set(cache,second,c.value) end else ()
in @{status=status,next=next,matched=true} end
implement glyph_position_pair_apply(b,t,s,scale,cache,first,second,core) = let
  val second_core=glyph_storage_core(s,second)
  val query=gpos_pair_query(b,t,core.glyph,second_core.glyph)
  val first_links=glyph_storage_links(s,first) and second_links=glyph_storage_links(s,second)
  val next=case+ query.progress of | PairContinueSecond() => second | PairContinueFollowing() => second_links.next
in if query.matched then change(b,scale,cache,query,first,second,next)
  else @{status=PositionReady(),next=first_links.next,matched=false} end
