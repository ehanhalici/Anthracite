#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/pass/glyph_pass_work.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
staload "data_font/glyph/pass/glyph_pass_ligature.sats"
staload "data_font/glyph/pass/glyph_pass_ligature_work.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup_types.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup_work.sats"
fun commit{n,k:nat}(phase: GlyphRunPhase(1),original: GlyphStorage(n),scratch: GlyphStorage(k),old: GlyphRunMeta,
  updated: GlyphRunMeta,status: GlyphPassStatus,visited: int,matches: int): GlyphPassResult(1) = case+ status of
  | GlyphPassApplied() => let val ()=glyph_storage_dispose(original)
    in GlyphPassResult(GlyphRun(phase,updated,scratch),status,visited,matches) end
  | GlyphPassDomain() => let val ()=glyph_storage_dispose(scratch) in GlyphPassResult(GlyphRun(phase,old,original),status,0,0) end
  | GlyphPassReference() => let val ()=glyph_storage_dispose(scratch) in GlyphPassResult(GlyphRun(phase,old,original),status,0,0) end
  | GlyphPassCapacity() => let val ()=glyph_storage_dispose(scratch) in GlyphPassResult(GlyphRun(phase,old,original),status,0,0) end
implement glyph_ligature_apply(b,t,maximum,m,phase,meta,s,f,set,selection) = let
  val count=glyph_storage_count(s)
  val scratch=glyph_storage_make(count)
  val ()=glyph_storage_copy(s,scratch,meta.used)
  val glyphs=buf_make(imul(imax(maximum,1),4)) and nodes=buf_make(imul(imax(maximum,1),4))
  val weights=buf_make(imul(imax(maximum,1),4))
  var updated: GlyphRunMeta=meta and visited: int=0 and matches: int=0
  val status=glyph_ligature_walk(b,t,m,scratch,updated,f,set,selection,glyphs,nodes,weights,visited,matches)
  val ()=buf_free(glyphs) and ()=buf_free(nodes) and ()=buf_free(weights)
in commit(phase,s,scratch,meta,updated,status,visited,matches) end
implement glyph_ligature_check(m,meta,glyphs,f,set,count) = let
  val props=glyph_metadata_info(m)
  val status=glyph_pass_domain_check(meta,m,glyphs,f,set,count)
in case+ status of | GlyphPassApplied() => if props.classes then status else GlyphPassReference()
  | GlyphPassDomain() => status | GlyphPassReference() => status | GlyphPassCapacity() => status end
implement glyph_pass_ligature(b,t,m,run,f,set,selection) = let
  val+ ~GlyphRun(phase,meta,s)=run
  val+ GsubLigatures(info)=t
  val status=glyph_ligature_check(m,meta,info.glyphs,f,set,1)
in case+ status of | GlyphPassApplied() => let val tables=ot_ligation_tables_append(ot_ligation_tables_make(1),info)
    val result=glyph_ligature_apply(b,tables,info.maximum,m,phase,meta,s,f,set,selection)
    val ()=ot_ligation_tables_dispose(tables)
  in result end
  | GlyphPassDomain() => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0)
  | GlyphPassReference() => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0)
  | GlyphPassCapacity() => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0) end
