staload "data_font/font.sats"
staload "data_font/font_glyph_id.sats"
staload "data_font/glyph_position_types.sats"
staload "core_render/render.sats"
datatype FontRunStatus = FontRunReady | FontRunFace | FontRunScale | FontRunOverflow | FontRunRaster | FontRunGraph
typedef FontRunExtent = @{status=FontRunStatus,xAdvance=int,yAdvance=int,drawn=int}
typedef FontRunBinding = @{face=FontGlyphFace,font=int}
(* Frozen, scaled runs only. Coordinates/advances in the result are 26.6;
   x/baseline are device pixels. The caller keeps the exact face bytes fixed
   between shaping and drawing; font is that caller's face registry ID.
   No cmap lookup, extra kerning, normalization, BiDi or shaping occurs here. *)
fun font_run_measure(positioned: !GlyphPositioned(1)): FontRunExtent
fun font_draw_positioned(f: !Font,r: !Rend,positioned: !GlyphPositioned(1),binding: FontRunBinding,
  x: double,baseline: double,color: uint): FontRunExtent
