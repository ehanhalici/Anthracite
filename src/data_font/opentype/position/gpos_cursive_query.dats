#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_values.sats"
staload "data_font/opentype/position/gpos_anchor_cache_types.sats"
staload "data_font/opentype/position/gpos_anchor_cache.sats"
staload "data_font/opentype/position/gpos_cursive_types.sats"
staload "data_font/opentype/position/gpos_cursive.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
implement gpos_cursive_query(b,table,glyph) = let val+ GposCursive(c,glyphs,cache)=table
  val index=ot_coverage_index(b,c,glyph)
in if not(index.found) then @{matched=false,entry=ot_anchor_missing(),exit=ot_anchor_missing()} else
  @{matched=true,entry=ot_anchor_cache_get(cache,imul(index.index,2)),exit=ot_anchor_cache_get(cache,iadd(imul(index.index,2),1))} end
implement gpos_cursive_pair(b,table,first,second) = let
  val a=gpos_cursive_query(b,table,first) and c=gpos_cursive_query(b,table,second)
  val exit=case+ a.exit.kind of | AnchorMissing() => false | AnchorPresent() => true
  val entry=case+ c.entry.kind of | AnchorMissing() => false | AnchorPresent() => true
in @{matched=a.matched andalso c.matched andalso exit andalso entry,exit=a.exit,entry=c.entry} end
implement gpos_cursive_dispose(table) = let val+ ~GposCursive(c,glyphs,cache)=table in ot_anchor_cache_dispose(cache) end
implement gpos_cursive_glyphs(table) = let val+ GposCursive(c,glyphs,cache)=table in glyphs end
