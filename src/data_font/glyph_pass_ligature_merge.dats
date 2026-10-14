#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/glyph_pass_ligature_work.sats"
fun policy(kind: GlyphLigatureKind): GlyphMergeKind = case+ kind of
  | LigatureCompound() => MergeLigature() | LigatureMarks() => MergeAssociation() | LigatureBaseMarks() => MergeAssociation()
implement glyph_ligature_merge(s,meta,nodes,weights,count,glyph,kind) =
  if ieq(count,1) then let val node=buf_get32(nodes,0) val old=glyph_storage_core(s,node)
    val ()=glyph_storage_set_core(s,node,glyph_run_new_glyph(old,glyph))
  in meta end else let
    val ()=case+ kind of | LigatureCompound() => glyph_ligature_bind(s,meta,nodes,weights,count)
      | LigatureMarks() => () | LigatureBaseMarks() => ()
    val ()=glyph_run_cluster_merge(s,meta,nodes,count)
  in glyph_run_merge_counted(s,meta,nodes,weights,count,glyph,policy(kind)) end
