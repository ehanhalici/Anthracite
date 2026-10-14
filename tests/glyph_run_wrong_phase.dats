#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
extern fun frozen_substitution(run: GlyphRun(3)): GlyphRunEdit(1)
implement frozen_substitution(run) = glyph_run_single(run,0,1)
