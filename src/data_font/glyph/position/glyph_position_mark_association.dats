#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_mark_matrix_types.sats"
staload "data_font/opentype/position/gpos_mark_ligature_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_mark_work.sats"
typedef Affinity = @{id=int,component=int}
fun affinity{n:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,node: int): Affinity = let
  val core=glyph_storage_core(s,node)
in case+ core.association of | Unassociated() => @{id=0,component=0}
  | LigatureForward() => @{id=0,component=0}
  | LigatureOwner() => @{id=iadd(node,1),component=0}
  | LigatureMark() => let val a=glyph_run_association(s,meta,node)
    in if a.found then @{id=iadd(a.owner,1),component=iadd(a.component,1)} else @{id=0,component=0} end end
implement glyph_position_mark_affinity(s,meta,node,parent) = let
  val a=affinity(s,meta,node) and c=affinity(s,meta,parent)
in if ieq(a.id,c.id) then ieq(a.id,0) orelse ieq(a.component,c.component)
  else (igt(a.id,0) andalso ieq(a.component,0)) orelse (igt(c.id,0) andalso ieq(c.component,0)) end
implement glyph_position_mark_component(s,meta,node,parent,count) = let
  val a=glyph_run_association(s,meta,node)
in if a.found andalso ieq(a.owner,parent) then imin(a.component,isub(count,1)) else isub(count,1) end
