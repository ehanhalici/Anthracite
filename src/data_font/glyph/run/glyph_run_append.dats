#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
implement glyph_run_append(run,seed) = let val+ ~GlyphRun(phase,meta,s)=run in
  if not(glyph_run_glyph(meta,seed.glyph)) then GlyphRunEdited(GlyphRun(phase,meta,s),GlyphDomain(),~1)
  else if not(glyph_run_seed(meta,seed)) then GlyphRunEdited(GlyphRun(phase,meta,s),GlyphSource(),~1)
  else if meta.used >= glyph_storage_count(s) then GlyphRunEdited(GlyphRun(phase,meta,s),GlyphCapacity(),~1) else let
    val node=meta.used
    val ()=glyph_run_initial(s,node,glyph_run_seed_core(seed),meta.tail,~1)
    val ()=glyph_run_next(s,meta.tail,node)
    val next: GlyphRunMeta= @{used=iadd(meta.used,1),live=iadd(meta.live,1),head=if ieq(meta.head,~1) then node else meta.head,
      tail=node,font=meta.font,glyphs=meta.glyphs,sourceLength=meta.sourceLength,nextLigature=meta.nextLigature,properties=GlyphSourceRaw()}
  in GlyphRunEdited(GlyphRun(phase,next,s),GlyphUpdated(),node) end end
