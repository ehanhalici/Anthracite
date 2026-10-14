#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_run_work.sats"
fun accepted {n:nat}(phase: GlyphRunPhase(1),meta: GlyphRunMeta,s: GlyphStorage(n),
  nodes: !Buf,count: int,glyph: int): GlyphRunEdit(1) =
  if ieq(count,1) then glyph_run_single(GlyphRun(phase,meta,s),buf_get32(nodes,0),glyph) else let
    val ()=glyph_run_cluster_merge(s,meta,nodes,count)
    val updated=glyph_run_merge(s,meta,nodes,count,glyph)
  in GlyphRunEdited(GlyphRun(phase,updated,s),GlyphUpdated(),buf_get32(nodes,0)) end
implement glyph_run_ligate(run,nodes,count,glyph) = let val+ ~GlyphRun(phase,meta,s)=run in
  if not(glyph_run_glyph(meta,glyph)) then GlyphRunEdited(GlyphRun(phase,meta,s),GlyphDomain(),~1) else
    case+ glyph_run_selection(s,meta,nodes,count) of
    | GlyphUpdated() => accepted(phase,meta,s,nodes,count,glyph)
    | GlyphUnchanged() => GlyphRunEdited(GlyphRun(phase,meta,s),GlyphUnchanged(),~1)
    | GlyphCapacity() => GlyphRunEdited(GlyphRun(phase,meta,s),GlyphCapacity(),~1)
    | GlyphNode() => GlyphRunEdited(GlyphRun(phase,meta,s),GlyphNode(),~1)
    | GlyphDomain() => GlyphRunEdited(GlyphRun(phase,meta,s),GlyphDomain(),~1)
    | GlyphSource() => GlyphRunEdited(GlyphRun(phase,meta,s),GlyphSource(),~1)
    | GlyphOrder() => GlyphRunEdited(GlyphRun(phase,meta,s),GlyphOrder(),~1)
    | GlyphAssociationError() => GlyphRunEdited(GlyphRun(phase,meta,s),GlyphAssociationError(),~1)
    | GlyphOverflow() => GlyphRunEdited(GlyphRun(phase,meta,s),GlyphOverflow(),~1) end
