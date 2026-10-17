implement font_atlas_w(f) = case+ f of
  | @FONT(s) => let val value = s.aw in fold@(f); value end

implement font_atlas_h(f) = case+ f of
  | @FONT(s) => let val value = s.ah in fold@(f); value end

implement font_tex(f) =
  case+ f of
  | @FONT(s) => let
      val t = s.tex
    in
      fold@(f); t
    end


implement put_file(f, b) =
  case+ f of
  | @FONT(s) => let
      val () = font_native_cache_reset(s.native_primary)
      val () = s.native_generation := font_native_generation_next(s.native_generation)
      val old = s.file
      val () = s.file := b
      val () = fold@(f)
    in
      buf_free(old)
    end

implement file_u8(f, o) =
  case+ f of
  | @FONT(s) => let
      val v = u8(s.file, o)
    in
      fold@(f); v
    end

implement file_u16(f, o) =
  case+ f of
  | @FONT(s) => let
      val v = u16(s.file, o)
    in
      fold@(f); v
    end

fun file_u32(f: !Font, o: int): int =
  case+ f of
  | @FONT(s) => let
      val v = u32(s.file, o)
    in
      fold@(f); v
    end

implement file_i16(f, o) =
  case+ f of
  | @FONT(s) => let
      val v = i16(s.file, o)
    in
      fold@(f); v
    end


implement clear_atlas(f) =
  case+ f of
  | @FONT(s) => let
      val () = buf_zero(s.atlas)
      val () = s.pen_x := 1
      val () = s.pen_y := 1
      val () = s.row_h := 0
    in
      fold@(f)
    end


fun optional_offset(table: SfntOptional): int = case+ table of
  | NoSfntTable() => ~1 | HasSfntTable(span) => span.offset

implement install_face_tables(f, info) = case+ f of
  | @FONT(s) => let
      val () = s.info := Some(info)
      val () = s.cmap_off := optional_offset(sfnt_table(s.file,info.tables,TableCmap()))
      val () = s.glyf_off := info.glyf.offset
      val () = s.loca_off := info.loca.offset
      val () = s.hmtx_off := info.hmtx.offset
      val () = s.kern_off := optional_offset(sfnt_table(s.file,info.tables,TableKern()))
    in fold@(f) end

fun swap_fb_loca(f: !Font): void =
  case+ f of
  | @FONT(s) => let
      val tl = s.loca_off; val () = s.loca_off := s.fb_loca; val () = s.fb_loca := tl
      val th = s.hmtx_off; val () = s.hmtx_off := s.fb_hmtx; val () = s.fb_hmtx := th
      val tfmt = s.loca_fmt; val () = s.loca_fmt := s.fb_loca_fmt; val () = s.fb_loca_fmt := tfmt
      val tng = s.nglyph; val () = s.nglyph := s.fb_nglyph; val () = s.fb_nglyph := tng
      val tnh = s.num_h; val () = s.num_h := s.fb_num_h; val () = s.fb_num_h := tnh
    in
      fold@(f)
    end

extern fun missing_fallback(): Buf = "mac#anth_die_box"

fun fallback_source(file: Option_vt(Buf)): Buf = case+ file of
  | ~Some_vt(b) => b | ~None_vt() => missing_fallback()

fun swap_fb_source(f: !Font): void = case+ f of
  | @FONT(s) => let
      val fb = s.fb_file
      val source = fallback_source(fb)
      val previous = s.file
      val () = s.file := source
      val () = s.fb_file := Some_vt(previous)
      val ti = s.info; val () = s.info := s.fb_info; val () = s.fb_info := ti
      val tk = s.kern_off; val () = s.kern_off := s.fb_kern; val () = s.fb_kern := tk
    in fold@(f) end

implement swap_fb(f) = let
  val () = swap_fb_source(f)
in
  case+ f of
  | @FONT(s) => let
      val tu = s.units
      val () = s.units := s.fb_units
      val () = s.fb_units := tu
      val tc = s.cmap_off
      val () = s.cmap_off := s.fb_cmap
      val () = s.fb_cmap := tc
      val tg = s.glyf_off
      val () = s.glyf_off := s.fb_glyf
      val () = s.fb_glyf := tg
      val () = fold@(f)
    in
      swap_fb_loca(f)
    end
end


implement install_fallback(f, b, info) = case+ f of
  | @FONT(s) => let
      val () = font_native_cache_reset(s.native_fallback)
      val () = s.native_fb_generation := font_native_generation_next(s.native_fb_generation)
      val cmap = optional_offset(sfnt_table(b,info.tables,TableCmap()))
      val kern = optional_offset(sfnt_table(b,info.tables,TableKern()))
      val old = s.fb_file; val () = s.fb_file := Some_vt(b)
      val () = s.fb_info := Some(info)
      val () = s.fb_units := info.units
      val () = s.fb_loca_fmt := toggle_of(info.long_loca)
      val () = s.fb_cmap := cmap
      val () = s.fb_kern := kern
      val () = s.fb_glyf := info.glyf.offset
      val () = s.fb_loca := info.loca.offset
      val () = s.fb_hmtx := info.hmtx.offset
      val () = s.fb_nglyph := info.glyphs
      val () = s.fb_num_h := info.hmetrics
      val () = s.fb_has := On
      val () = fold@(f)
    in release_fallback(old) end

implement font_has_fb(f) =
  case+ f of
  | @FONT(s) => let
      val h = is_on(s.fb_has)
    in
      fold@(f); h
    end

implement drop_tex(f) =
  case+ f of
  | @FONT(s) => let
      val t = s.tex
      val () = s.tex := ztex()
      val () = fold@(f)
    in
      rend_tex_free(t)
    end

implement cmap_gid(f, cp) = case+ f of
  | @FONT(s) => let
      val gid = case+ s.info of | None() => 0 | Some(info) => sfnt_map(s.file,info,cp)
    in fold@(f); gid end

implement loca_at(f, gid) = let
  val off = f_get_loca_off(f)
  val fmt = f_get_loca_fmt(f)
in
  if off < 0 orelse gid < 0 then 0
  else if is_off(fmt) then file_u16(f, off + gid * 2) * 2
  else file_u32(f, off + gid * 4)
end

implement hmtx_adv(f, gid) = case+ f of
  | @FONT(s) => let
      val advance = case+ s.info of
        | None() => 0 | Some(info) => let val metric = sfnt_metrics(s.file,info,gid) in metric.advance end
    in fold@(f); advance end


implement pt_set(f, i, x, y, on) = let
  val () =
    case+ f of
    | @FONT(s) => let
        val () = buf_set32(s.xs, i, x)
        val () = buf_set32(s.ys, i, y)
        val () = buf_set(s.fl, i, on)
      in
        fold@(f)
      end
in
end

