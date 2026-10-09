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

#define AW 1024
#define AH 1024
#define MAXP 3000
#define OUT0 3200
#define MAXE 10000

datavtype Font_ = FONT of @{
  file= Buf, atlas= Buf, cache= Buf
, xs= Buf, ys= Buf, fl= Buf, ends= Buf, edges= Buf, cov= Buf
, px= int, units= int, asc= int, desc= int, lgap= int
, num_h= int, nglyph= int, loca_fmt= Toggle
, cmap_off= int, glyf_off= int, loca_off= int, hmtx_off= int, kern_off= int
, npts= int, nends= int, nedges= int
, pen_x= int, pen_y= int, row_h= int
, aw= int, ah= int, tex= uint
, has_ttf= Toggle, line_h= int, asc_px= int
}
(* skill.md 1. kural istisnasi: ATS2 soyut tip gerceklemesi (sats'taki absviewtype). Kanit disi cast veya ham C yoktur. *)
assume Font = Font_

macdef FONT_FIELD_PX = 0
macdef FONT_FIELD_UNITS = 1
macdef FONT_FIELD_ASC = 2
macdef FONT_FIELD_DESC = 3
macdef FONT_FIELD_LGAP = 4
macdef FONT_FIELD_NUM_H = 5
macdef FONT_FIELD_NGLYPH = 6
macdef FONT_FIELD_LOCA_FMT = 7
macdef FONT_FIELD_CMAP_OFF = 8
macdef FONT_FIELD_GLYF_OFF = 9
macdef FONT_FIELD_LOCA_OFF = 10
macdef FONT_FIELD_HMTX_OFF = 11
macdef FONT_FIELD_KERN_OFF = 12
macdef FONT_FIELD_NPTS = 13
macdef FONT_FIELD_NENDS = 14
macdef FONT_FIELD_NEDGES = 15
macdef FONT_FIELD_PEN_X = 16
macdef FONT_FIELD_PEN_Y = 17
macdef FONT_FIELD_ROW_H = 18
macdef FONT_FIELD_AW = 19
macdef FONT_FIELD_AH = 20
macdef FONT_FIELD_HAS_TTF = 21
macdef FONT_FIELD_LINE_H = 22
macdef FONT_FIELD_ASC_PX = 23

fun ztex(): uint = u_zero()

fun bit(a: int, m: int): int = anth_bit(a, m)

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

fun iround(d: double): int =
  if d >= 0.0 then n_d2i(n_floor(d + 0.5))
  else 0 - n_d2i(n_floor((0.0 - d) + 0.5))

fun delta_of(short: int, same: int, byte: int, word: int): int =
  if short = 1 then (if same = 1 then byte else isub(0, byte)) else (if same = 1 then 0 else word)
fun adv_p(short: int, same: int, p: int): int =
  if short = 1 then iadd(p, 1) else if same = 1 then p else iadd(p, 2)

fun imod(a: int, m: int): int = let
  val r = a - idiv(a, m) * m
in
  if r < 0 then r + m else r
end

implement font_open() = FONT(@{
  file= buf_make(1), atlas= buf_make(AW * AH), cache= buf_make(1024 * 12 * 4)
, xs= buf_make(8192 * 4), ys= buf_make(8192 * 4), fl= buf_make(8192)
, ends= buf_make(512 * 4), edges= buf_make(MAXE * 4 * 4), cov= buf_make(256 * 256)
, px= 16, units= 0, asc= 0, desc= 0, lgap= 0
, num_h= 0, nglyph= 0, loca_fmt= Off
, cmap_off= ~1, glyf_off= ~1, loca_off= ~1, hmtx_off= ~1, kern_off= ~1
, npts= 0, nends= 0, nedges= 0
, pen_x= 1, pen_y= 1, row_h= 0
, aw= AW, ah= AH, tex= ztex()
, has_ttf= Off, line_h= 18, asc_px= 14
})

implement font_free(f) = let
  val+~FONT(s) = f
  val () = rend_tex_free(s.tex)
  val () = buf_free(s.file)
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

fun f_int_head(f: !Font, which: int): int =
  case+ f of
  | @FONT(s) => let
      val v = if which = FONT_FIELD_PX then s.px
        else if which = FONT_FIELD_UNITS then s.units
        else if which = FONT_FIELD_ASC then s.asc
        else if which = FONT_FIELD_DESC then s.desc
        else if which = FONT_FIELD_LGAP then s.lgap
        else if which = FONT_FIELD_NUM_H then s.num_h
        else if which = FONT_FIELD_NGLYPH then s.nglyph
        else if which = FONT_FIELD_LOCA_FMT then toggle_int(s.loca_fmt)
        else if which = FONT_FIELD_CMAP_OFF then s.cmap_off
        else if which = FONT_FIELD_GLYF_OFF then s.glyf_off
        else if which = FONT_FIELD_LOCA_OFF then s.loca_off
        else if which = FONT_FIELD_HMTX_OFF then s.hmtx_off
        else s.kern_off
    in
      fold@(f); v
    end

fun f_int_tail(f: !Font, which: int): int =
  case+ f of
  | @FONT(s) => let
      val v =
        if which = FONT_FIELD_NPTS then s.npts
        else if which = FONT_FIELD_NENDS then s.nends
        else if which = FONT_FIELD_NEDGES then s.nedges
        else if which = FONT_FIELD_PEN_X then s.pen_x
        else if which = FONT_FIELD_PEN_Y then s.pen_y
        else if which = FONT_FIELD_ROW_H then s.row_h
        else if which = FONT_FIELD_AW then s.aw
        else if which = FONT_FIELD_AH then s.ah
        else if which = FONT_FIELD_HAS_TTF then toggle_int(s.has_ttf)
        else if which = FONT_FIELD_LINE_H then s.line_h
        else s.asc_px
    in
      fold@(f); v
    end

fun f_int(f: !Font, which: int): int =
  if which < 0 orelse which >= FONT_FIELD_NPTS then f_int_tail(f, which)
  else f_int_head(f, which)

fun f_set_head(f: !Font, which: int, v: int): void =
  case+ f of
  | @FONT(s) => let
      val () =
        if which = FONT_FIELD_PX then s.px := v
        else if which = FONT_FIELD_UNITS then s.units := v
        else if which = FONT_FIELD_ASC then s.asc := v
        else if which = FONT_FIELD_DESC then s.desc := v
        else if which = FONT_FIELD_LGAP then s.lgap := v
        else if which = FONT_FIELD_NUM_H then s.num_h := v
        else if which = FONT_FIELD_NGLYPH then s.nglyph := v
        else if which = FONT_FIELD_LOCA_FMT then s.loca_fmt := toggle_of(ieq(v, 1))
        else if which = FONT_FIELD_CMAP_OFF then s.cmap_off := v
        else if which = FONT_FIELD_GLYF_OFF then s.glyf_off := v
        else if which = FONT_FIELD_LOCA_OFF then s.loca_off := v
        else if which = FONT_FIELD_HMTX_OFF then s.hmtx_off := v
        else s.kern_off := v
    in
      fold@(f)
    end

fun f_set_tail(f: !Font, which: int, v: int): void =
  case+ f of
  | @FONT(s) => let
      val () =
        if which = FONT_FIELD_NPTS then s.npts := v
        else if which = FONT_FIELD_NENDS then s.nends := v
        else if which = FONT_FIELD_NEDGES then s.nedges := v
        else if which = FONT_FIELD_PEN_X then s.pen_x := v
        else if which = FONT_FIELD_PEN_Y then s.pen_y := v
        else if which = FONT_FIELD_ROW_H then s.row_h := v
        else if which = FONT_FIELD_HAS_TTF then s.has_ttf := toggle_of(ieq(v, 1))
        else if which = FONT_FIELD_LINE_H then s.line_h := v
        else s.asc_px := v
    in
      fold@(f)
    end

fun f_set(f: !Font, which: int, v: int): void =
  if which < 0 orelse which >= FONT_FIELD_NPTS then f_set_tail(f, which, v)
  else f_set_head(f, which, v)

fun f_get_px(f: !Font): int = f_int(f, FONT_FIELD_PX)
fun f_get_units(f: !Font): int = f_int(f, FONT_FIELD_UNITS)
fun f_get_asc(f: !Font): int = f_int(f, FONT_FIELD_ASC)
fun f_get_desc(f: !Font): int = f_int(f, FONT_FIELD_DESC)
fun f_get_lgap(f: !Font): int = f_int(f, FONT_FIELD_LGAP)
fun f_get_num_h(f: !Font): int = f_int(f, FONT_FIELD_NUM_H)
fun f_get_nglyph(f: !Font): int = f_int(f, FONT_FIELD_NGLYPH)
fun f_get_loca_fmt(f: !Font): Toggle = toggle_of(ieq(f_int(f, FONT_FIELD_LOCA_FMT), 1))
fun f_get_cmap_off(f: !Font): int = f_int(f, FONT_FIELD_CMAP_OFF)
fun f_get_glyf_off(f: !Font): int = f_int(f, FONT_FIELD_GLYF_OFF)
fun f_get_loca_off(f: !Font): int = f_int(f, FONT_FIELD_LOCA_OFF)
fun f_get_hmtx_off(f: !Font): int = f_int(f, FONT_FIELD_HMTX_OFF)
fun f_get_kern_off(f: !Font): int = f_int(f, FONT_FIELD_KERN_OFF)
fun f_get_npts(f: !Font): int = f_int(f, FONT_FIELD_NPTS)
fun f_get_nends(f: !Font): int = f_int(f, FONT_FIELD_NENDS)
fun f_get_nedges(f: !Font): int = f_int(f, FONT_FIELD_NEDGES)
fun f_get_pen_x(f: !Font): int = f_int(f, FONT_FIELD_PEN_X)
fun f_get_pen_y(f: !Font): int = f_int(f, FONT_FIELD_PEN_Y)
fun f_get_row_h(f: !Font): int = f_int(f, FONT_FIELD_ROW_H)

fun f_set_px_val(f: !Font, v: int): void = f_set(f, FONT_FIELD_PX, v)
fun f_set_units(f: !Font, v: int): void = f_set(f, FONT_FIELD_UNITS, v)
fun f_set_asc(f: !Font, v: int): void = f_set(f, FONT_FIELD_ASC, v)
fun f_set_desc(f: !Font, v: int): void = f_set(f, FONT_FIELD_DESC, v)
fun f_set_lgap(f: !Font, v: int): void = f_set(f, FONT_FIELD_LGAP, v)
fun f_set_num_h(f: !Font, v: int): void = f_set(f, FONT_FIELD_NUM_H, v)
fun f_set_nglyph(f: !Font, v: int): void = f_set(f, FONT_FIELD_NGLYPH, v)
fun f_set_loca_fmt(f: !Font, v: Toggle): void = f_set(f, FONT_FIELD_LOCA_FMT, toggle_int(v))
fun f_set_cmap_off(f: !Font, v: int): void = f_set(f, FONT_FIELD_CMAP_OFF, v)
fun f_set_glyf_off(f: !Font, v: int): void = f_set(f, FONT_FIELD_GLYF_OFF, v)
fun f_set_loca_off(f: !Font, v: int): void = f_set(f, FONT_FIELD_LOCA_OFF, v)
fun f_set_hmtx_off(f: !Font, v: int): void = f_set(f, FONT_FIELD_HMTX_OFF, v)
fun f_set_kern_off(f: !Font, v: int): void = f_set(f, FONT_FIELD_KERN_OFF, v)
fun f_set_npts(f: !Font, v: int): void = f_set(f, FONT_FIELD_NPTS, v)
fun f_set_nends(f: !Font, v: int): void = f_set(f, FONT_FIELD_NENDS, v)
fun f_set_nedges(f: !Font, v: int): void = f_set(f, FONT_FIELD_NEDGES, v)
fun f_set_pen_x(f: !Font, v: int): void = f_set(f, FONT_FIELD_PEN_X, v)
fun f_set_pen_y(f: !Font, v: int): void = f_set(f, FONT_FIELD_PEN_Y, v)
fun f_set_row_h(f: !Font, v: int): void = f_set(f, FONT_FIELD_ROW_H, v)
fun f_set_has_ttf(f: !Font, v: int): void = f_set(f, FONT_FIELD_HAS_TTF, v)
fun f_set_line_h(f: !Font, v: int): void = f_set(f, FONT_FIELD_LINE_H, v)
fun f_set_asc_px(f: !Font, v: int): void = f_set(f, FONT_FIELD_ASC_PX, v)

implement font_has_ttf(f) = toggle_of(ieq(f_int(f, FONT_FIELD_HAS_TTF), 1))
implement font_line_h(f) = f_int(f, FONT_FIELD_LINE_H)
implement font_asc(f) = f_int(f, FONT_FIELD_ASC_PX)
implement font_atlas_w(f) = f_int(f, FONT_FIELD_AW)
implement font_atlas_h(f) = f_int(f, FONT_FIELD_AH)

implement font_tex(f) =
  case+ f of
  | @FONT(s) => let
      val t = s.tex
    in
      fold@(f); t
    end

fun take_file(f: !Font): Buf =
  case+ f of
  | @FONT(s) => let
      val b = s.file
      val () = s.file := buf_make(1)
    in
      fold@(f); b
    end

fun put_file(f: !Font, b: Buf): void =
  case+ f of
  | @FONT(s) => let
      val old = s.file
      val () = s.file := b
      val () = fold@(f)
    in
      buf_free(old)
    end

fun file_u8(f: !Font, o: int): int =
  case+ f of
  | @FONT(s) => let
      val v = u8(s.file, o)
    in
      fold@(f); v
    end

fun file_u16(f: !Font, o: int): int =
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

fun file_i16(f: !Font, o: int): int =
  case+ f of
  | @FONT(s) => let
      val v = i16(s.file, o)
    in
      fold@(f); v
    end


extern fun find_table_exh(f: !Font, a: int, c: int, d: int, e: int, i: int, n: int): int = "mac#anth_die_int"

fun find_table_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, a: int, c: int, d: int, e: int, i: int, n: int): int =
  if recfuel > 0 then (
    if i >= n then ~1
    else let
      val o = 12 + i * 16
      val hit =
        file_u8(f, o) = a andalso file_u8(f, o + 1) = c
          andalso file_u8(f, o + 2) = d andalso file_u8(f, o + 3) = e
    in
      if hit then file_u32(f, o + 8) else find_table_m(recfuel - 1, f, a, c, d, e, i + 1, n)
    end
  ) else find_table_exh(f, a, c, d, e, i, n)

fun find_table(f: !Font, a: int, c: int, d: int, e: int, i: int, n: int): int = find_table_m(airlock_nat(MAX_REC_FUEL), f, a, c, d, e, i, n)

extern fun clear_cache_exh(f: !Font, i: int): void = "mac#anth_die_void"

fun clear_cache_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int): void =
  if recfuel > 0 then (
    if i >= 1024 then ()
    else let
      val () =
        case+ f of
        | @FONT(s) => let
            val () = buf_set32(s.cache, i * 12, 0)
          in
            fold@(f)
          end
    in
      clear_cache_m(recfuel - 1, f, i + 1)
    end
  ) else clear_cache_exh(f, i)

