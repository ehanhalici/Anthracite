staload "data_font/font.sats"
staload "data_font/font_glyph_id.sats"
staload "core_render/render.sats"
fun id_test_read(f: !Font,r: !Rend,face: FontGlyphFace,glyph: int,errors: &int >> _): gmet
fun id_test_geometry(a: gmet,b: gmet): bool
fun id_test_faces(r: !Rend,latin: string,arabic: string): int
fun id_test_primary(r: !Rend,path: string): int
fun id_test_fallback(r: !Rend,latin: string,arabic: string): int
fun id_test_domains(r: !Rend,latin: string,arabic: string): int
fun id_test_cache(): int
fun id_test_cache_collision(): int
fun id_test_atlas(r: !Rend,path: string): int
