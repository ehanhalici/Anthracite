#include "share/atspre_staload.hats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position.sats"
fun illegal(p: GlyphPositioned(1)): GlyphPositionFinished = glyph_position_finish(p,PositionLTR())