fun clear_cache(f: !Font, i: int): void = clear_cache_m(airlock_nat(MAX_REC_FUEL), f, i)

fun clear_atlas(f: !Font): void =
  case+ f of
  | @FONT(s) => let
      val () = buf_zero(s.atlas)
      val () = s.pen_x := 1
      val () = s.pen_y := 1
      val () = s.row_h := 0
    in
      fold@(f)
    end

fun tables_present(cmap: int, glyf: int, loca: int, hmtx: int, hhea: int, maxp: int, head: int): bool =
  not(cmap < 0 orelse glyf < 0 orelse loca < 0 orelse hmtx < 0
    orelse hhea < 0 orelse maxp < 0 orelse head < 0)

fun store_head_hhea(f: !Font, head: int, hhea: int, maxp: int): void = let
  val units: int = file_u16(f, head + 18)
  val locaf: int = file_i16(f, head + 50)
  val asc: int = file_i16(f, hhea + 4)
  val desc: int = file_i16(f, hhea + 6)
  val lgap: int = file_i16(f, hhea + 8)
  val nh: int = file_u16(f, hhea + 34)
  val ng: int = file_u16(f, maxp + 4)
  val () = f_set_units(f, units)
  val () = f_set_asc(f, asc)
  val () = f_set_desc(f, desc)
  val () = f_set_lgap(f, lgap)
  val () = f_set_num_h(f, nh)
  val () = f_set_nglyph(f, ng)
  val () = f_set_loca_fmt(f, toggle_of(locaf <> 0))
in
end

fun store_table_offsets(f: !Font, cmap: int, glyf: int, loca: int, hmtx: int, kern: int): void = let
  val () = f_set_cmap_off(f, cmap)
  val () = f_set_glyf_off(f, glyf)
  val () = f_set_loca_off(f, loca)
  val () = f_set_hmtx_off(f, hmtx)
  val () = f_set_kern_off(f, kern)
in
end

fun ttf_line_height(px: int, units: int, asc: int, desc: int, lgap: int): int = let
  val den: int = if igt(units, 0) then units else 1
  val numer: int = imul(iadd(isub(asc, desc), lgap), px)
  val lh0: int = idiv(numer, den)
in
  if ilt(lh0, 12) then 12 else lh0
end

fun ttf_ascent_px(px: int, units: int, asc: int): int = let
  val den: int = if igt(units, 0) then units else 1
  val ap: int = idiv(imul(asc, px), den)
in
  if igt(ap, 0) then ap else 12
end

fun store_ttf_metrics(f: !Font): void = let
  val want = f_get_px(f)
  val px: int = if igt(want, 0) then want else 16
  val units = f_get_units(f)
  val asc = f_get_asc(f)
  val desc = f_get_desc(f)
  val lgap = f_get_lgap(f)
  val () = f_set_px_val(f, px)
  val () = f_set_line_h(f, ttf_line_height(px, units, asc, desc, lgap))
  val () = f_set_asc_px(f, ttf_ascent_px(px, units, asc))
  val () = f_set_has_ttf(f, 1)
  val () = clear_atlas(f)
  val () = clear_cache(f, 0)
in
end

fun parse_tables(f: !Font): bool = let
  val ntab = file_u16(f, 4)
  val cmap = find_table(f, 99, 109, 97, 112, 0, ntab)
  val glyf = find_table(f, 103, 108, 121, 102, 0, ntab)
  val loca = find_table(f, 108, 111, 99, 97, 0, ntab)
  val hmtx = find_table(f, 104, 109, 116, 120, 0, ntab)
  val hhea = find_table(f, 104, 104, 101, 97, 0, ntab)
  val maxp = find_table(f, 109, 97, 120, 112, 0, ntab)
  val head = find_table(f, 104, 101, 97, 100, 0, ntab)
  val kern = find_table(f, 107, 101, 114, 110, 0, ntab)
in
  if not(tables_present(cmap, glyf, loca, hmtx, hhea, maxp, head)) then false
  else let
    val () = store_head_hhea(f, head, hhea, maxp)
    val () = store_table_offsets(f, cmap, glyf, loca, hmtx, kern)
    val () = store_ttf_metrics(f)
  in
    true
  end
end

fun drop_tex(f: !Font): void =
  case+ f of
  | @FONT(s) => let
      val t = s.tex
      val () = s.tex := ztex()
      val () = fold@(f)
    in
      rend_tex_free(t)
    end

fun scaled_line_h(f: !Font, px: int): int = let
  val units = f_get_units(f)
  val asc = f_get_asc(f)
  val desc = f_get_desc(f)
  val lgap = f_get_lgap(f)
  val den = if igt(units, 0) then units else 1
  val span = iadd(isub(asc, desc), lgap)
  val numer: int = imul(span, px)
  val lh0 = if igt(units, 0) then idiv(numer, den) else iadd(px, 2)
in
  if ilt(lh0, px) then px else lh0
end

fun scaled_asc_px(f: !Font, px: int): int = let
  val units = f_get_units(f)
  val den = if igt(units, 0) then units else 1
  val ap = if igt(units, 0) then idiv(imul(f_get_asc(f), px), den) else isub(px, 2)
in
  if igt(ap, 0) then ap else 12
end

