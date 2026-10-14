#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_cursive_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_anchor.sats"
staload "data_font/glyph_position_cursive_work.sats"
fun difference(a: int,b: int): GlyphCoordinate = glyph_position_checked(g0int2int_int_llint(a)-g0int2int_int_llint(b))
fun changed(p: GlyphPosition,xa: GlyphCoordinate,xo: GlyphCoordinate): GlyphPositionChange =
  glyph_position_change(xa,@{status=PositionReady(),value=p.yAdvance},xo,@{status=PositionReady(),value=p.yOffset},p)
fun joined(a: GlyphPositionChange,c: GlyphPositionChange): GlyphCursiveChange =
  @{status=if glyph_position_ready(a.status) then c.status else a.status,first=a.value,second=c.value}
fun forward(a: GlyphPosition,c: GlyphPosition,exit: GlyphAnchorOffset,entry: GlyphAnchorOffset): GlyphCursiveChange = let
  val xa=glyph_position_sum(exit.x,a.xOffset) and distance=glyph_position_sum(entry.x,c.xOffset)
  val first=changed(a,xa,@{status=PositionReady(),value=a.xOffset})
  val second=changed(c,difference(c.xAdvance,distance.value),difference(c.xOffset,distance.value))
in if not(glyph_position_ready(distance.status)) then @{status=distance.status,first=a,second=c} else joined(first,second) end
fun backward(a: GlyphPosition,c: GlyphPosition,exit: GlyphAnchorOffset,entry: GlyphAnchorOffset): GlyphCursiveChange = let
  val distance=glyph_position_sum(exit.x,a.xOffset)
  val first=changed(a,difference(a.xAdvance,distance.value),difference(a.xOffset,distance.value))
  val second=changed(c,glyph_position_sum(entry.x,c.xOffset),@{status=PositionReady(),value=c.xOffset})
in if not(glyph_position_ready(distance.status)) then @{status=distance.status,first=a,second=c} else joined(first,second) end
implement glyph_position_cursive_main(d,a,c,exit,entry) =
  if not(glyph_position_ready(exit.status)) then @{status=exit.status,first=a,second=c}
  else if not(glyph_position_ready(entry.status)) then @{status=entry.status,first=a,second=c}
  else case+ d of | PositionLTR() => forward(a,c,exit,entry) | PositionRTL() => backward(a,c,exit,entry)
