#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/glyph/pass/glyph_pass_work.sats"
implement glyph_pass_selected(selection,mask) = case+ selection.kind of
  | GlyphAll() => true | GlyphMasked() => (mask land selection.mask) != 0u