implement font_set_px(f, px0) = let
  val px = if ilt(px0, 8) then 8 else if igt(px0, 48) then 48 else px0
in
  if ieq(f_get_px(f), px) then ()
  else let
    val lh = scaled_line_h(f, px)
    val ap = scaled_asc_px(f, px)
    val () = f_set_px_val(f, px)
    val () = f_set_line_h(f, if ilt(lh, 8) then 8 else lh)
    val () = f_set_asc_px(f, if igt(ap, 0) then ap else 12)
    val () = clear_atlas(f)
    val () = clear_cache(f, 0)
  in
    drop_tex(f)
  end
end

fun read_font_file(f: !Font, fd: int, sz: int): int = let
  val b0 = take_file(f)
  var b = b0
  val () = buf_resize(b, sz + 1)
  val n = fs_read_buf(fd, b, sz)
  val () = buf_set_len(b, if n > 0 then n else 0)
  val () = fs_close(fd)
  val () = put_file(f, b)
in
  n
end

fun fit_px_after_load(f: !Font): void = let
  val cur_px = f_get_px(f)
  val px_val = if cur_px >= 8 then cur_px else 18
  val () = f_set_px_val(f, 0)
in
  font_set_px(f, px_val)
end

fun load_font_fd(f: !Font, fd: int, sz: int): bool = let
  val n = read_font_file(f, fd, sz)
in
  if n < 12 then false
  else let
    val ok = parse_tables(f)
    val () = if ok then fit_px_after_load(f) else ()
  in
    ok
  end
end

implement font_use_file(f, path) = let
  val sz = fs_size(path)
in
  if sz <= 12 orelse sz > 20000000 then false
  else let
    val fd = fs_open_read(path)
  in
    if fd < 0 then false
    else load_font_fd(f, fd, sz)
  end
end

fun cmap_seg_gid(f: !Font, i: int, cp: int, sc: int, deltas: int, offs: int): int = let
  val ro: int = file_u16(f, iadd(offs, imul(i, 2)))
  val delta: int = file_i16(f, iadd(deltas, imul(i, 2)))
  val gid0 = (
    if ro = 0 then 0
    else file_u16(f, iadd(iadd(iadd(offs, imul(i, 2)), ro), imul(isub(cp, sc), 2)))
  ): int
  val gid = (
    if ro = 0 then imod(iadd(cp, delta), 65536)
    else if gid0 = 0 then 0
    else imod(iadd(gid0, delta), 65536)
  ): int
in
  gid
end

extern fun cmap_search_exh(f: !Font, i: int, segs: int, cp: int, ends: int, starts: int, deltas: int, offs: int): int = "mac#anth_die_int"

fun cmap_search_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int, segs: int, cp: int, ends: int, starts: int, deltas: int, offs: int): int =
  if recfuel > 0 then (
    if i >= segs then 0
    else let
      val ec: int = file_u16(f, iadd(ends, imul(i, 2)))
    in
      if cp > ec then cmap_search_m(recfuel - 1, f, i + 1, segs, cp, ends, starts, deltas, offs)
      else let
        val sc: int = file_u16(f, iadd(starts, imul(i, 2)))
      in
        if cp < sc then 0
        else cmap_seg_gid(f, i, cp, sc, deltas, offs)
      end
    end
  ) else cmap_search_exh(f, i, segs, cp, ends, starts, deltas, offs)

fun cmap_search(f: !Font, i: int, segs: int, cp: int, ends: int, starts: int, deltas: int, offs: int): int = cmap_search_m(airlock_nat(MAX_REC_FUEL), f, i, segs, cp, ends, starts, deltas, offs)

fun cmap_fmt4(f: !Font, sub: int, cp: int): int = let
  val segs2: int = file_u16(f, iadd(sub, 6))
  val segs: int = idiv(segs2, 2)
  val ends: int = iadd(sub, 14)
  val starts: int = iadd(iadd(ends, segs2), 2)
  val deltas: int = iadd(starts, segs2)
  val offs: int = iadd(deltas, segs2)
in
  if segs <= 0 orelse segs > 512 then 0
  else cmap_search(f, 0, segs, cp, ends, starts, deltas, offs)
end

datatype CmapEnc = CmapWinBmp | CmapUniBmp | CmapUniFull | CmapOther

fun cmap_enc_of(plat: int, enc: int): CmapEnc =
  if plat = 3 andalso enc = 1 then CmapWinBmp
  else if plat = 0 andalso enc = 3 then CmapUniBmp
  else if plat = 0 andalso enc = 4 then CmapUniFull
  else CmapOther

fun cmap_usable(k: CmapEnc): bool = case+ k of
  | CmapWinBmp() => true
  | CmapUniBmp() => true
  | CmapUniFull() => true
  | CmapOther() => false

extern fun cmap_find_exh(f: !Font, i: int, nt: int, cmap: int): int = "mac#anth_die_int"

fun cmap_find_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int, nt: int, cmap: int): int =
  if recfuel > 0 then (
    if i >= nt then ~1
    else let
      val at: int = iadd(iadd(cmap, 4), imul(i, 8))
      val plat: int = file_u16(f, at)
      val enc: int = file_u16(f, iadd(at, 2))
      val off: int = file_u32(f, iadd(at, 4))
    in
      if cmap_usable(cmap_enc_of(plat, enc)) then iadd(cmap, off) else cmap_find_m(recfuel - 1, f, i + 1, nt, cmap)
    end
  ) else cmap_find_exh(f, i, nt, cmap)

fun cmap_find(f: !Font, i: int, nt: int, cmap: int): int = cmap_find_m(airlock_nat(MAX_REC_FUEL), f, i, nt, cmap)

datatype CmapFmt = CmapSeg | CmapOther

fun cmap_fmt_of(n: int): CmapFmt =
  if n = 4 then CmapSeg else CmapOther

fun is_cmap_seg(k: CmapFmt): bool = case+ k of
  | CmapSeg() => true
  | CmapOther() => false

fun cmap_gid(f: !Font, cp: int): int = let
  val cmap: int = f_get_cmap_off(f)
  val nt: int = (if cmap < 0 then 0 else file_u16(f, iadd(cmap, 2))): int
  val sub: int = (if cmap < 0 then ~1 else cmap_find(f, 0, nt, cmap)): int
in
  if sub < 0 then 0
  else let
    val fmt = file_u16(f, sub)
  in
    if is_cmap_seg(cmap_fmt_of(fmt)) then cmap_fmt4(f, sub, cp) else 0
  end
end

fun loca_at(f: !Font, gid: int): int = let
  val off = f_get_loca_off(f)
  val fmt = f_get_loca_fmt(f)
in
  if off < 0 orelse gid < 0 then 0
  else if is_off(fmt) then file_u16(f, off + gid * 2) * 2
  else file_u32(f, off + gid * 4)
end

fun hmtx_adv(f: !Font, gid: int): int = let
  val off = f_get_hmtx_off(f)
  val nh = f_get_num_h(f)
  val i: int = (if gid < nh then gid else if nh > 0 then isub(nh, 1) else 0): int
in
  if off < 0 orelse nh <= 0 then 0 else file_u16(f, iadd(off, imul(i, 4)))
end


fun pt_set(f: !Font, i: int, x: int, y: int, on: int): void = let
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

fun pt_x(f: !Font, i: int): int =
  case+ f of
  | @FONT(s) => let
      val v = buf_get32(s.xs, i)
    in
      fold@(f); v
    end

fun pt_y(f: !Font, i: int): int =
  case+ f of
  | @FONT(s) => let
      val v = buf_get32(s.ys, i)
    in
      fold@(f); v
    end

fun pt_on(f: !Font, i: int): int =
  case+ f of
  | @FONT(s) => let
      val v = buf_get(s.fl, i)
    in
      fold@(f); v
    end

fun end_set(f: !Font, i: int, v: int): void =
  case+ f of
  | @FONT(s) => let
      val () = buf_set32(s.ends, i, v)
    in
      fold@(f)
    end

fun end_get(f: !Font, i: int): int =
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

fun edge_push(f: !Font, x0: int, y0: int, x1: int, y1: int): void =
  if x0 = x1 andalso y0 = y1 then ()
  else let
    val n = f_get_nedges(f)
  in
    if n >= MAXE then ()
    else edge_store(f, n, x0, y0, x1, y1)
  end

fun edge_get(f: !Font, e: int, k: int): int =
  case+ f of
  | @FONT(s) => let
      val v = buf_get32(s.edges, e * 4 + k)
    in
      fold@(f); v
    end

extern fun quad_exh(f: !Font, x0: int, y0: int, x1: int, y1: int, x2: int, y2: int, depth: int): void = "mac#anth_die_void"

fun quad_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, x0: int, y0: int, x1: int, y1: int, x2: int, y2: int, depth: int): void =
  if recfuel > 0 then (
    if depth <= 0 then edge_push(f, x0, y0, x2, y2)
    else let
      val mx01 = (x0 + x1) / 2
      val my01 = (y0 + y1) / 2
      val mx12 = (x1 + x2) / 2
      val my12 = (y1 + y2) / 2
      val mx = (mx01 + mx12) / 2
      val my = (my01 + my12) / 2
      val () = quad_m(recfuel - 1, f, x0, y0, mx01, my01, mx, my, depth - 1)
    in
      quad_m(recfuel - 1, f, mx, my, mx12, my12, x2, y2, depth - 1)
    end
  ) else quad_exh(f, x0, y0, x1, y1, x2, y2, depth)

fun quad(f: !Font, x0: int, y0: int, x1: int, y1: int, x2: int, y2: int, depth: int): void = quad_m(airlock_nat(MAX_REC_FUEL), f, x0, y0, x1, y1, x2, y2, depth)

fun set_x(f: !Font, i: int, x: int): void =
  case+ f of
  | @FONT(s) => let
      val () = buf_set32(s.xs, i, x)
    in
      fold@(f)
    end


fun set_fl(f: !Font, i: int, v: int): void =
  case+ f of
  | @FONT(s) => let
      val () = buf_set(s.fl, i, v)
    in
      fold@(f)
    end

extern fun read_ends_exh(f: !Font, i: int, ncont: int, p: int, base: int, eb: int): int = "mac#anth_die_int"

