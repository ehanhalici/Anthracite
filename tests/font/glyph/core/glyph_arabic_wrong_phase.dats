#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_arabic.sats"
extern fun late_joining(map: !PropertyMap(3),plan: !ArabicMaskPlan,run: GlyphRun(1)): GlyphRun(1)
implement late_joining(map,plan,run) =
  glyph_arabic_prepare(map,plan,@{before=BoundaryNone(),after=BoundaryNone()},run)
