#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/glyph/core/glyph_expansion_types.sats"
staload "data_font/glyph/core/glyph_expansion_work.sats"
fun illegal(t: !GlyphExpansionPlan(2,1)): GlyphExpansion = glyph_expansion_get(t,0)