fun read_ends_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int, ncont: int, p: int, base: int, eb: int): int =
  if recfuel > 0 then (
    if i >= ncont then p
    else let
      val e = file_u16(f, p)
      val () = end_set(f, eb + i, base + e)
    in
      read_ends_m(recfuel - 1, f, i + 1, ncont, p + 2, base, eb)
    end
  ) else read_ends_exh(f, i, ncont, p, base, eb)

fun read_ends(f: !Font, i: int, ncont: int, p: int, base: int, eb: int): int = read_ends_m(airlock_nat(MAX_REC_FUEL), f, i, ncont, p, base, eb)

extern fun flag_run_exh(f: !Font, i: int, np: int, p: int, base: int): int = "mac#anth_die_int"

fun flag_run_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int, np: int, p: int, base: int): int =
  if recfuel > 0 then (
    if i >= np then p
    else let
      val flg = file_u8(f, p)
      val rep0: int = (if bit(flg, 8) = 1 then file_u8(f, p + 1) else 0): int
      val rep: int = (if rep0 < 0 then 1 else rep0 + 1): int
      val p2 = (if bit(flg, 8) = 1 then iadd(p, 2) else iadd(p, 1)) : int
      fun put(f: !Font, k: int): void =
        if k >= rep orelse i + k >= np then ()
        else let
          val () = set_fl(f, iadd(iadd(base, i), k), flg)
        in
          put(f, iadd(k, 1))
        end
      val () = put(f, 0)
      val step = (if iadd(i, rep) > np then isub(np, i) else rep) : int
    in
      flag_run_m(recfuel - 1, f, iadd(i, step), np, p2, base)
    end
  ) else flag_run_exh(f, i, np, p, base)

fun flag_run(f: !Font, i: int, np: int, p: int, base: int): int = flag_run_m(airlock_nat(MAX_REC_FUEL), f, i, np, p, base)

extern fun xs_loop_exh(f: !Font, i: int, np: int, p: int, x: int, base: int): int = "mac#anth_die_int"

fun xs_loop_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int, np: int, p: int, x: int, base: int): int =
  if recfuel > 0 then (
    if i >= np then p
    else let
      val flg = pt_on(f, base + i)
      val short = bit(flg, 2)
      val same = bit(flg, 16)
      val dx = delta_of(short, same, file_u8(f, p), file_i16(f, p))
      val p2 = adv_p(short, same, p)
      val () = set_x(f, iadd(base, i), iadd(x, dx))
    in
      xs_loop_m(recfuel - 1, f, iadd(i, 1), np, p2, iadd(x, dx), base)
    end
  ) else xs_loop_exh(f, i, np, p, x, base)

fun xs_loop(f: !Font, i: int, np: int, p: int, x: int, base: int): int = xs_loop_m(airlock_nat(MAX_REC_FUEL), f, i, np, p, x, base)

extern fun ys_loop_exh(f: !Font, i: int, np: int, p: int, y: int, base: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double): void = "mac#anth_die_void"

fun ys_loop_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int, np: int, p: int, y: int, base: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double): void =
  if recfuel > 0 then (
    if i >= np then ()
    else let
      val flg = pt_on(f, base + i)
      val short = bit(flg, 4)
      val same = bit(flg, 32)
      val dyb = delta_of(short, same, file_u8(f, p), file_i16(f, p))
      val p2 = adv_p(short, same, p)
      val rx = pt_x(f, iadd(base, i))
      val ry = iadd(y, dyb)
      val nx = iround(xx * n_i2d(rx) + xy * n_i2d(ry) + dx)
      val ny = iround(yx * n_i2d(rx) + yy * n_i2d(ry) + dy)
      val () = pt_set(f, iadd(base, i), nx, ny, bit(flg, 1))
    in
      ys_loop_m(recfuel - 1, f, iadd(i, 1), np, p2, ry, base, dx, dy, xx, yy, xy, yx)
    end
  ) else ys_loop_exh(f, i, np, p, y, base, dx, dy, xx, yy, xy, yx)

fun ys_loop(f: !Font, i: int, np: int, p: int, y: int, base: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double): void = ys_loop_m(airlock_nat(MAX_REC_FUEL), f, i, np, p, y, base, dx, dy, xx, yy, xy, yx)

fun decode_points(f: !Font, p2: int, base: int, np: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double): void = let
  val p3 = flag_run(f, 0, np, p2, base)
  val p4 = xs_loop(f, 0, np, p3, 0, base)
in
  ys_loop(f, 0, np, p4, 0, base, dx, dy, xx, yy, xy, yx)
end

fun decode_simple(f: !Font, p0: int, ncont: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double): void = let
  val base = f_get_npts(f)
  val eb = f_get_nends(f)
in
  if ncont <= 0 then ()
  else let
    val p1 = read_ends(f, 0, ncont, p0, base, eb)
    val ninstr = file_u16(f, p1)
    val p2 = p1 + 2 + ninstr
    val np = end_get(f, eb + ncont - 1) - base + 1
  in
    if np <= 0 orelse np > MAXP orelse base + np >= OUT0 then ()
    else let
      val () = decode_points(f, p2, base, np, dx, dy, xx, yy, xy, yx)
      val () = f_set_nends(f, eb + ncont)
      val () = f_set_npts(f, base + np)
    in
    end
  end
end

fun file_i8(f: !Font, o: int): int = let
  val v = file_u8(f, o)
in
  if v >= 128 then v - 256 else v
end

fun f214(f: !Font, o: int): double = n_i2d(file_i16(f, o)) / 16384.0

typedef comp_xf = @{ cxx= double, cyy= double, cxy= double, cyx= double, q= int }

fun comp_scale_xf(f: !Font, flags: int, q: int): comp_xf =
  if bit(flags, 8) = 1 then let
    val s = f214(f, q)
  in
    @{cxx= s, cyy= s, cxy= 0.0, cyx= 0.0, q= iadd(q, 2)}
  end
  else if bit(flags, 64) = 1 then
    @{cxx= f214(f, q), cyy= f214(f, iadd(q, 2)), cxy= 0.0, cyx= 0.0, q= iadd(q, 4)}
  else if bit(flags, 128) = 1 then
    @{cxx= f214(f, q), cyy= f214(f, iadd(q, 6)), cxy= f214(f, iadd(q, 2)), cyx= f214(f, iadd(q, 4)), q= iadd(q, 8)}
  else @{cxx= 1.0, cyy= 1.0, cxy= 0.0, cyx= 0.0, q= q}

extern fun comp_loop_exh(f: !Font, p: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double, depth: int, left: int): void = "mac#anth_die_void"

fun load_glyph {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, gid: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double, depth: int): void =
  if recfuel > 0 then (
    if depth > 8 orelse gid <= 0 orelse gid >= f_get_nglyph(f) then ()
    else let
      val a = loca_at(f, gid)
      val b = loca_at(f, gid + 1)
      val glyf = f_get_glyf_off(f)
    in
      if b <= a orelse glyf < 0 then ()
      else let
        val p = glyf + a
        val ncont = file_i16(f, p)
      in
        if ncont > 0 then decode_simple(f, p + 10, ncont, dx, dy, xx, yy, xy, yx)
        else if ncont < 0 then comp_loop(recfuel - 1, f, p + 10, dx, dy, xx, yy, xy, yx, depth, 48)
        else ()
      end
    end
  ) else ()

and comp_loop {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, p: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double, depth: int, left: int): void =
  if recfuel > 0 then (
    if left <= 0 then ()
    else let
      val flags = file_u16(f, p)
      val gid = file_u16(f, iadd(p, 2))
      val q0 = iadd(p, 4)
      val words = bit(flags, 1)
      val arg1 = (if ieq(words, 1) then file_i16(f, q0) else file_i8(f, q0)) : int
      val arg2 = (if ieq(words, 1) then file_i16(f, iadd(q0, 2)) else file_i8(f, iadd(q0, 1))) : int
      val xf = comp_scale_xf(f, flags, (if ieq(words, 1) then iadd(q0, 4) else iadd(q0, 2)))
      val () = comp_place(recfuel - 1, f, flags, gid, dx, dy, xx, yy, xy, yx, depth, xf, arg1, arg2)
    in
      if bit(flags, 32) = 1 then comp_loop(recfuel - 1, f, xf.q, dx, dy, xx, yy, xy, yx, depth, left - 1)
      else ()
    end
  ) else comp_loop_exh(f, p, dx, dy, xx, yy, xy, yx, depth, left)

and comp_place {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, flags: int, gid: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double, depth: int, xf: comp_xf, arg1: int, arg2: int): void =
  if recfuel > 0 then let
    val adx = n_i2d(arg1)
    val ady = n_i2d(arg2)
    val nxx = xx * xf.cxx + xy * xf.cyx
    val nxy = xx * xf.cxy + xy * xf.cyy
    val nyx = yx * xf.cxx + yy * xf.cyx
    val nyy = yx * xf.cxy + yy * xf.cyy
    val ndx = xx * adx + xy * ady + dx
    val ndy = yx * adx + yy * ady + dy
  in
    if bit(flags, 2) = 1 then load_glyph(recfuel - 1, f, gid, ndx, ndy, nxx, nyy, nxy, nyx, depth + 1)
    else ()
  end else ()

fun push_out(f: !Font, n: int, x: int, y: int, on: int): int =
  if n >= 1500 then n
  else let
    val () = pt_set(f, iadd(OUT0, n), x, y, on)
  in
    iadd(n, 1)
  end

fun pix_x(x: int, minx: int, sc: double): int = iround(n_i2d(x - minx) * sc) + 1
fun pix_y(y: int, maxy: int, sc: double): int = iround(n_i2d(maxy - y) * sc) + 1

fun emit_xy(f: !Font, x0: int, y0: int, x1: int, y1: int, minx: int, maxy: int, sc: double): void =
  edge_push(f, pix_x(x0, minx, sc), pix_y(y0, maxy, sc), pix_x(x1, minx, sc), pix_y(y1, maxy, sc))

extern fun rot_copy_exh(f: !Font, n: int, s: int, i: int): void = "mac#anth_die_void"

fun rot_copy_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, n: int, s: int, i: int): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val src = OUT0 + imod(s + i, n)
      val () = pt_set(f, 5200 + i, pt_x(f, src), pt_y(f, src), pt_on(f, src))
    in
      rot_copy_m(recfuel - 1, f, n, s, i + 1)
    end
  ) else rot_copy_exh(f, n, s, i)

