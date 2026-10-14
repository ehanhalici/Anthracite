#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
implement glyph_run_clone(run) = let val+ GlyphRun(phase,meta,source)=run
  val target=glyph_storage_make(glyph_storage_count(source))
  val ()=glyph_storage_copy(source,target,meta.used)
in GlyphRun(phase,meta,target) end
