#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_cursive_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_work.sats"
staload "data_font/glyph/position/glyph_position_anchor.sats"
staload "data_font/glyph/position/glyph_position_cursive_work.sats"
fun cross(flags: OtLookupFlags,delta: int): GlyphCoordinate =
  if flags.rtl then glyph_position_checked(g0int2int_int_llint(delta))
  else glyph_position_checked(~g0int2int_int_llint(delta))
implement glyph_position_cursive_connect(s,meta,c,f,first,second,delta) = let
  val child=if f.rtl then first else second and parent=if f.rtl then second else first
  val y=cross(f,delta.y)
  val reversed=if glyph_position_ready(y.status) then glyph_position_cursive_reverse(s,meta,c,child,parent) else y.status
in if not(glyph_position_ready(reversed)) then reversed else let
  val p=glyph_position_cache_get(c,child) and base=glyph_position_cache_get(c,parent)
  val ()=glyph_position_cache_set(c,child,glyph_position_cursive_attached(p,parent,y.value))
  val ()=if ieq(base.parent,child) then glyph_position_cache_set(c,parent,glyph_position_cursive_detached(base)) else ()
in PositionReady() end end