fun rot_copy(f: !Font, n: int, s: int, i: int): void = rot_copy_m(airlock_nat(MAX_REC_FUEL), f, n, s, i)

extern fun rot_back_exh(f: !Font, n: int, i: int): void = "mac#anth_die_void"

fun rot_back_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, n: int, i: int): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val () = pt_set(f, OUT0 + i, pt_x(f, 5200 + i), pt_y(f, 5200 + i), pt_on(f, 5200 + i))
    in
      rot_back_m(recfuel - 1, f, n, i + 1)
    end
  ) else rot_back_exh(f, n, i)

fun rot_back(f: !Font, n: int, i: int): void = rot_back_m(airlock_nat(MAX_REC_FUEL), f, n, i)

extern fun find_on_exh(f: !Font, n: int, i: int): int = "mac#anth_die_int"

fun find_on_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, n: int, i: int): int =
  if recfuel > 0 then (
    if i >= n then 0
    else if pt_on(f, OUT0 + i) <> 0 then i else find_on_m(recfuel - 1, f, n, i + 1)
  ) else find_on_exh(f, n, i)

fun find_on(f: !Font, n: int, i: int): int = find_on_m(airlock_nat(MAX_REC_FUEL), f, n, i)

fun push_mid(f: !Font, n: int, prev_i: int, curr_i: int): int = let
  val mx = idiv(iadd(pt_x(f, prev_i), pt_x(f, curr_i)), 2)
  val my = idiv(iadd(pt_y(f, prev_i), pt_y(f, curr_i)), 2)
in
  push_out(f, n, mx, my, 1)
end

fun expand_contour(f: !Font, a: int, b: int): int = let
  val clen = isub(b, a) + 1
  fun loop(f: !Font, k: int, clen: int, a: int, n: int): int =
    if k >= clen then n
    else let
      val curr_i = iadd(a, k)
      val prev_k = imod(isub(iadd(k, clen), 1), clen)
      val prev_i = iadd(a, prev_k)
      val curr_on = pt_on(f, curr_i)
      val prev_on = pt_on(f, prev_i)
      val n2 = if ieq(curr_on, 0) andalso ieq(prev_on, 0) then push_mid(f, n, prev_i, curr_i) else n
      val n3 = push_out(f, n2, pt_x(f, curr_i), pt_y(f, curr_i), curr_on)
    in
      loop(f, iadd(k, 1), clen, a, n3)
    end
in
  if ilt(clen, 2) then 0 else loop(f, 0, clen, a, 0)
end

fun emit_line_at(f: !Font, i: int, n: int, minx: int, maxy: int, sc: double): void = let
  val p0 = imod(i, n)
  val p1 = imod(iadd(i, 1), n)
in
  emit_xy(f, pt_x(f, iadd(OUT0, p0)), pt_y(f, iadd(OUT0, p0)),
             pt_x(f, iadd(OUT0, p1)), pt_y(f, iadd(OUT0, p1)), minx, maxy, sc)
end

fun emit_curve_at(f: !Font, i: int, n: int, minx: int, maxy: int, sc: double): void = let
  val p0 = imod(i, n)
  val p1 = imod(iadd(i, 1), n)
  val p2 = imod(iadd(i, 2), n)
  val x0 = pt_x(f, iadd(OUT0, p0))
  val y0 = pt_y(f, iadd(OUT0, p0))
  val x1 = pt_x(f, iadd(OUT0, p1))
  val y1 = pt_y(f, iadd(OUT0, p1))
  val x2 = pt_x(f, iadd(OUT0, p2))
  val y2 = pt_y(f, iadd(OUT0, p2))
in
  quad(f, pix_x(x0, minx, sc), pix_y(y0, maxy, sc),
          pix_x(x1, minx, sc), pix_y(y1, maxy, sc),
          pix_x(x2, minx, sc), pix_y(y2, maxy, sc), 3)
end

fun walk_contour(f: !Font, n: int, minx: int, maxy: int, sc: double): void = let
  fun walk(f: !Font, i: int, n: int, minx: int, maxy: int, sc: double): void =
    if i >= n then ()
    else if pt_on(f, iadd(OUT0, imod(iadd(i, 1), n))) <> 0 then let
      val () = emit_line_at(f, i, n, minx, maxy, sc)
    in
      walk(f, iadd(i, 1), n, minx, maxy, sc)
    end else let
      val () = emit_curve_at(f, i, n, minx, maxy, sc)
    in
      walk(f, iadd(i, 2), n, minx, maxy, sc)
    end
in
  if igt(n, 1) then walk(f, 0, n, minx, maxy, sc) else ()
end

fun one_contour(f: !Font, a: int, b: int, minx: int, maxy: int, sc: double): void =
  if b < a then ()
  else let
    val n1 = expand_contour(f, a, b)
    val s = (if n1 > 0 then find_on(f, n1, 0) else 0) : int
    val () = if ine(s, 0) then let
      val () = rot_copy(f, n1, s, 0)
    in
      rot_back(f, n1, 0)
    end else ()
  in
    walk_contour(f, n1, minx, maxy, sc)
  end

extern fun contours_exh(f: !Font, ci: int, nends: int, minx: int, maxy: int, sc: double): void = "mac#anth_die_void"

fun contours_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, ci: int, nends: int, minx: int, maxy: int, sc: double): void =
  if recfuel > 0 then (
    if ci >= nends then ()
    else let
      val a = (if ci = 0 then 0 else iadd(end_get(f, isub(ci, 1)), 1)) : int
      val b = end_get(f, ci)
      val () = one_contour(f, a, b, minx, maxy, sc)
    in
      contours_m(recfuel - 1, f, ci + 1, nends, minx, maxy, sc)
    end
  ) else contours_exh(f, ci, nends, minx, maxy, sc)

fun contours(f: !Font, ci: int, nends: int, minx: int, maxy: int, sc: double): void = contours_m(airlock_nat(MAX_REC_FUEL), f, ci, nends, minx, maxy, sc)

extern fun bbox_exh(f: !Font, i: int, n: int, minx: &int, miny: &int, maxx: &int, maxy: &int): void = "mac#anth_die_void"

fun bbox_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int, n: int, minx: &int, miny: &int, maxx: &int, maxy: &int): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val x = pt_x(f, i)
      val y = pt_y(f, i)
      val () = if x < minx then minx := x else ()
      val () = if y < miny then miny := y else ()
      val () = if x > maxx then maxx := x else ()
      val () = if y > maxy then maxy := y else ()
    in
      bbox_m(recfuel - 1, f, i + 1, n, minx, miny, maxx, maxy)
    end
  ) else bbox_exh(f, i, n, minx, miny, maxx, maxy)

fun bbox(f: !Font, i: int, n: int, minx: &int, miny: &int, maxx: &int, maxy: &int): void = bbox_m(airlock_nat(MAX_REC_FUEL), f, i, n, minx, miny, maxx, maxy)

fun zero_cov(f: !Font): void =
  case+ f of
  | @FONT(s) => let
      val () = buf_zero(s.cov)
    in
      fold@(f)
    end

fun cov_set(f: !Font, i: int, v: int): void =
  case+ f of
  | @FONT(s) => let
      val () = if i >= 0 then buf_set(s.cov, i, v) else ()
    in
      fold@(f)
    end

fun cov_get(f: !Font, i: int): int =
  case+ f of
  | @FONT(s) => let
      val v = if i >= 0 then buf_get(s.cov, i) else 0
    in
      fold@(f); v
    end

fun atlas_set(f: !Font, x: int, y: int, v: int): void =
  case+ f of
  | @FONT(s) => let
      val () = if x >= 0 andalso y >= 0 andalso x < s.aw andalso y < s.ah then buf_set(s.atlas, y * s.aw + x, v) else ()
    in
      fold@(f)
    end

fun atlas_get(f: !Font, x: int, y: int): int =
  case+ f of
  | @FONT(s) => let
      val v = if x >= 0 andalso y >= 0 andalso x < s.aw andalso y < s.ah then buf_get(s.atlas, y * s.aw + x) else 0
    in
      fold@(f); v
    end

extern fun collect_exh(f: !Font, y: int, e: int, ne: int, nc: int): int = "mac#anth_die_int"

fun collect_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, y: int, e: int, ne: int, nc: int): int =
  if recfuel > 0 then (
    if e >= ne orelse nc >= 100 then nc
    else let
      val y0 = edge_get(f, e, 1)
      val y1 = edge_get(f, e, 3)
    in
      if y0 = y1 then collect_m(recfuel - 1, f, y, e + 1, ne, nc)
      else if (y0 <= y andalso y1 > y) orelse (y1 <= y andalso y0 > y) then let
        val x0 = edge_get(f, e, 0)
        val x1 = edge_get(f, e, 2)
        val den = n_i2d(y1 - y0)
        val t = (n_i2d(y) - n_i2d(y0)) / den
        val x = iround(n_i2d(x0) + t * n_i2d(x1 - x0))
        val dir = if y1 > y0 then 1 else ~1
        val () = end_set(f, nc * 2, x)
        val () = end_set(f, nc * 2 + 1, dir)
      in
        collect_m(recfuel - 1, f, y, e + 1, ne, nc + 1)
      end else collect_m(recfuel - 1, f, y, e + 1, ne, nc)
    end
  ) else collect_exh(f, y, e, ne, nc)

fun collect(f: !Font, y: int, e: int, ne: int, nc: int): int = collect_m(airlock_nat(MAX_REC_FUEL), f, y, e, ne, nc)

extern fun cross_swap_exh(f: !Font, i: int): void = "mac#anth_die_void"

fun cross_swap_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, i: int): void =
  if recfuel > 0 then (
    if i <= 0 then ()
    else let
      val x = end_get(f, i * 2)
      val xp = end_get(f, (i - 1) * 2)
    in
      if x >= xp then ()
      else let
        val d = end_get(f, i * 2 + 1)
        val dp = end_get(f, (i - 1) * 2 + 1)
        val () = end_set(f, i * 2, xp)
        val () = end_set(f, i * 2 + 1, dp)
        val () = end_set(f, (i - 1) * 2, x)
        val () = end_set(f, (i - 1) * 2 + 1, d)
      in
        cross_swap_m(recfuel - 1, f, i - 1)
      end
    end
  ) else cross_swap_exh(f, i)

