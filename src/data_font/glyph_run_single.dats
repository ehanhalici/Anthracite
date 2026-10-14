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
implement glyph_run_single(run,node,glyph) = let val+ ~GlyphRun(phase,meta,s)=run in
  if not(glyph_run_node(s,meta,node)) then GlyphRunEdited(GlyphRun(phase,meta,s),GlyphNode(),~1)
  else if not(glyph_run_glyph(meta,glyph)) then GlyphRunEdited(GlyphRun(phase,meta,s),GlyphDomain(),~1) else let
    val old=glyph_storage_core(s,node)
    val ()=glyph_storage_set_core(s,node,glyph_run_new_glyph(old,glyph))
  in GlyphRunEdited(GlyphRun(phase,meta,s),GlyphUpdated(),node) end end
