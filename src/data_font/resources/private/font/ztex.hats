fun ztex(): uint = u_zero()

fun u8(b: !Buf, o: int): int =
  if o < 0 then 0 else buf_get(b, o)

fun u16(b: !Buf, o: int): int = u8(b, o) * 256 + u8(b, o + 1)

fun u32(b: !Buf, o: int): int = let
  val hi = u16(b, o)
  val lo = u16(b, o + 2)
in
  anth_u32(hi, lo)
end

fun i16(b: !Buf, o: int): int = let
  val v = u16(b, o)
in
  if v >= WORD16_SIGN_BIT then v - WORD16_MODULUS else v
end

implement font_open() = FONT(@{
  file= buf_make(FONT_OPEN_FILE_INITIAL_BYTES), fb_file= None_vt(), info= sfnt_metadata_empty(), fb_info= sfnt_metadata_empty()
, atlas= buf_make(FONT_ATLAS_WIDTH_PIXELS * FONT_ATLAS_HEIGHT_PIXELS), cache= buf_make(1024 * 12 * 4)
, xs= buf_make(8192 * 4), ys= buf_make(8192 * 4), fl= buf_make(FONT_OPEN_BUFFER_INITIAL_BYTES)
, ends= buf_make(512 * 4), edges= buf_make(FONT_MAX_EDGES * 4 * 4), cov= buf_make(256 * 256)
, px= 16, units= 0, asc= 0, desc= 0, lgap= 0
, num_h= 0, nglyph= 0, loca_fmt= Off
, cmap_off= ~1, glyf_off= ~1, loca_off= ~1, hmtx_off= ~1, kern_off= ~1
, npts= 0, nends= 0, nedges= 0
, pen_x= 1, pen_y= 1, row_h= 0
, aw= FONT_ATLAS_WIDTH_PIXELS, ah= FONT_ATLAS_HEIGHT_PIXELS, tex= ztex()
, has_ttf= Off, line_h= 18, asc_px= 14
, fb_has= Off
, fb_units= 0, fb_cmap= ~1, fb_glyf= ~1, fb_loca= ~1, fb_hmtx= ~1, fb_loca_fmt= Off
, fb_nglyph= 0, fb_num_h= 0
, fb_kern= ~1
, native_primary= None_vt(), native_fallback= None_vt(), native_generation= 0, native_fb_generation= 0
, text_session= None_vt(), registry= font_registry_next()
})

fun release_fallback(file: Option_vt(Buf)): void = case+ file of
  | ~None_vt() => () | ~Some_vt(b) => buf_free(b)

implement font_free(f) = let
  val+~FONT(s) = f
  val () = font_text_session_release(s.text_session)
  val () = font_native_cache_release(s.native_primary)
  val () = font_native_cache_release(s.native_fallback)
  val () = rend_tex_free(s.tex)
  val () = buf_free(s.file)
  val () = release_fallback(s.fb_file)
  val () = buf_free(s.atlas)
  val () = buf_free(s.cache)
  val () = buf_free(s.xs)
  val () = buf_free(s.ys)
  val () = buf_free(s.fl)
  val () = buf_free(s.ends)
  val () = buf_free(s.edges)
in
  buf_free(s.cov)
end

implement font_get_px(f) = case+ f of
  | @FONT(s) => let val value = s.px in fold@(f); value end

implement f_registry(f) = case+ f of
  | @FONT(s) => let val value = s.registry in fold@(f); value end

implement font_get_units(f) = case+ f of
  | @FONT(s) => let val value = s.units in fold@(f); value end

implement font_get_ascender(f) = case+ f of
  | @FONT(s) => let val value = s.asc in fold@(f); value end

implement font_get_descender(f) = case+ f of
  | @FONT(s) => let val value = s.desc in fold@(f); value end

implement font_get_line_gap(f) = case+ f of
  | @FONT(s) => let val value = s.lgap in fold@(f); value end

fun f_get_num_h(f: !Font): int = case+ f of
  | @FONT(s) => let val value = s.num_h in fold@(f); value end

implement font_get_fallback_glyph_count(f) = case+ f of
  | @FONT(s) => let val value=s.fb_nglyph in fold@(f); value end
implement font_get_fallback_units(f) = case+ f of
  | @FONT(s) => let val value=s.fb_units in fold@(f); value end
implement font_get_glyph_count(f) = case+ f of
  | @FONT(s) => let val value = s.nglyph in fold@(f); value end

fun f_get_loca_fmt(f: !Font): Toggle = case+ f of
  | @FONT(s) => let val value = s.loca_fmt in fold@(f); value end

fun f_get_cmap_off(f: !Font): int = case+ f of
  | @FONT(s) => let val value = s.cmap_off in fold@(f); value end