fun cross_swap(f: !Font, i: int): void = cross_swap_m(airlock_nat(MAX_REC_FUEL), f, i)

extern fun cross_sort_exh(f: !Font, n: int, i: int): void = "mac#anth_die_void"

fun cross_sort_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, n: int, i: int): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val () = cross_swap(f, i)
    in
      cross_sort_m(recfuel - 1, f, n, i + 1)
    end
  ) else cross_sort_exh(f, n, i)

fun cross_sort(f: !Font, n: int, i: int): void = cross_sort_m(airlock_nat(MAX_REC_FUEL), f, n, i)

fun paint(f: !Font, sw: int, y: int, x0: int, x1: int): void = let
  val a = (if x0 < 0 then 0 else x0) : int
  val b = (if x1 > sw then sw else x1) : int
  fun pix(f: !Font, x: int): void =
    if x >= b then ()
    else let
      val () = cov_set(f, y * sw + x, 255)
    in
      pix(f, x + 1)
    end
in
  if a < b andalso y >= 0 andalso y < 256 then pix(f, a) else ()
end

extern fun wind_exh(f: !Font, sw: int, y: int, n: int, i: int, w: int, prev: int): void = "mac#anth_die_void"

fun wind_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, sw: int, y: int, n: int, i: int, w: int, prev: int): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val x = end_get(f, i * 2)
      val d = end_get(f, i * 2 + 1)
      val () = if w <> 0 then paint(f, sw, y, prev, x) else ()
    in
      wind_m(recfuel - 1, f, sw, y, n, i + 1, w + d, x)
    end
  ) else wind_exh(f, sw, y, n, i, w, prev)

fun wind(f: !Font, sw: int, y: int, n: int, i: int, w: int, prev: int): void = wind_m(airlock_nat(MAX_REC_FUEL), f, sw, y, n, i, w, prev)

extern fun scan_rows_exh(f: !Font, sw: int, sh: int, y: int): void = "mac#anth_die_void"

fun scan_rows_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, sw: int, sh: int, y: int): void =
  if recfuel > 0 then (
    if y >= sh then ()
    else let
      val ne = f_get_nedges(f)
      val nc = collect(f, y, 0, ne, 0)
      val () = cross_sort(f, nc, 1)
      val () = wind(f, sw, y, nc, 0, 0, 0)
    in
      scan_rows_m(recfuel - 1, f, sw, sh, y + 1)
    end
  ) else scan_rows_exh(f, sw, sh, y)

fun scan_rows(f: !Font, sw: int, sh: int, y: int): void = scan_rows_m(airlock_nat(MAX_REC_FUEL), f, sw, sh, y)

extern fun blit_exh(f: !Font, x0: int, y0: int, sw: int, bw: int, bh: int, y: int): void = "mac#anth_die_void"

fun blit_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, x0: int, y0: int, sw: int, bw: int, bh: int, y: int): void =
  if recfuel > 0 then (
    if y >= bh then ()
    else let
      fun bx(f: !Font, x: int): void =
        if x >= bw then ()
        else let
          val i00 = (y * 2) * sw + x * 2
          val s = cov_get(f, i00) + cov_get(f, i00 + 1) + cov_get(f, i00 + sw) + cov_get(f, i00 + sw + 1)
          val () = atlas_set(f, x0 + x, y0 + y, (s / 4): int)
        in
          bx(f, x + 1)
        end
      val () = bx(f, 0)
    in
      blit_m(recfuel - 1, f, x0, y0, sw, bw, bh, y + 1)
    end
  ) else blit_exh(f, x0, y0, sw, bw, bh, y)

fun blit(f: !Font, x0: int, y0: int, sw: int, bw: int, bh: int, y: int): void = blit_m(airlock_nat(MAX_REC_FUEL), f, x0, y0, sw, bw, bh, y)

fun cache_i(f: !Font, slot: int, k: int): int =
  case+ f of
  | @FONT(s) => let
      val v = buf_get32(s.cache, slot * 12 + k)
    in
      fold@(f); v
    end

fun cache_s(f: !Font, slot: int, k: int, v: int): void =
  case+ f of
  | @FONT(s) => let
      val () = buf_set32(s.cache, slot * 12 + k, v)
    in
      fold@(f)
    end

fun fill_g(g: &gmet >> _, ax: int, bx: int, top: int, bw: int, bh: int, x0: int, y0: int): void = let
  val () = g.ax := ax
  val () = g.bx := bx
  val () = g.top := top
  val () = g.bw := bw
  val () = g.bh := bh
  val () = g.x0 := x0
  val () = g.y0 := y0
  val () = g.ok := On
in
end

extern fun cache_probe_exh(f: !Font, cp: int, g: &gmet >> _, h0: int, k: int): int = "mac#anth_die_int"

fun cache_probe_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, cp: int, g: &gmet >> _, h0: int, k: int): int =
  if recfuel > 0 then (
    if k >= 24 then let
      val () = fill_g(g, 0, 0, 0, 0, 0, 0, 0)
    in
      0
    end else let
      val slot = imod(iadd(h0, k), 1024)
      val used = cache_i(f, slot, 0)
    in
      if ieq(used, 1) andalso ieq(cache_i(f, slot, 1), cp) then let
        val () = fill_g(g, cache_i(f, slot, 2), cache_i(f, slot, 3), cache_i(f, slot, 4), cache_i(f, slot, 5), cache_i(f, slot, 6), cache_i(f, slot, 7), cache_i(f, slot, 8))
      in
        1
      end else cache_probe_m(recfuel - 1, f, cp, g, h0, iadd(k, 1))
    end
  ) else cache_probe_exh(f, cp, g, h0, k)

fun cache_probe(f: !Font, cp: int, g: &gmet >> _, h0: int, k: int): int = cache_probe_m(airlock_nat(MAX_REC_FUEL), f, cp, g, h0, k)

fun cache_get(f: !Font, cp: int, g: &gmet >> _): int =
  cache_probe(f, cp, g, imod(iadd(imul(cp, 17), 3), 1024), 0)

extern fun cache_find_slot_exh(f: !Font, cp: int, h0: int, k: int): int = "mac#anth_die_int"

fun cache_find_slot_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, cp: int, h0: int, k: int): int =
  if recfuel > 0 then (
    if k >= 24 then h0
    else let
      val slot = imod(h0 + k, 1024)
    in
      if cache_i(f, slot, 0) = 0 orelse cache_i(f, slot, 1) = cp then slot
      else cache_find_slot_m(recfuel - 1, f, cp, h0, k + 1)
    end
  ) else cache_find_slot_exh(f, cp, h0, k)

fun cache_find_slot(f: !Font, cp: int, h0: int, k: int): int = cache_find_slot_m(airlock_nat(MAX_REC_FUEL), f, cp, h0, k)

fun cache_write_entry(f: !Font, slot: int, cp: int, g: &gmet): void = let
  val () = cache_s(f, slot, 0, 1)
  val () = cache_s(f, slot, 1, cp)
  val () = cache_s(f, slot, 2, g.ax)
  val () = cache_s(f, slot, 3, g.bx)
  val () = cache_s(f, slot, 4, g.top)
  val () = cache_s(f, slot, 5, g.bw)
  val () = cache_s(f, slot, 6, g.bh)
  val () = cache_s(f, slot, 7, g.x0)
  val () = cache_s(f, slot, 8, g.y0)
in
end

fun cache_put(f: !Font, cp: int, g: &gmet): void = let
  val h0 = imod(cp * 17 + 3, 1024)
  val slot = cache_find_slot(f, cp, h0, 0)
  val () = cache_write_entry(f, slot, cp, g)
in
end

fun clamp_even(n: int): int = let
  val c = (if n < 2 then 2 else (if n > 254 then 254 else n)) : int
in
  isub(c, imod(c, 2))
end

fun reset_atlas(f: !Font): void = let
  val () = clear_atlas(f)
  val () = clear_cache(f, 0)
in
  drop_tex(f)
end

fun reserve(f: !Font, bw: int, bh: int, x: &int >> _, y: &int >> _): void = let
  val px0 = f_get_pen_x(f)
  val py0 = f_get_pen_y(f)
  val rh0 = f_get_row_h(f)
  val wrap = iadd(iadd(px0, bw), 1) >= font_atlas_w(f)
  val px1 = (if wrap then 1 else px0) : int
  val py1 = (if wrap then iadd(iadd(py0, rh0), 1) else py0) : int
  val rh1 = (if wrap then 0 else rh0) : int
  val boom = iadd(iadd(py1, bh), 1) >= font_atlas_h(f)
  val () = if boom then reset_atlas(f) else ()
  val x0 = (if boom then 1 else px1) : int
  val y0 = (if boom then 1 else py1) : int
  val rh = (if boom then 0 else rh1) : int
  val () = f_set_pen_x(f, iadd(iadd(x0, bw), 1))
  val () = f_set_pen_y(f, y0)
  val () = f_set_row_h(f, if bh > rh then bh else rh)
  val () = x := x0
  val () = y := y0
in
end

fun ensure_tex(f: !Font, r: !Rend): void =
  case+ f of
  | @FONT(s) => let
      val t0 = s.tex
      val t = if t0 = ztex() then rend_tex_r8(r, t0, s.aw, s.ah) else t0
      val () = s.tex := t
    in
      fold@(f)
    end

fun upload_atlas(f: !Font, r: !Rend, tex: uint, x: int, y: int, w: int, h: int): void =
  case+ f of
  | @FONT(s) => let
      val () = glPixelStorei(GL_UNPACK_ROW_LENGTH, s.aw)
      val () = rend_tex_sub_buf(r, tex, x, y, w, h, s.atlas, y * s.aw + x)
      val () = glPixelStorei(GL_UNPACK_ROW_LENGTH, 0)
    in
      fold@(f)
    end

fun upload(f: !Font, r: !Rend, x: int, y: int, w: int, h: int): void =
  if w <= 0 orelse h <= 0 then ()
  else let
    val () = ensure_tex(f, r)
    val tex = font_tex(f)
  in
    upload_atlas(f, r, tex, x, y, w, h)
  end

