(* Private capability contract: Font resource ownership and private storage access. *)
staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"

fun font_get_px(f: !Font): int
fun f_registry(f: !Font): int
fun font_get_units(f: !Font): int
fun font_get_ascender(f: !Font): int
fun font_get_descender(f: !Font): int
fun font_get_line_gap(f: !Font): int
fun font_get_glyph_count(f: !Font): int
fun font_get_fallback_glyph_count(f: !Font): int
fun font_get_fallback_units(f: !Font): int
fun font_get_glyf_off(f: !Font): int
fun font_get_kern_off(f: !Font): int
fun font_get_point_count(f: !Font): int
fun font_get_contour_count(f: !Font): int
fun font_get_edge_count(f: !Font): int
fun font_get_pen_x(f: !Font): int
fun font_get_pen_y(f: !Font): int
fun font_get_row_h(f: !Font): int
fun font_set_px_val(f: !Font, v: int): void
fun font_set_units(f: !Font, v: int): void
fun font_set_ascender(f: !Font, v: int): void
fun font_set_descender(f: !Font, v: int): void
fun font_set_line_gap(f: !Font, v: int): void
fun font_set_horizontal_metric_count(f: !Font, v: int): void
fun font_set_glyph_count(f: !Font, v: int): void
fun font_set_loca_fmt(f: !Font, v: Toggle): void
fun font_set_point_count(f: !Font, v: int): void
fun font_set_contour_count(f: !Font, v: int): void
fun font_set_edge_count(f: !Font, v: int): void
fun font_set_pen_x(f: !Font, v: int): void
fun font_set_pen_y(f: !Font, v: int): void
fun font_set_row_h(f: !Font, v: int): void
fun font_set_has_ttf(f: !Font, v: Toggle): void
fun font_set_line_h(f: !Font, v: int): void
fun font_set_ascender_px(f: !Font, v: int): void
fun put_file(f: !Font, b: Buf): void
fun file_u8(f: !Font, o: int): int
fun file_u16(f: !Font, o: int): int
fun file_i16(f: !Font, o: int): int
fun clear_atlas(f: !Font): void
fun install_face_tables(f: !Font, info: SfntInfo): void
fun swap_fb(f: !Font): void
fun install_fallback(f: !Font, b: Buf, info: SfntInfo): void
fun font_has_fb(f: !Font): bool
fun drop_tex(f: !Font): void
fun cmap_gid(f: !Font, cp: int): int
fun loca_at(f: !Font, gid: int): int
fun hmtx_adv(f: !Font, gid: int): int
fun pt_set(f: !Font, i: int, x: int, y: int, on: int): void
fun pt_x(f: !Font, i: int): int
fun pt_y(f: !Font, i: int): int
fun pt_on(f: !Font, i: int): int
fun end_set(f: !Font, i: int, v: int): void
fun end_get(f: !Font, i: int): int
fun edge_push(f: !Font, x0: int, y0: int, x1: int, y1: int): void
fun edge_get(f: !Font, e: int, k: int): int
fun set_x(f: !Font, i: int, x: int): void
fun set_fl(f: !Font, i: int, v: int): void
fun component_at(f: !Font, span: SfntSpan, p: int): ComponentRead
fun zero_cov(f: !Font): void
fun cov_set(f: !Font, i: int, v: int): void
fun cov_get(f: !Font, i: int): int
fun atlas_set(f: !Font, x: int, y: int, v: int): void
fun atlas_get(f: !Font, x: int, y: int): int
fun cache_i(f: !Font, slot: int, k: int): int
fun cache_s(f: !Font, slot: int, k: int, v: int): void
fun ensure_tex(f: !Font, r: !Rend): void
fun upload_atlas(f: !Font, r: !Rend, tex: uint, x: int, y: int, w: int, h: int): void
fun kern_fmt0_value(f: !Font, p: int, left: int, right: int): int
