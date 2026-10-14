#include "data_font/glyph_position_schedule_internal.hats"
fun illegal(b: !Buf,g: !OtPositionGraph,s: !OtShapeSchedule(1),m: !GlyphMetadata,p: GlyphPositioned(0)): GlyphPositionStageResult =
  glyph_position_schedule_apply(b,g,s,m,p,PositionRTL())