fun colmask(c: int): int =
  if c <= 0 then 128
  else if c = 1 then 64
  else if c = 2 then 32
  else if c = 3 then 16
  else if c = 4 then 8
  else if c = 5 then 4
  else if c = 6 then 2
  else 1

extern fun write_pix_loop_exh(f: !Font, x0: int, y0: int, cp: int, ww: int, r: int, c: int): void = "mac#anth_die_void"

fun write_pix_loop_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, x0: int, y0: int, cp: int, ww: int, r: int, c: int): void =
  if recfuel > 0 then (
    if r >= 16 then ()
    else if c >= ww then write_pix_loop_m(recfuel - 1, f, x0, y0, cp, ww, r + 1, 0)
    else let
      val colb = c >= 8
      val bitn = if colb then c - 8 else c
      val on = bit(uf_byte(cp, r, if colb then 1 else 0), colmask(bitn))
      val () = if on = 1 then atlas_set(f, x0 + c, y0 + r, 255) else ()
    in
      write_pix_loop_m(recfuel - 1, f, x0, y0, cp, ww, r, c + 1)
    end
  ) else write_pix_loop_exh(f, x0, y0, cp, ww, r, c)

fun write_pix_loop(f: !Font, x0: int, y0: int, cp: int, ww: int, r: int, c: int): void = write_pix_loop_m(airlock_nat(MAX_REC_FUEL), f, x0, y0, cp, ww, r, c)

extern fun write_box_loop_exh(f: !Font, x0: int, y0: int, r: int, c: int): void = "mac#anth_die_void"

fun write_box_loop_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, x0: int, y0: int, r: int, c: int): void =
  if recfuel > 0 then (
    if r >= 16 then ()
    else if c >= 8 then write_box_loop_m(recfuel - 1, f, x0, y0, r + 1, 0)
    else let
      val edge = ieq(r, 0) orelse ieq(r, 15) orelse ieq(c, 0) orelse ieq(c, 7)
      val () = if edge then atlas_set(f, x0 + c, y0 + r, 255) else ()
    in
      write_box_loop_m(recfuel - 1, f, x0, y0, r, c + 1)
    end
  ) else write_box_loop_exh(f, x0, y0, r, c)

fun write_box_loop(f: !Font, x0: int, y0: int, r: int, c: int): void = write_box_loop_m(airlock_nat(MAX_REC_FUEL), f, x0, y0, r, c)

fun write_bitmap(f: !Font, x0: int, y0: int, cp: int): void = let
  val ww = if ieq(uf_wide(cp), 16) then 16 else 8
in
  if ieq(uf_wide(cp), 0) then write_box_loop(f, x0, y0, 0, 0)
  else write_pix_loop(f, x0, y0, cp, ww, 0, 0)
end

fun scale_of(f: !Font): double = let
  val units = f_get_units(f)
  val px = f_get_px(f)
  val den = if units > 0 then units else 1
in
  n_i2d(px) / n_i2d(den)
end

fun load_ttf_outline(f: !Font, gid: int): void = let
  val () = f_set_npts(f, 0)
  val () = f_set_nends(f, 0)
  val () = f_set_nedges(f, 0)
  val load_glyph_res = load_glyph(airlock_nat(MAX_REC_FUEL), f, gid, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0)
in
end

fun ttf_rasterize(f: !Font, sc: double, minx: int, maxy: int, sw: int, sh: int): void = let
  val () = contours(f, 0, f_get_nends(f), minx, maxy, sc)
  val () = zero_cov(f)
in
  scan_rows(f, sw, sh, 0)
end

fun ttf_upload_glyph(f: !Font, r: !Rend, sw: int, sh: int, x0: &int >> _, y0: &int >> _): void = let
  val bw = sw / 2
  val bh = sh / 2
  val () = reserve(f, bw, bh, x0, y0)
  val () = blit(f, x0, y0, sw, bw, bh, 0)
in
  upload(f, r, x0, y0, bw, bh)
end

fun ttf_glyph_bitmap(f: !Font, r: !Rend, sc1: double, ax: int, npts: int, g: &gmet >> _): void = let
  var minx: int = pt_x(f, 0)
  var miny: int = pt_y(f, 0)
  var maxx: int = minx
  var maxy: int = miny
  val () = bbox(f, 1, npts, minx, miny, maxx, maxy)
  val sc = sc1 * 2.0
  val sw = clamp_even(iround(n_i2d(maxx - minx) * sc) + 4)
  val sh = clamp_even(iround(n_i2d(maxy - miny) * sc) + 4)
  val () = ttf_rasterize(f, sc, minx, maxy, sw, sh)
  var x0: int = 0
  var y0: int = 0
  val () = ttf_upload_glyph(f, r, sw, sh, x0, y0)
  val top = iround(n_i2d(maxy) * sc1)
  val bx = iround(n_i2d(minx) * sc1)
in
  fill_g(g, if ax > 0 then ax else sw / 2, bx, top, sw / 2, sh / 2, x0, y0)
end

fun raster_ttf(f: !Font, r: !Rend, cp: int, gid: int, g: &gmet >> _): void = let
  val () = load_ttf_outline(f, gid)
  val adv = hmtx_adv(f, gid)
  val sc1 = scale_of(f)
  val ax = iround(n_i2d(adv) * sc1)
  val npts = f_get_npts(f)
in
  if npts <= 0 then fill_g(g, if ax > 0 then ax else idiv(f_get_px(f), 2), 0, font_asc(f), 0, 0, 0, 0)
  else ttf_glyph_bitmap(f, r, sc1, ax, npts, g)
end

fun raster_bitmap(f: !Font, r: !Rend, cp: int, g: &gmet >> _): void = let
  var x0: int = 0
  var y0: int = 0
  val w = if ieq(uf_wide(cp), 16) then 16 else 8
  val () = reserve(f, w, 16, x0, y0)
  val () = write_bitmap(f, x0, y0, cp)
  val () = upload(f, r, x0, y0, w, 16)
in
  fill_g(g, w, 0, 14, w, 16, x0, y0)
end

fun raster(f: !Font, r: !Rend, cp: int, g: &gmet >> _): void =
  if is_off(font_has_ttf(f)) then raster_bitmap(f, r, cp, g)
  else let
    val gid = cmap_gid(f, cp)
  in
    if gid <= 0 then
      if cp = CHAR_SPACE orelse cp = CHAR_TAB then fill_g(g, idiv(f_get_px(f), 2), 0, font_asc(f), 0, 0, 0, 0)
      else raster_bitmap(f, r, cp, g)
    else raster_ttf(f, r, cp, gid, g)
  end

implement font_glyph(f, r, cp, g) =
  if cache_get(f, cp, g) = 1 then ()
  else let
    val () = raster(f, r, cp, g)
  in
    cache_put(f, cp, g)
  end

fun u_land(a: int, m: int): int = anth_iand(a, m)

extern fun kern_search_exh(b: !Buf, off: int, n: int, left: int, right: int, lo: int, hi: int): int = "mac#anth_die_int"

fun kern_search_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, off: int, n: int, left: int, right: int, lo: int, hi: int): int =
  if recfuel > 0 then (
    if lo >= hi then 0
    else let
      val mid = (lo + hi) / 2
      val pl = u16(b, off + mid * 6)
      val pr = u16(b, off + mid * 6 + 2)
      val key = left * 65536 + right
      val mk = pl * 65536 + pr
    in
      if key = mk then i16(b, off + mid * 6 + 4)
      else if key < mk then kern_search_m(recfuel - 1, b, off, n, left, right, lo, mid)
      else kern_search_m(recfuel - 1, b, off, n, left, right, mid + 1, hi)
    end
  ) else kern_search_exh(b, off, n, left, right, lo, hi)

fun kern_search(b: !Buf, off: int, n: int, left: int, right: int, lo: int, hi: int): int = kern_search_m(airlock_nat(MAX_REC_FUEL), b, off, n, left, right, lo, hi)

fun kern_fmt0_value(f: !Font, p: int, left: int, right: int): int = let
  val np = file_u16(f, iadd(p, 6))
in
  case+ f of
  | @FONT(s) => let
      val k = kern_search(s.file, iadd(p, 14), np, left, right, 0, np)
    in
      fold@(f); k
    end
end

extern fun kern_at_exh(f: !Font, off: int, left: int, right: int, i: int, p: int, nt: int): int = "mac#anth_die_int"

fun kern_at_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, off: int, left: int, right: int, i: int, p: int, nt: int): int =
  if recfuel > 0 then (
    if i >= nt orelse i > 6 then 0
    else let
      val length = file_u16(f, p + 2)
      val cov = file_u16(f, p + 4)
      val fmt = u_land(cov, 255)
      val next = (if igt(length, 6) then iadd(p, length) else iadd(p, 6)) : int
    in
      if ieq(fmt, 0) then let
        val v = kern_fmt0_value(f, p, left, right)
      in
        if ine(v, 0) then v else kern_at_m(recfuel - 1, f, off, left, right, iadd(i, 1), next, nt)
      end else kern_at_m(recfuel - 1, f, off, left, right, iadd(i, 1), next, nt)
    end
  ) else kern_at_exh(f, off, left, right, i, p, nt)

fun kern_at(f: !Font, off: int, left: int, right: int, i: int, p: int, nt: int): int = kern_at_m(airlock_nat(MAX_REC_FUEL), f, off, left, right, i, p, nt)

implement font_kern(f, a, b) =
  if is_off(font_has_ttf(f)) orelse a <= 0 orelse b <= 0 then 0
  else let
    val off = f_get_kern_off(f)
  in
    if off < 0 then 0
    else let
      val ga = cmap_gid(f, a)
      val gb = cmap_gid(f, b)
      val nt = file_u16(f, off + 2)
      val fu = kern_at(f, off, ga, gb, 0, off + 4, nt)
      val sc = scale_of(f)
    in
      iround(n_i2d(fu) * sc)
    end
  end

extern fun atlas_sum_exh(f: !Font, x: int, y: int, w: int, h: int, row: int, acc: int): int = "mac#anth_die_int"

