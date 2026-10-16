#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup_types.sats"
staload "data_font/glyph/pass/glyph_pass_ligature_work.sats"
staload "data_font/glyph/pass/glyph_pass_ligation.sats"
implement glyph_pass_ligation(b,t,m,run,selection) = let
  val+ ~GlyphRun(phase,meta,s)=run
  val+ OtLigationLookup(h,glyphs,maximum,rows)=t
  val status=glyph_ligature_check(m,meta,glyphs,h.flags,h.markSet,h.count)
in case+ status of | GlyphPassApplied() => glyph_ligature_apply(b,rows,maximum,m,phase,meta,s,h.flags,h.markSet,selection)
  | GlyphPassDomain() => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0)
  | GlyphPassReference() => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0)
  | GlyphPassCapacity() => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0) end
