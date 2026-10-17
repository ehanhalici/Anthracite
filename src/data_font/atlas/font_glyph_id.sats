staload "data_font/resources/font.sats"
staload "core_render/render.sats"
datatype FontGlyphFace = GlyphPrimaryFace | GlyphFallbackFace
datatype FontGlyphStatus = GlyphRasterReady | GlyphRasterUnavailable | GlyphRasterDomain
(* IDs belong to the selected face, not Unicode. Glyph 0 is a valid .notdef
   request; no cmap, legacy kerning or character fallback is applied here.
   The caller keeps face and size fixed while consuming atlas coordinates. *)
fun font_glyph_id(f: !Font,r: !Rend,face: FontGlyphFace,glyph: int,g: &gmet >> _): FontGlyphStatus