fun atlas_sum_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, x: int, y: int, w: int, h: int, row: int, acc: int): int =
  if recfuel > 0 then (
    if row >= h then acc
    else let
      fun cols(f: !Font, c: int, a: int): int =
        if c >= w then a else cols(f, c + 1, a + atlas_get(f, x + c, y + row))
    in
      atlas_sum_m(recfuel - 1, f, x, y, w, h, row + 1, cols(f, 0, acc))
    end
  ) else atlas_sum_exh(f, x, y, w, h, row, acc)

fun atlas_sum(f: !Font, x: int, y: int, w: int, h: int, row: int, acc: int): int = atlas_sum_m(airlock_nat(MAX_REC_FUEL), f, x, y, w, h, row, acc)

fun buf_append_str(b: &Buf >> _, s: string): void =
  buf_append(b, c_str_ptr(s), c_strlen(s))

fun buf_cat_range(dst: &Buf >> _, src: !Buf, st: int, en: int): void = let
  val n = buf_len(src)
  val s0 = if ilt(st, 0) then 0 else st
  val s1 = if igt(en, n) then n else en
  val count = if igt(s1, s0) then isub(s1, s0) else 0
in
  if igt(count, 0) then buf_append_at(dst, src, s0, count) else ()
end

fun is_ttf_filename(name: string): bool = let
  val n = c_strlen(name)
in
  if ilt(n, 4) then false
  else let
    val b0 = c_str_byte(name, isub(n, 4))
    val b1 = c_str_byte(name, isub(n, 3))
    val b2 = c_str_byte(name, isub(n, 2))
    val b3 = c_str_byte(name, isub(n, 1))
    val is_dot = ieq(b0, 46)
    val is_t1 = (ieq(b1, 116) orelse ieq(b1, 84))
    val is_t2 = (ieq(b2, 116) orelse ieq(b2, 84))
    val is_f  = (ieq(b3, 102) orelse ieq(b3, 70))
  in
    is_dot andalso is_t1 andalso is_t2 andalso is_f
  end
end

fun meta_put(meta: &Buf >> _, idx: int, poff: int, plen: int, noff: int, dlen: int): void = let
  val () = buf_ensure(meta, iadd(imul(idx, 16), 16))
  val () = buf_set32(meta, imul(idx, 4), poff)
  val () = buf_set32(meta, iadd(imul(idx, 4), 1), plen)
  val () = buf_set32(meta, iadd(imul(idx, 4), 2), noff)
  val () = buf_set32(meta, iadd(imul(idx, 4), 3), dlen)
in
end

fun scan_add_font(dir: string, nlen: int, name_buf: !Buf, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _): void = let
  var full_p = buf_make(512)
  val () = buf_append_str(full_p, dir)
  val () = buf_push(full_p, 47)
  val () = buf_cat_range(full_p, name_buf, 0, nlen)
  val poff = buf_len(paths)
  val plen = buf_len(full_p)
  val () = buf_cat_range(paths, full_p, 0, plen)
  val noff = buf_len(names)
  val dlen = (if ige(nlen, 4) then isub(nlen, 4) else nlen) : int
  val () = buf_cat_range(names, name_buf, 0, dlen)
  val idx = cnt
  val () = meta_put(meta, idx, poff, plen, noff, dlen)
  val () = cnt := iadd(cnt, 1)
  val () = buf_free(full_p)
in
end

extern fun scan_step_exh(dp: ptr, dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _, name_buf: &Buf >> _, isdir: &int >> _): void = "mac#anth_die_void"

fun scan_step_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dp: ptr, dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _, name_buf: &Buf >> _, isdir: &int >> _): void =
  if recfuel > 0 then (
    if ige(cnt, 100) orelse ieq(dir_next_buf(dp, name_buf, 255, isdir), 0) then ()
    else let
      val fname = buf_cstr(name_buf)
      val nlen = c_strlen(fname)
      val () = buf_set_len(name_buf, nlen)
      val first_b = (if igt(nlen, 0) then buf_get(name_buf, 0) else 0) : int
      val () =
        if ieq(first_b, 46) then ()
        else if is_dir_mark(dir_mark_of(isdir), DirYes) then scan_subdir(recfuel - 1, dir, nlen, name_buf, depth, paths, names, meta, cnt)
        else if is_ttf_filename(fname) then scan_add_font(dir, nlen, name_buf, paths, names, meta, cnt)
        else ()
    in
      scan_step_m(recfuel - 1, dp, dir, depth, paths, names, meta, cnt, name_buf, isdir)
    end
  ) else scan_step_exh(dp, dir, depth, paths, names, meta, cnt, name_buf, isdir)

and scan_subdir {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dir: string, nlen: int, name_buf: !Buf, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _): void =
  if recfuel > 0 then let
    var sub_dir = buf_make(512)
    val () = buf_append_str(sub_dir, dir)
    val () = buf_push(sub_dir, 47)
    val () = buf_cat_range(sub_dir, name_buf, 0, nlen)
    val () = buf_push(sub_dir, 0)
    val () = scan_fonts_rec(recfuel - 1, buf_cstr(sub_dir), iadd(depth, 1), paths, names, meta, cnt)
    val () = buf_free(sub_dir)
  in
  end else ()

and scan_fonts_rec {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _): void =
  if recfuel > 0 then (
    if igt(depth, 4) orelse ige(cnt, 100) then ()
    else let
      val dp = dir_open(dir)
    in
      if ptr_is_null(dp) then ()
      else let
        var name_buf = buf_make(256)
        var isdir: int = 0
        val () = scan_step_m(recfuel - 1, dp, dir, depth, paths, names, meta, cnt, name_buf, isdir)
        val () = buf_free(name_buf)
        val () = dir_close(dp)
      in
      end
    end
  ) else ()

fun scan_step(dp: ptr, dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _, name_buf: &Buf >> _, isdir: &int >> _): void = scan_step_m(airlock_nat(MAX_REC_FUEL), dp, dir, depth, paths, names, meta, cnt, name_buf, isdir)

implement font_scan_fonts(dir, paths, names, meta, cnt) = let
  val () = buf_set_len(paths, 0)
  val () = buf_set_len(names, 0)
  val () = buf_set_len(meta, 0)
  val () = cnt := 0
in
  scan_fonts_rec(airlock_nat(MAX_REC_FUEL), dir, 0, paths, names, meta, cnt)
end

fun load_first_scanned(f: !Font, paths: !Buf, meta: !Buf, cnt: int): bool =
  if igt(cnt, 0) then let
    val poff = buf_get32(meta, 0)
    val plen = buf_get32(meta, 1)
    var first_p = buf_make(iadd(plen, 1))
    val () = buf_cat_range(first_p, paths, poff, iadd(poff, plen))
    val () = buf_push(first_p, 0)
    val res = font_use_file(f, buf_cstr(first_p))
    val () = buf_free(first_p)
  in
    res
  end else false

fun load_scanned_default(f: !Font): bool = let
  var paths = buf_make(1024)
  var names = buf_make(512)
  var meta = buf_make(256)
  var cnt: int = 0
  val () = font_scan_fonts("fonts", paths, names, meta, cnt)
  val ok = load_first_scanned(f, paths, meta, cnt)
  val () = buf_free(paths)
  val () = buf_free(names)
  val () = buf_free(meta)
in
  ok
end

fun load_fontconfig_default(f: !Font): bool = let
  var b = buf_make(512)
  val n = c_fc_font_buf(b, 511)
  val s = buf_cstr(b)
  val hit = ieq(n, 1) andalso igt(c_strlen(s), 0) andalso font_use_file(f, s)
  val () = buf_free(b)
in
  hit
end

fun load_default(f: !Font): bool = let
  val env = c_getenv("ANTHRACITE_FONT")
in
  if igt(c_strlen(env), 0) andalso font_use_file(f, env) then true
  else if load_scanned_default(f) then true
  else if load_fontconfig_default(f) then true
  else font_use_file(f, "/nix/store/v3n8r3sy38l5f1sj76azj1n4n0ndd6a7-dejavu-fonts-2.37/share/fonts/truetype/DejaVuSansMono.ttf")
end

implement font_load_default(f) = load_default(f)

fun glyph_ink65(f: !Font, r: !Rend, g: &gmet >> _): int = let
  val () = font_glyph(f, r, 65, g)
in
  atlas_sum(f, g.x0, g.y0, g.bw, g.bh, 0, 0)
end

fun kern_selftest(): int = let
  val kb = buf_make(16)
  val () = buf_set(kb, 0, 0)
  val () = buf_set(kb, 1, 1)
  val () = buf_set(kb, 2, 0)
  val () = buf_set(kb, 3, 2)
  val () = buf_set(kb, 4, 255)
  val () = buf_set(kb, 5, 226)
  val kv = kern_search(kb, 0, 1, 1, 2, 0, 1)
  val () = buf_free(kb)
in
  (if ieq(kv, isub(0, 30)) then 1 else 0)
end

implement font_selftest(r) = let
  val f = font_open()
  var g: gmet = @{ax= 0, bx= 0, top= 0, bw= 0, bh= 0, x0= 0, y0= 0, ok= Off}
  val ink = glyph_ink65(f, r, g)
  val ok1 = (if igt(g.bw, 0) andalso igt(ink, 0) then 1 else 0) : int
  val ok2 = kern_selftest()
  val loaded = load_default(f)
  val gid = (if loaded then cmap_gid(f, 65) else 0) : int
  val inkA = glyph_ink65(f, r, g)
  val axA = g.ax
  val bwA = g.bw
  val jb_ok = font_use_file(f, "fonts/JetBrains-Mono-Medium/JetBrainsMono-Regular.ttf")
  val inkJB = glyph_ink65(f, r, g)
  val sc_ok = font_use_file(f, "fonts/Source-Code-Pro-Regular/sourcecodepro/SourceCodePro-Regular.ttf")
  val inkSC = glyph_ink65(f, r, g)
  val () = font_free(f)
  val ok3 = (if loaded andalso igt(gid, 0) andalso igt(axA, 0) andalso igt(inkA, 20) andalso igt(inkJB, 20) andalso igt(inkSC, 20) andalso jb_ok andalso sc_ok then 1 else 0) : int
in
  (if ieq(ok1, 1) andalso ieq(ok2, 1) andalso ieq(ok3, 1) then 1 else 0)
end
