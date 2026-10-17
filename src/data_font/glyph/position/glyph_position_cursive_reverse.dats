#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_cursive_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_work.sats"
staload "data_font/glyph/position/glyph_position_anchor.sats"
staload "data_font/glyph/position/glyph_position_cursive_work.sats"
fun walk{n,m,k:nat} .<k>. (left: int(k),s: !GlyphStorage(n),meta: GlyphRunMeta,c: !GlyphPositionCache(m),
  cursor: int,previous: int,parent: int,y: int): GlyphPositionStatus =
  if ieq(cursor,parent) then PositionReady()
  else if left = 0 then PositionReference()
  else if not(glyph_run_node(s,meta,cursor)) then PositionReference() else let
    val p=glyph_position_cache_get(c,cursor)
    val reverse=glyph_position_checked(~g0int2int_int_llint(y))
  in if not(glyph_position_ready(reverse.status)) then reverse.status else let
    val ()=glyph_position_cache_set(c,cursor,glyph_position_cursive_attached(p,previous,reverse.value))
  in case+ p.attachment of | AttachmentNone() => PositionReady() | AttachmentMark() => PositionReady()
    | AttachmentCursive() => walk(left-1,s,meta,c,p.parent,cursor,parent,p.yOffset) end end
implement glyph_position_cursive_reverse(s,meta,c,child,parent) = let val p=glyph_position_cache_get(c,child) in
  case+ p.attachment of | AttachmentNone() => PositionReady() | AttachmentMark() => PositionReady()
  | AttachmentCursive() => let val ()=glyph_position_cache_set(c,child,glyph_position_cursive_detached(p))
    in walk(airlock_nat(meta.live),s,meta,c,p.parent,child,parent,p.yOffset) end end
