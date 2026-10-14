#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_render/gl.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"
staload "data_font/sfnt.sats"
staload "data_font/glyph_component.sats"
staload "data_text/text_source.sats"
staload "data_font/font_glyph_id.sats"
staload "data_font/native_shape_types.sats"
staload "data_font/font_native_types.sats"
staload "data_font/font_native.sats"
staload "data_font/private/font_native_owner.sats"
staload "data_font/font_text_types.sats"
staload "data_font/font_text.sats"
staload "data_font/private/font_text_owner.sats"


#define AW 1024
#define AH 1024
#define MAXP 3000
#define OUT0 3200
#define MAXE 10000

datavtype Font_ = FONT of @{
  file= Buf, fb_file= Option_vt(Buf), info= Option(SfntInfo), fb_info= Option(SfntInfo), atlas= Buf, cache= Buf
, xs= Buf, ys= Buf, fl= Buf, ends= Buf, edges= Buf, cov= Buf
, px= int, units= int, asc= int, desc= int, lgap= int
, num_h= int, nglyph= int, loca_fmt= Toggle
, cmap_off= int, glyf_off= int, loca_off= int, hmtx_off= int, kern_off= int
, npts= int, nends= int, nedges= int
, pen_x= int, pen_y= int, row_h= int
, aw= int, ah= int, tex= uint
, has_ttf= Toggle, line_h= int, asc_px= int
, fb_has= Toggle
, fb_units= int, fb_cmap= int, fb_glyf= int, fb_loca= int, fb_hmtx= int, fb_loca_fmt= Toggle
, fb_nglyph= int, fb_num_h= int
, fb_kern= int
, native_primary= Option_vt(NativeShapeCache), native_fallback= Option_vt(NativeShapeCache)
, native_generation= int, native_fb_generation= int
, text_session= Option_vt(FontTextSession)
}
(* skill.md 1. kural istisnasi: ATS2 soyut tip gerceklemesi (sats'taki absviewtype). Kanit disi cast veya ham C yoktur. *)
assume Font = Font_


(* Font resource ownership and private storage access. *)
staload "data_font/private/font_legacy_pairs.sats"
staload "data_font/private/font_storage.sats"

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
  if v >= 32768 then v - 65536 else v
end

implement font_open() = FONT(@{
  file= buf_make(1), fb_file= None_vt(), info= None(), fb_info= None()
, atlas= buf_make(AW * AH), cache= buf_make(1024 * 12 * 4)
, xs= buf_make(8192 * 4), ys= buf_make(8192 * 4), fl= buf_make(8192)
, ends= buf_make(512 * 4), edges= buf_make(MAXE * 4 * 4), cov= buf_make(256 * 256)
, px= 16, units= 0, asc= 0, desc= 0, lgap= 0
, num_h= 0, nglyph= 0, loca_fmt= Off
, cmap_off= ~1, glyf_off= ~1, loca_off= ~1, hmtx_off= ~1, kern_off= ~1
, npts= 0, nends= 0, nedges= 0
, pen_x= 1, pen_y= 1, row_h= 0
, aw= AW, ah= AH, tex= ztex()
, has_ttf= Off, line_h= 18, asc_px= 14
, fb_has= Off
, fb_units= 0, fb_cmap= ~1, fb_glyf= ~1, fb_loca= ~1, fb_hmtx= ~1, fb_loca_fmt= Off
, fb_nglyph= 0, fb_num_h= 0
, fb_kern= ~1
, native_primary= None_vt(), native_fallback= None_vt(), native_generation= 0, native_fb_generation= 0
, text_session= None_vt()
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

implement f_get_px(f) = case+ f of
  | @FONT(s) => let val value = s.px in fold@(f); value end

implement f_get_units(f) = case+ f of
  | @FONT(s) => let val value = s.units in fold@(f); value end

implement f_get_asc(f) = case+ f of
  | @FONT(s) => let val value = s.asc in fold@(f); value end

implement f_get_desc(f) = case+ f of
  | @FONT(s) => let val value = s.desc in fold@(f); value end

implement f_get_lgap(f) = case+ f of
  | @FONT(s) => let val value = s.lgap in fold@(f); value end

fun f_get_num_h(f: !Font): int = case+ f of
  | @FONT(s) => let val value = s.num_h in fold@(f); value end

implement f_get_fb_nglyph(f) = case+ f of
  | @FONT(s) => let val value=s.fb_nglyph in fold@(f); value end
implement f_get_fb_units(f) = case+ f of
  | @FONT(s) => let val value=s.fb_units in fold@(f); value end
implement f_get_nglyph(f) = case+ f of
  | @FONT(s) => let val value = s.nglyph in fold@(f); value end

fun f_get_loca_fmt(f: !Font): Toggle = case+ f of
  | @FONT(s) => let val value = s.loca_fmt in fold@(f); value end

fun f_get_cmap_off(f: !Font): int = case+ f of
  | @FONT(s) => let val value = s.cmap_off in fold@(f); value end

implement f_get_glyf_off(f) = case+ f of
  | @FONT(s) => let val value = s.glyf_off in fold@(f); value end

fun f_get_loca_off(f: !Font): int = case+ f of
  | @FONT(s) => let val value = s.loca_off in fold@(f); value end

fun f_get_hmtx_off(f: !Font): int = case+ f of
  | @FONT(s) => let val value = s.hmtx_off in fold@(f); value end

implement f_get_kern_off(f) = case+ f of
  | @FONT(s) => let val value = s.kern_off in fold@(f); value end

implement f_get_npts(f) = case+ f of
  | @FONT(s) => let val value = s.npts in fold@(f); value end

implement f_get_nends(f) = case+ f of
  | @FONT(s) => let val value = s.nends in fold@(f); value end

implement f_get_nedges(f) = case+ f of
  | @FONT(s) => let val value = s.nedges in fold@(f); value end

implement f_get_pen_x(f) = case+ f of
  | @FONT(s) => let val value = s.pen_x in fold@(f); value end

implement f_get_pen_y(f) = case+ f of
  | @FONT(s) => let val value = s.pen_y in fold@(f); value end

implement f_get_row_h(f) = case+ f of
  | @FONT(s) => let val value = s.row_h in fold@(f); value end

implement f_set_px_val(f, v) = case+ f of
  | @FONT(s) => let val () = s.px := v in fold@(f) end

implement f_set_units(f, v) = case+ f of
  | @FONT(s) => let val () = s.units := v in fold@(f) end

implement f_set_asc(f, v) = case+ f of
  | @FONT(s) => let val () = s.asc := v in fold@(f) end

implement f_set_desc(f, v) = case+ f of
  | @FONT(s) => let val () = s.desc := v in fold@(f) end

implement f_set_lgap(f, v) = case+ f of
  | @FONT(s) => let val () = s.lgap := v in fold@(f) end

implement f_set_num_h(f, v) = case+ f of
  | @FONT(s) => let val () = s.num_h := v in fold@(f) end

implement f_set_nglyph(f, v) = case+ f of
  | @FONT(s) => let val () = s.nglyph := v in fold@(f) end

implement f_set_loca_fmt(f, v) = case+ f of
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

implement f_set_npts(f, v) = case+ f of
  | @FONT(s) => let val () = s.npts := v in fold@(f) end

implement f_set_nends(f, v) = case+ f of
  | @FONT(s) => let val () = s.nends := v in fold@(f) end

implement f_set_nedges(f, v) = case+ f of
  | @FONT(s) => let val () = s.nedges := v in fold@(f) end

implement f_set_pen_x(f, v) = case+ f of
  | @FONT(s) => let val () = s.pen_x := v in fold@(f) end

implement f_set_pen_y(f, v) = case+ f of
  | @FONT(s) => let val () = s.pen_y := v in fold@(f) end

implement f_set_row_h(f, v) = case+ f of
  | @FONT(s) => let val () = s.row_h := v in fold@(f) end

implement f_set_has_ttf(f, v) = case+ f of
  | @FONT(s) => let val () = s.has_ttf := v in fold@(f) end

implement f_set_line_h(f, v) = case+ f of
  | @FONT(s) => let val () = s.line_h := v in fold@(f) end

implement f_set_asc_px(f, v) = case+ f of
  | @FONT(s) => let val () = s.asc_px := v in fold@(f) end

implement font_has_ttf(f) = case+ f of
  | @FONT(s) => let val value = s.has_ttf in fold@(f); value end

implement font_line_h(f) = case+ f of
  | @FONT(s) => let val value = s.line_h in fold@(f); value end

implement font_asc(f) = case+ f of
  | @FONT(s) => let val value = s.asc_px in fold@(f); value end

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

implement pt_x(f, i) =
  case+ f of
  | @FONT(s) => let
      val v = buf_get32(s.xs, i)
    in
      fold@(f); v
    end

implement pt_y(f, i) =
  case+ f of
  | @FONT(s) => let
      val v = buf_get32(s.ys, i)
    in
      fold@(f); v
    end

implement pt_on(f, i) =
  case+ f of
  | @FONT(s) => let
      val v = buf_get(s.fl, i)
    in
      fold@(f); v
    end

implement end_set(f, i, v) =
  case+ f of
  | @FONT(s) => let
      val () = buf_set32(s.ends, i, v)
    in
      fold@(f)
    end

implement end_get(f, i) =
  case+ f of
  | @FONT(s) => let
      val v = buf_get32(s.ends, i)
    in
      fold@(f); v
    end

fun edge_store(f: !Font, n: int, x0: int, y0: int, x1: int, y1: int): void =
  case+ f of
  | @FONT(s) => let
      val b = n * 4
      val () = buf_set32(s.edges, b, x0)
      val () = buf_set32(s.edges, b + 1, y0)
      val () = buf_set32(s.edges, b + 2, x1)
      val () = buf_set32(s.edges, b + 3, y1)
      val () = s.nedges := n + 1
    in
      fold@(f)
    end

implement edge_push(f, x0, y0, x1, y1) =
  if x0 = x1 andalso y0 = y1 then ()
  else let
    val n = f_get_nedges(f)
  in
    if n >= MAXE then ()
    else edge_store(f, n, x0, y0, x1, y1)
  end

implement edge_get(f, e, k) =
  case+ f of
  | @FONT(s) => let
      val v = buf_get32(s.edges, e * 4 + k)
    in
      fold@(f); v
    end

implement set_x(f, i, x) =
  case+ f of
  | @FONT(s) => let
      val () = buf_set32(s.xs, i, x)
    in
      fold@(f)
    end


implement set_fl(f, i, v) =
  case+ f of
  | @FONT(s) => let
      val () = buf_set(s.fl, i, v)
    in
      fold@(f)
    end

implement component_at(f, span, p) = case+ f of
  | @FONT(s) => let
      val result = glyph_component_read(s.file,span,p,s.nglyph)
    in fold@(f); result end

implement zero_cov(f) =
  case+ f of
  | @FONT(s) => let
      val () = buf_zero(s.cov)
    in
      fold@(f)
    end

implement cov_set(f, i, v) =
  case+ f of
  | @FONT(s) => let
      val () = if i >= 0 then buf_set(s.cov, i, v) else ()
    in
      fold@(f)
    end

implement cov_get(f, i) =
  case+ f of
  | @FONT(s) => let
      val v = if i >= 0 then buf_get(s.cov, i) else 0
    in
      fold@(f); v
    end

implement atlas_set(f, x, y, v) =
  case+ f of
  | @FONT(s) => let
      val () = if x >= 0 andalso y >= 0 andalso x < s.aw andalso y < s.ah then buf_set(s.atlas, y * s.aw + x, v) else ()
    in
      fold@(f)
    end

implement atlas_get(f, x, y) =
  case+ f of
  | @FONT(s) => let
      val v = if x >= 0 andalso y >= 0 andalso x < s.aw andalso y < s.ah then buf_get(s.atlas, y * s.aw + x) else 0
    in
      fold@(f); v
    end

implement cache_i(f, slot, k) =
  case+ f of
  | @FONT(s) => let
      val v = buf_get32(s.cache, slot * 12 + k)
    in
      fold@(f); v
    end

implement cache_s(f, slot, k, v) =
  case+ f of
  | @FONT(s) => let
      val () = buf_set32(s.cache, slot * 12 + k, v)
    in
      fold@(f)
    end

implement ensure_tex(f, r) =
  case+ f of
  | @FONT(s) => let
      val t0 = s.tex
      val t = if t0 = ztex() then rend_tex_r8(r, t0, s.aw, s.ah) else t0
      val () = s.tex := t
    in
      fold@(f)
    end

implement upload_atlas(f, r, tex, x, y, w, h) =
  case+ f of
  | @FONT(s) => let
      val () = glPixelStorei(GL_UNPACK_ROW_LENGTH, s.aw)
      val () = rend_tex_sub_buf(r, tex, x, y, w, h, s.atlas, y * s.aw + x)
      val () = glPixelStorei(GL_UNPACK_ROW_LENGTH, 0)
    in
      fold@(f)
    end

implement kern_fmt0_value(f, p, left, right) = let
  val np = file_u16(f, iadd(p, 6))
in
  case+ f of
  | @FONT(s) => let
      val k = kern_search(s.file, iadd(p, 14), np, left, right, 0, np)
    in
      fold@(f); k
    end
end

#include "data_font/private/font_native_binding_impl.hats"
staload "data_font/font_document_metrics.sats"
#include "data_font/private/font_document_metrics_impl.hats"
#include "data_font/private/font_native_shape_impl.hats"
#include "data_font/private/font_native_coverage_impl.hats"
#include "data_font/private/font_text_owner_impl.hats"
