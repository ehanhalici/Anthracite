#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/glyph_pass_single.sats"
extern fun frozen_pass(b: !Buf,t: !GsubSingle,run: GlyphRun(3)): GlyphPassResult(1)
implement frozen_pass(b,t,run) = glyph_pass_single(b,t,run,@{kind=GlyphAll(),mask=0u})
