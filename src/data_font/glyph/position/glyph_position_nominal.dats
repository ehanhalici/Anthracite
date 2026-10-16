#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/glyph/position/glyph_position_work.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
extern fun position_graph_failed(): int = "mac#anth_die_int"
fun nominal(b: !Buf,info: SfntInfo,scale: GlyphScale,core: GlyphCore): GlyphPositionChange = let
  val metrics=sfnt_metrics(b,info,core.glyph)
in glyph_position_change(glyph_position_coordinate(scale.units,scale.xPpem,metrics.advance,0),
  @{status=PositionReady(),value=0},@{status=PositionReady(),value=0},@{status=PositionReady(),value=0},glyph_position_empty()) end
fun walk{n,m,k:nat} .<k>. (left: int(k),b: !Buf,info: SfntInfo,scale: GlyphScale,s: !GlyphStorage(n),
  meta: GlyphRunMeta,cache: !GlyphPositionCache(m),node: int): GlyphPositionStatus =
  if left = 0 then (if ieq(node,~1) then PositionReady() else let val failed=position_graph_failed() in PositionReference() end)
  else if not(glyph_run_node(s,meta,node)) then let val failed=position_graph_failed() in PositionReference() end else let
    val value=nominal(b,info,scale,glyph_storage_core(s,node)) and links=glyph_storage_links(s,node)
  in if not(glyph_position_ready(value.status)) then value.status else let
    val ()=glyph_position_cache_set(cache,node,value.value)
  in walk(left-1,b,info,scale,s,meta,cache,links.next) end end
implement glyph_position_nominal(face,scale,s,meta,cache) = let val+ SfntFace(b,info)=face
in glyph_position_nominal_bytes(b,info,scale,s,meta,cache) end
implement glyph_position_nominal_bytes(b,info,scale,s,meta,cache) = walk(airlock_nat(meta.live),b,info,scale,s,meta,cache,meta.head)