implement font_get_glyf_off(f) = case+ f of
  | @FONT(s) => let val value = s.glyf_off in fold@(f); value end

fun f_get_loca_off(f: !Font): int = case+ f of
  | @FONT(s) => let val value = s.loca_off in fold@(f); value end

fun f_get_hmtx_off(f: !Font): int = case+ f of
  | @FONT(s) => let val value = s.hmtx_off in fold@(f); value end

implement font_get_kern_off(f) = case+ f of
  | @FONT(s) => let val value = s.kern_off in fold@(f); value end

implement font_get_point_count(f) = case+ f of
  | @FONT(s) => let val value = s.npts in fold@(f); value end

implement font_get_contour_count(f) = case+ f of
  | @FONT(s) => let val value = s.nends in fold@(f); value end

implement font_get_edge_count(f) = case+ f of
  | @FONT(s) => let val value = s.nedges in fold@(f); value end

implement font_get_pen_x(f) = case+ f of
  | @FONT(s) => let val value = s.pen_x in fold@(f); value end

implement font_get_pen_y(f) = case+ f of
  | @FONT(s) => let val value = s.pen_y in fold@(f); value end

implement font_get_row_h(f) = case+ f of
  | @FONT(s) => let val value = s.row_h in fold@(f); value end

implement font_set_px_val(f, v) = case+ f of
  | @FONT(s) => let val () = s.px := v in fold@(f) end

implement font_set_units(f, v) = case+ f of
  | @FONT(s) => let val () = s.units := v in fold@(f) end

implement font_set_ascender(f, v) = case+ f of
  | @FONT(s) => let val () = s.asc := v in fold@(f) end

implement font_set_descender(f, v) = case+ f of
  | @FONT(s) => let val () = s.desc := v in fold@(f) end

implement font_set_line_gap(f, v) = case+ f of
  | @FONT(s) => let val () = s.lgap := v in fold@(f) end

implement font_set_horizontal_metric_count(f, v) = case+ f of
  | @FONT(s) => let val () = s.num_h := v in fold@(f) end

implement font_set_glyph_count(f, v) = case+ f of
  | @FONT(s) => let val () = s.nglyph := v in fold@(f) end

implement font_set_loca_fmt(f, v) = case+ f of
  | @FONT(s) => let val () = s.loca_fmt := v in fold@(f) end

fun f_set_cmap_off(f: !Font, v: int): void = case+ f of
  | @FONT(s) => let val () = s.cmap_off := v in fold@(f) end

fun f_set_glyf_off(f: !Font, v: int): void = case+ f of
  | @FONT(s) => let val () = s.glyf_off := v in fold@(f) end

fun f_set_loca_off(f: !Font, v: int): void = case+ f of
  | @FONT(s) => let val () = s.loca_off := v in fold@(f) end

fun f_set_hmtx_off(f: !Font, v: int): void = case+ f of
  | @FONT(s) => let val () = s.hmtx_off := v in fold@(f) end

fun f_set_kern_off(f: !Font, v: int): void = case+ f of
  | @FONT(s) => let val () = s.kern_off := v in fold@(f) end

implement font_set_point_count(f, v) = case+ f of
  | @FONT(s) => let val () = s.npts := v in fold@(f) end

implement font_set_contour_count(f, v) = case+ f of
  | @FONT(s) => let val () = s.nends := v in fold@(f) end

implement font_set_edge_count(f, v) = case+ f of
  | @FONT(s) => let val () = s.nedges := v in fold@(f) end

implement font_set_pen_x(f, v) = case+ f of
  | @FONT(s) => let val () = s.pen_x := v in fold@(f) end

implement font_set_pen_y(f, v) = case+ f of
  | @FONT(s) => let val () = s.pen_y := v in fold@(f) end

implement font_set_row_h(f, v) = case+ f of
  | @FONT(s) => let val () = s.row_h := v in fold@(f) end

implement font_set_has_ttf(f, v) = case+ f of
  | @FONT(s) => let val () = s.has_ttf := v in fold@(f) end

implement font_set_line_h(f, v) = case+ f of
  | @FONT(s) => let val () = s.line_h := v in fold@(f) end

implement font_set_ascender_px(f, v) = case+ f of
  | @FONT(s) => let val () = s.asc_px := v in fold@(f) end

implement font_has_ttf(f) = case+ f of
  | @FONT(s) => let val value = s.has_ttf in fold@(f); value end

implement font_line_h(f) = case+ f of
  | @FONT(s) => let val value = s.line_h in fold@(f); value end

implement font_asc(f) = case+ f of
  | @FONT(s) => let val value = s.asc_px in fold@(f); value end
