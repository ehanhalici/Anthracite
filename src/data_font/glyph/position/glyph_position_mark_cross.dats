#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_mark_matrix_types.sats"
staload "data_font/opentype/position/gpos_mark_ligature_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_work.sats"
staload "data_font/glyph/position/glyph_position_mark_work.sats"
fun walk{n,m,k:nat} .<k>. (left: int(k),s: !GlyphStorage(n),meta: GlyphRunMeta,
  c: !GlyphPositionCache(m),node: int,sum: llint): GlyphCoordinate =
  if left = 0 then @{status=PositionReference(),value=0}
  else if not(glyph_run_node(s,meta,node)) then @{status=PositionReference(),value=0} else let
    val p=glyph_position_cache_get(c,node)
    val next=sum+g0int2int_int_llint(p.yOffset)
  in case+ p.attachment of | AttachmentNone() => glyph_position_checked(next)
    | AttachmentMark() => glyph_position_checked(next)
    | AttachmentCursive() => walk(left-1,s,meta,c,p.parent,next) end
implement glyph_position_mark_cross(s,meta,c,node) = walk(airlock_nat(meta.live),s,meta,c,node,0LL)
