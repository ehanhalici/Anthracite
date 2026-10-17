staload "mem.sats"
staload "data_font/resources/font.sats"
staload "data_font/atlas/font_glyph_id.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/sfnt/sfnt.sats"
staload "core_render/render.sats"
fun run_render_test_run(face: !SfntFace,a: int,c: int,d: GlyphPositionDirection): GlyphPositioned(1)
fun run_render_test_reference(f: !Font,r: !Rend,p: !GlyphPositioned(1),face: FontGlyphFace,d: GlyphPositionDirection,errors: &int >> _): Buf
fun run_render_test_compare(a: !Buf,b: !Buf): int
fun run_render_test_faces(r: !Rend,latin: string,arabic: string): int
