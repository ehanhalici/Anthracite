#include "share/atspre_staload.hats"
staload "data_font/glyph_position_types.sats"
staload "data_font/font_run.sats"
fun illegal(p: !GlyphPositioned(0)): FontRunExtent = font_run_measure(p)
