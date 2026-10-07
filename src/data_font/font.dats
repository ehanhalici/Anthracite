#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
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
, num_h= int, nglyph= int, loca_fmt= int
, cmap_off= int, glyf_off= int, loca_off= int, hmtx_off= int, kern_off= int
, npts= int, nends= int, nedges= int
, pen_x= int, pen_y= int, row_h= int
, aw= int, ah= int, tex= uint
, has_ttf= int, line_h= int, asc_px= int
}
assume Font = Font_

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
  if short = 1 then iif(same = 1, byte, isub(0, byte)) else iif(same = 1, 0, word)
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
, num_h= 0, nglyph= 0, loca_fmt= 0
, cmap_off= ~1, glyf_off= ~1, loca_off= ~1, hmtx_off= ~1, kern_off= ~1
, npts= 0, nends= 0, nedges= 0
, pen_x= 1, pen_y= 1, row_h= 0
, aw= AW, ah= AH, tex= ztex()
, has_ttf= 0, line_h= 18, asc_px= 14
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

fun f_int(f: !Font, which: int): int =
  case+ f of
  | @FONT(s) => let
      val v =
        if which = 0 then s.px
        else if which = 1 then s.units
        else if which = 2 then s.asc
        else if which = 3 then s.desc
        else if which = 4 then s.lgap
        else if which = 5 then s.num_h
        else if which = 6 then s.nglyph
        else if which = 7 then s.loca_fmt
        else if which = 8 then s.cmap_off
        else if which = 9 then s.glyf_off
        else if which = 10 then s.loca_off
        else if which = 11 then s.hmtx_off
        else if which = 12 then s.kern_off
        else if which = 13 then s.npts
        else if which = 14 then s.nends
        else if which = 15 then s.nedges
        else if which = 16 then s.pen_x
        else if which = 17 then s.pen_y
        else if which = 18 then s.row_h
        else if which = 19 then s.aw
        else if which = 20 then s.ah
        else if which = 21 then s.has_ttf
        else if which = 22 then s.line_h
        else s.asc_px
    in
      fold@(f); v
    end

fun f_set(f: !Font, which: int, v: int): void =
  case+ f of
  | @FONT(s) => let
      val () =
        if which = 0 then s.px := v
        else if which = 1 then s.units := v
        else if which = 2 then s.asc := v
        else if which = 3 then s.desc := v
        else if which = 4 then s.lgap := v
        else if which = 5 then s.num_h := v
        else if which = 6 then s.nglyph := v
        else if which = 7 then s.loca_fmt := v
        else if which = 8 then s.cmap_off := v
        else if which = 9 then s.glyf_off := v
        else if which = 10 then s.loca_off := v
        else if which = 11 then s.hmtx_off := v
        else if which = 12 then s.kern_off := v
        else if which = 13 then s.npts := v
        else if which = 14 then s.nends := v
        else if which = 15 then s.nedges := v
        else if which = 16 then s.pen_x := v
        else if which = 17 then s.pen_y := v
        else if which = 18 then s.row_h := v
        else if which = 21 then s.has_ttf := v
        else if which = 22 then s.line_h := v
        else s.asc_px := v
    in
      fold@(f)
    end

implement font_has_ttf(f) = f_int(f, 21)
implement font_line_h(f) = f_int(f, 22)
implement font_asc(f) = f_int(f, 23)
implement font_atlas_w(f) = f_int(f, 19)
implement font_atlas_h(f) = f_int(f, 20)

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

fun file_len(f: !Font): int =
  case+ f of
  | @FONT(s) => let
      val n = buf_len(s.file)
    in
      fold@(f); n
    end

fun find_table(f: !Font, a: int, c: int, d: int, e: int, i: int, n: int): int =
  if i >= n then ~1
  else let
    val o = 12 + i * 16
    val hit = (
      if file_u8(f, o) = a andalso file_u8(f, o + 1) = c
        andalso file_u8(f, o + 2) = d andalso file_u8(f, o + 3) = e
      then 1 else 0
    ): int
  in
    if hit = 1 then file_u32(f, o + 8) else find_table(f, a, c, d, e, i + 1, n)
  end

fun clear_cache(f: !Font, i: int): void =
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
    clear_cache(f, i + 1)
  end

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

fun parse_tables(f: !Font): int = let
  val ntab = file_u16(f, 4)
  val cmap = find_table(f, 99, 109, 97, 112, 0, ntab)
  val glyf = find_table(f, 103, 108, 121, 102, 0, ntab)
  val loca = find_table(f, 108, 111, 99, 97, 0, ntab)
  val hmtx = find_table(f, 104, 109, 116, 120, 0, ntab)
  val hhea = find_table(f, 104, 104, 101, 97, 0, ntab)
  val maxp = find_table(f, 109, 97, 120, 112, 0, ntab)
  val head = find_table(f, 104, 101, 97, 100, 0, ntab)
  val kern = find_table(f, 107, 101, 114, 110, 0, ntab)
  val ok = (
    if cmap < 0 orelse glyf < 0 orelse loca < 0 orelse hmtx < 0
      orelse hhea < 0 orelse maxp < 0 orelse head < 0
    then 0 else 1
  ): int
in
  if ok = 0 then 0
  else let
    val units: int = file_u16(f, head + 18)
    val locaf: int = file_i16(f, head + 50)
    val asc: int = file_i16(f, hhea + 4)
    val desc: int = file_i16(f, hhea + 6)
    val lgap: int = file_i16(f, hhea + 8)
    val nh: int = file_u16(f, hhea + 34)
    val ng: int = file_u16(f, maxp + 4)
    val want = f_int(f, 0)
    val px: int = if igt(want, 0) then want else 16
    val den: int = if igt(units, 0) then units else 1
    val span = iadd(isub(asc, desc), lgap)
    val numer: int = imul(span, px)
    val lh0: int = idiv(numer, den)
    val lh: int = if ilt(lh0, 12) then 12 else lh0
    val ap: int = idiv(imul(asc, px), den)
    val () = f_set(f, 1, units)
    val () = f_set(f, 2, asc)
    val () = f_set(f, 3, desc)
    val () = f_set(f, 4, lgap)
    val () = f_set(f, 5, nh)
    val () = f_set(f, 6, ng)
    val () = f_set(f, 7, if locaf <> 0 then 1 else 0: int)
    val () = f_set(f, 8, cmap)
    val () = f_set(f, 9, glyf)
    val () = f_set(f, 10, loca)
    val () = f_set(f, 11, hmtx)
    val () = f_set(f, 12, kern)
    val () = f_set(f, 0, px)
    val () = f_set(f, 22, lh)
    val () = f_set(f, 23, if igt(ap, 0) then ap else 12)
    val () = f_set(f, 21, 1)
    val () = clear_atlas(f)
    val () = clear_cache(f, 0)
  in
    1
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

implement font_set_px(f, px0) = let
  val px = if ilt(px0, 8) then 8 else if igt(px0, 48) then 48 else px0
  val same = if ieq(f_int(f, 0), px) then 1 else 0
in
  if ieq(same, 1) then ()
  else let
    val units = f_int(f, 1)
    val asc = f_int(f, 2)
    val desc = f_int(f, 3)
    val lgap = f_int(f, 4)
    val den = if igt(units, 0) then units else 1
    val span = iadd(isub(asc, desc), lgap)
    val numer: int = imul(span, px)
    val lh0 = if igt(units, 0) then idiv(numer, den) else iadd(px, 2)
    val lh = if ilt(lh0, px) then px else lh0
    val ap = if igt(units, 0) then idiv(imul(asc, px), den) else isub(px, 2)
    val () = f_set(f, 0, px)
    val () = f_set(f, 22, if ilt(lh, 8) then 8 else lh)
    val () = f_set(f, 23, if igt(ap, 0) then ap else 12)
    val () = clear_atlas(f)
    val () = clear_cache(f, 0)
  in
    drop_tex(f)
  end
end

implement font_use_file(f, path) = let
  val sz = fs_size(path)
in
  if sz <= 12 orelse sz > 20000000 then 0
  else let
    val fd = fs_open_read(path)
  in
    if fd < 0 then 0
    else let
      val b0 = take_file(f)
      var b = b0
      val () = buf_resize(b, sz + 1)
      val n = fs_read(fd, buf_ptr(b), sz)
      val () = buf_set_len(b, if n > 0 then n else 0)
      val () = fs_close(fd)
      val () = put_file(f, b)
    in
      if n < 12 then 0
      else let
        val ok = parse_tables(f)
        val () = if ok = 1 then let
          val cur_px = f_int(f, 0)
          val px_val = if cur_px >= 8 then cur_px else 18
          val () = f_set(f, 0, 0)
          val () = font_set_px(f, px_val)
        in
        end else ()
      in
        ok
      end
    end
  end
end

fun cmap_search(f: !Font, i: int, segs: int, cp: int, ends: int, starts: int, deltas: int, offs: int): int =
  if i >= segs then 0
  else let
    val ec: int = file_u16(f, iadd(ends, imul(i, 2)))
  in
    if cp > ec then cmap_search(f, i + 1, segs, cp, ends, starts, deltas, offs)
    else let
      val sc: int = file_u16(f, iadd(starts, imul(i, 2)))
    in
      if cp < sc then 0
      else let
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
    end
  end

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

fun cmap_find(f: !Font, i: int, nt: int, cmap: int): int =
  if i >= nt then ~1
  else let
    val at: int = iadd(iadd(cmap, 4), imul(i, 8))
    val plat: int = file_u16(f, at)
    val enc: int = file_u16(f, iadd(at, 2))
    val off: int = file_u32(f, iadd(at, 4))
    val use = (
      if plat = 3 andalso enc = 1 then 1
      else if plat = 0 andalso enc = 3 then 1
      else if plat = 0 andalso enc = 4 then 1
      else 0
    ): int
  in
    if use = 1 then iadd(cmap, off) else cmap_find(f, i + 1, nt, cmap)
  end

fun cmap_gid(f: !Font, cp: int): int = let
  val cmap: int = f_int(f, 8)
  val nt = (if cmap < 0 then 0 else file_u16(f, iadd(cmap, 2))): int
  val sub = (if cmap < 0 then ~1 else cmap_find(f, 0, nt, cmap)): int
in
  if sub < 0 then 0
  else let
    val fmt: int = file_u16(f, sub)
  in
    if fmt = 4 then cmap_fmt4(f, sub, cp) else 0
  end
end

fun loca_at(f: !Font, gid: int): int = let
  val off = f_int(f, 10)
  val fmt = f_int(f, 7)
in
  if off < 0 orelse gid < 0 then 0
  else if fmt = 0 then file_u16(f, off + gid * 2) * 2
  else file_u32(f, off + gid * 4)
end

fun hmtx_adv(f: !Font, gid: int): int = let
  val off = f_int(f, 11)
  val nh = f_int(f, 5)
  val i = (if gid < nh then gid else if nh > 0 then isub(nh, 1) else 0): int
in
  if off < 0 orelse nh <= 0 then 0 else file_u16(f, iadd(off, imul(i, 4)))
end

fun hmtx_lsb(f: !Font, gid: int): int = let
  val off = f_int(f, 11)
  val nh = f_int(f, 5)
in
  if off < 0 orelse nh <= 0 then 0
  else if gid < nh then file_i16(f, off + gid * 4 + 2)
  else file_i16(f, off + nh * 4 + (gid - nh) * 2)
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

fun edge_push(f: !Font, x0: int, y0: int, x1: int, y1: int): void =
  if x0 = x1 andalso y0 = y1 then ()
  else let
    val n = f_int(f, 15)
  in
    if n >= MAXE then ()
    else let
      val () =
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
    in
    end
  end

fun edge_get(f: !Font, e: int, k: int): int =
  case+ f of
  | @FONT(s) => let
      val v = buf_get32(s.edges, e * 4 + k)
    in
      fold@(f); v
    end

fun quad(f: !Font, x0: int, y0: int, x1: int, y1: int, x2: int, y2: int, depth: int): void =
  if depth <= 0 then edge_push(f, x0, y0, x2, y2)
  else let
    val mx01 = (x0 + x1) / 2
    val my01 = (y0 + y1) / 2
    val mx12 = (x1 + x2) / 2
    val my12 = (y1 + y2) / 2
    val mx = (mx01 + mx12) / 2
    val my = (my01 + my12) / 2
    val () = quad(f, x0, y0, mx01, my01, mx, my, depth - 1)
  in
    quad(f, mx, my, mx12, my12, x2, y2, depth - 1)
  end

fun set_x(f: !Font, i: int, x: int): void =
  case+ f of
  | @FONT(s) => let
      val () = buf_set32(s.xs, i, x)
    in
      fold@(f)
    end

fun set_y(f: !Font, i: int, y: int): void =
  case+ f of
  | @FONT(s) => let
      val () = buf_set32(s.ys, i, y)
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

fun read_ends(f: !Font, i: int, ncont: int, p: int, base: int, eb: int): int =
  if i >= ncont then p
  else let
    val e = file_u16(f, p)
    val () = end_set(f, eb + i, base + e)
  in
    read_ends(f, i + 1, ncont, p + 2, base, eb)
  end

fun flag_run(f: !Font, i: int, np: int, p: int, base: int): int =
  if i >= np then p
  else let
    val flg = file_u8(f, p)
    val rep0 = (if bit(flg, 8) = 1 then file_u8(f, p + 1) else 0): int
    val rep = (if rep0 < 0 then 1 else rep0 + 1): int
    val p2 = iif(bit(flg, 8) = 1, iadd(p, 2), iadd(p, 1))
    fun put(f: !Font, k: int): void =
      if k >= rep orelse i + k >= np then ()
      else let
        val () = set_fl(f, iadd(iadd(base, i), k), flg)
      in
        put(f, iadd(k, 1))
      end
    val () = put(f, 0)
    val step = iif(iadd(i, rep) > np, isub(np, i), rep)
  in
    flag_run(f, iadd(i, step), np, p2, base)
  end

fun xs_loop(f: !Font, i: int, np: int, p: int, x: int, base: int): int =
  if i >= np then p
  else let
    val flg = pt_on(f, base + i)
    val short = bit(flg, 2)
    val same = bit(flg, 16)
    val dx = delta_of(short, same, file_u8(f, p), file_i16(f, p))
    val p2 = adv_p(short, same, p)
    val () = set_x(f, iadd(base, i), iadd(x, dx))
  in
    xs_loop(f, iadd(i, 1), np, p2, iadd(x, dx), base)
  end

fun ys_loop(f: !Font, i: int, np: int, p: int, y: int, base: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double): void =
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
    ys_loop(f, iadd(i, 1), np, p2, ry, base, dx, dy, xx, yy, xy, yx)
  end

fun decode_simple(f: !Font, p0: int, ncont: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double): void = let
  val base = f_int(f, 13)
  val eb = f_int(f, 14)
in
  if ncont <= 0 then ()
  else let
    val p1 = read_ends(f, 0, ncont, p0, base, eb)
    val ninstr = file_u16(f, p1)
    val p2 = p1 + 2 + ninstr
    val last = end_get(f, eb + ncont - 1)
    val np = last - base + 1
  in
    if np <= 0 orelse np > MAXP orelse base + np >= OUT0 then ()
    else let
      val p3 = flag_run(f, 0, np, p2, base)
      val p4 = xs_loop(f, 0, np, p3, 0, base)
      val () = ys_loop(f, 0, np, p4, 0, base, dx, dy, xx, yy, xy, yx)
      val () = f_set(f, 14, eb + ncont)
      val () = f_set(f, 13, base + np)
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

fun load_glyph(f: !Font, gid: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double, depth: int): void =
  if depth > 8 orelse gid <= 0 then ()
  else let
    val ng = f_int(f, 6)
  in
    if gid >= ng then ()
    else let
      val a = loca_at(f, gid)
      val b = loca_at(f, gid + 1)
      val glyf = f_int(f, 9)
    in
      if b <= a orelse glyf < 0 then ()
      else let
        val p = glyf + a
        val ncont = file_i16(f, p)
      in
        if ncont > 0 then decode_simple(f, p + 10, ncont, dx, dy, xx, yy, xy, yx)
        else if ncont < 0 then comp_loop(f, p + 10, dx, dy, xx, yy, xy, yx, depth, 48)
        else ()
      end
    end
  end

and comp_loop(f: !Font, p: int, dx: double, dy: double, xx: double, yy: double, xy: double, yx: double, depth: int, left: int): void =
  if left <= 0 then ()
  else let
    val flags = file_u16(f, p)
    val gid = file_u16(f, iadd(p, 2))
    val q0 = iadd(p, 4)
    val words = bit(flags, 1)
    val arg1 = iif(ieq(words, 1), file_i16(f, q0), file_i8(f, q0))
    val arg2 = iif(ieq(words, 1), file_i16(f, iadd(q0, 2)), file_i8(f, iadd(q0, 1)))
    var q: int = iif(ieq(words, 1), iadd(q0, 4), iadd(q0, 2))
    var cxx: double = 1.0
    var cyy: double = 1.0
    var cxy: double = 0.0
    var cyx: double = 0.0
    val () =
      if bit(flags, 8) = 1 then let
        val s = f214(f, q)
        val () = cxx := s
        val () = cyy := s
      in
        q := iadd(q, 2)
      end else if bit(flags, 64) = 1 then let
        val () = cxx := f214(f, q)
        val () = cyy := f214(f, iadd(q, 2))
      in
        q := iadd(q, 4)
      end else if bit(flags, 128) = 1 then let
        val () = cxx := f214(f, q)
        val () = cxy := f214(f, iadd(q, 2))
        val () = cyx := f214(f, iadd(q, 4))
        val () = cyy := f214(f, iadd(q, 6))
      in
        q := iadd(q, 8)
      end else ()
    val adx = n_i2d(arg1)
    val ady = n_i2d(arg2)
    val nxx = xx * cxx + xy * cyx
    val nxy = xx * cxy + xy * cyy
    val nyx = yx * cxx + yy * cyx
    val nyy = yx * cxy + yy * cyy
    val ndx = xx * adx + xy * ady + dx
    val ndy = yx * adx + yy * ady + dy
    val () =
      if bit(flags, 2) = 1 then load_glyph(f, gid, ndx, ndy, nxx, nyy, nxy, nyx, depth + 1)
      else ()
  in
    if bit(flags, 32) = 1 then comp_loop(f, q, dx, dy, xx, yy, xy, yx, depth, left - 1)
    else ()
  end

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

fun rot_copy(f: !Font, n: int, s: int, i: int): void =
  if i >= n then ()
  else let
    val src = OUT0 + imod(s + i, n)
    val () = pt_set(f, 5200 + i, pt_x(f, src), pt_y(f, src), pt_on(f, src))
  in
    rot_copy(f, n, s, i + 1)
  end

fun rot_back(f: !Font, n: int, i: int): void =
  if i >= n then ()
  else let
    val () = pt_set(f, OUT0 + i, pt_x(f, 5200 + i), pt_y(f, 5200 + i), pt_on(f, 5200 + i))
  in
    rot_back(f, n, i + 1)
  end

fun find_on(f: !Font, n: int, i: int): int =
  if i >= n then 0
  else if pt_on(f, OUT0 + i) <> 0 then i else find_on(f, n, i + 1)

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
      val n2 = if ieq(curr_on, 0) andalso ieq(prev_on, 0) then let
        val mx = idiv(iadd(pt_x(f, prev_i), pt_x(f, curr_i)), 2)
        val my = idiv(iadd(pt_y(f, prev_i), pt_y(f, curr_i)), 2)
      in
        push_out(f, n, mx, my, 1)
      end else n
      val n3 = push_out(f, n2, pt_x(f, curr_i), pt_y(f, curr_i), curr_on)
    in
      loop(f, iadd(k, 1), clen, a, n3)
    end
in
  if ilt(clen, 2) then 0 else loop(f, 0, clen, a, 0)
end

fun walk_contour(f: !Font, n: int, minx: int, maxy: int, sc: double): void = let
  fun walk(f: !Font, i: int, n: int, minx: int, maxy: int, sc: double): void =
    if i >= n then ()
    else let
      val p0 = imod(i, n)
      val p1 = imod(iadd(i, 1), n)
      val on1 = pt_on(f, iadd(OUT0, p1))
    in
      if on1 <> 0 then let
        val () = emit_xy(f, pt_x(f, iadd(OUT0, p0)), pt_y(f, iadd(OUT0, p0)),
                            pt_x(f, iadd(OUT0, p1)), pt_y(f, iadd(OUT0, p1)), minx, maxy, sc)
      in
        walk(f, iadd(i, 1), n, minx, maxy, sc)
      end else let
        val p2 = imod(iadd(i, 2), n)
        val x0 = pt_x(f, iadd(OUT0, p0))
        val y0 = pt_y(f, iadd(OUT0, p0))
        val x1 = pt_x(f, iadd(OUT0, p1))
        val y1 = pt_y(f, iadd(OUT0, p1))
        val x2 = pt_x(f, iadd(OUT0, p2))
        val y2 = pt_y(f, iadd(OUT0, p2))
        val () = quad(f, pix_x(x0, minx, sc), pix_y(y0, maxy, sc),
                         pix_x(x1, minx, sc), pix_y(y1, maxy, sc),
                         pix_x(x2, minx, sc), pix_y(y2, maxy, sc), 3)
      in
        walk(f, iadd(i, 2), n, minx, maxy, sc)
      end
    end
in
  if igt(n, 1) then walk(f, 0, n, minx, maxy, sc) else ()
end

fun one_contour(f: !Font, a: int, b: int, minx: int, maxy: int, sc: double): void =
  if b < a then ()
  else let
    val n1 = expand_contour(f, a, b)
    val s = iif(n1 > 0, find_on(f, n1, 0), 0)
    val () = if ine(s, 0) then let
      val () = rot_copy(f, n1, s, 0)
    in
      rot_back(f, n1, 0)
    end else ()
  in
    walk_contour(f, n1, minx, maxy, sc)
  end

fun contours(f: !Font, ci: int, nends: int, minx: int, maxy: int, sc: double): void =
  if ci >= nends then ()
  else let
    val a = iif(ci = 0, 0, iadd(end_get(f, isub(ci, 1)), 1))
    val b = end_get(f, ci)
    val () = one_contour(f, a, b, minx, maxy, sc)
  in
    contours(f, ci + 1, nends, minx, maxy, sc)
  end

fun bbox(f: !Font, i: int, n: int, minx: &int, miny: &int, maxx: &int, maxy: &int): void =
  if i >= n then ()
  else let
    val x = pt_x(f, i)
    val y = pt_y(f, i)
    val () = if x < minx then minx := x else ()
    val () = if y < miny then miny := y else ()
    val () = if x > maxx then maxx := x else ()
    val () = if y > maxy then maxy := y else ()
  in
    bbox(f, i + 1, n, minx, miny, maxx, maxy)
  end

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

fun atlas_ptr(f: !Font, x: int, y: int): ptr =
  case+ f of
  | @FONT(s) => let
      val cap = buf_cap(s.atlas)
      val p = mem_ptr_at(buf_ptr(s.atlas), cap, y * s.aw + x)
    in
      fold@(f); p
    end

fun collect(f: !Font, y: int, e: int, ne: int, nc: int): int =
  if e >= ne orelse nc >= 100 then nc
  else let
    val y0 = edge_get(f, e, 1)
    val y1 = edge_get(f, e, 3)
  in
    if y0 = y1 then collect(f, y, e + 1, ne, nc)
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
      collect(f, y, e + 1, ne, nc + 1)
    end else collect(f, y, e + 1, ne, nc)
  end

fun cross_swap(f: !Font, i: int): void =
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
      cross_swap(f, i - 1)
    end
  end

fun cross_sort(f: !Font, n: int, i: int): void =
  if i >= n then ()
  else let
    val () = cross_swap(f, i)
  in
    cross_sort(f, n, i + 1)
  end

fun paint(f: !Font, sw: int, y: int, x0: int, x1: int): void = let
  val a = iif(x0 < 0, 0, x0)
  val b = iif(x1 > sw, sw, x1)
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

fun wind(f: !Font, sw: int, y: int, n: int, i: int, w: int, prev: int): void =
  if i >= n then ()
  else let
    val x = end_get(f, i * 2)
    val d = end_get(f, i * 2 + 1)
    val () = if w <> 0 then paint(f, sw, y, prev, x) else ()
  in
    wind(f, sw, y, n, i + 1, w + d, x)
  end

fun scan_rows(f: !Font, sw: int, sh: int, y: int): void =
  if y >= sh then ()
  else let
    val ne = f_int(f, 15)
    val nc = collect(f, y, 0, ne, 0)
    val () = cross_sort(f, nc, 1)
    val () = wind(f, sw, y, nc, 0, 0, 0)
  in
    scan_rows(f, sw, sh, y + 1)
  end

fun blit(f: !Font, x0: int, y0: int, sw: int, bw: int, bh: int, y: int): void =
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
    blit(f, x0, y0, sw, bw, bh, y + 1)
  end

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
  val () = g.ok := 1
in
end

fun cache_probe(f: !Font, cp: int, g: &gmet >> _, h0: int, k: int): int =
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
    end else cache_probe(f, cp, g, h0, iadd(k, 1))
  end

fun cache_get(f: !Font, cp: int, g: &gmet >> _): int =
  cache_probe(f, cp, g, imod(iadd(imul(cp, 17), 3), 1024), 0)

fun cache_put(f: !Font, cp: int, g: &gmet): void = let
  val h0 = imod(cp * 17 + 3, 1024)
  fun probe(f: !Font, k: int): int =
    if k >= 24 then h0
    else let
      val slot = imod(h0 + k, 1024)
    in
      if cache_i(f, slot, 0) = 0 orelse cache_i(f, slot, 1) = cp then slot else probe(f, k + 1)
    end
  val slot = probe(f, 0)
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

fun clamp_even(n: int): int = let
  val c = iif(n < 2, 2, iif(n > 254, 254, n))
in
  isub(c, imod(c, 2))
end

fun reserve(f: !Font, bw: int, bh: int, x: &int >> _, y: &int >> _): void = let
  val aw = f_int(f, 19)
  val ah = f_int(f, 20)
  val px0 = f_int(f, 16)
  val py0 = f_int(f, 17)
  val rh0 = f_int(f, 18)
  val wrap = iif(iadd(iadd(px0, bw), 1) >= aw, 1, 0)
  val px1 = iif(wrap = 1, 1, px0)
  val py1 = iif(wrap = 1, iadd(iadd(py0, rh0), 1), py0)
  val rh1 = iif(wrap = 1, 0, rh0)
  val boom = iif(iadd(iadd(py1, bh), 1) >= ah, 1, 0)
  val () = if boom = 1 then let
    val () = clear_atlas(f)
    val () = clear_cache(f, 0)
  in
    drop_tex(f)
  end else ()
  val x0 = iif(boom = 1, 1, px1)
  val y0 = iif(boom = 1, 1, py1)
  val rh = iif(boom = 1, 0, rh1)
  val () = f_set(f, 16, iadd(iadd(x0, bw), 1))
  val () = f_set(f, 17, y0)
  val () = f_set(f, 18, if bh > rh then bh else rh)
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

fun upload(f: !Font, r: !Rend, x: int, y: int, w: int, h: int): void =
  if w <= 0 orelse h <= 0 then ()
  else let
    val () = ensure_tex(f, r)
    val tex = font_tex(f)
    val aw = font_atlas_w(f)
    val p = atlas_ptr(f, x, y)
    val () = glPixelStorei(GL_UNPACK_ROW_LENGTH, aw)
    val () = rend_tex_sub_r8(r, tex, x, y, w, h, p)
    val () = glPixelStorei(GL_UNPACK_ROW_LENGTH, 0)
  in
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

fun write_bitmap(f: !Font, x0: int, y0: int, cp: int): void = let
  val ww = if ieq(uf_wide(cp), 16) then 16 else 8
  fun pix(f: !Font, r: int, c: int): void =
    if r >= 16 then ()
    else if c >= ww then pix(f, r + 1, 0)
    else let
      val colb = if c >= 8 then 1 else 0
      val bitn = if c >= 8 then c - 8 else c
      val on = bit(uf_byte(cp, r, colb), colmask(bitn))
      val () = if ieq(on, 1) then atlas_set(f, x0 + c, y0 + r, 255) else ()
    in
      pix(f, r, c + 1)
    end
  fun box(f: !Font, r: int, c: int): void =
    if r >= 16 then ()
    else if c >= 8 then box(f, r + 1, 0)
    else let
      val edge = if ieq(r, 0) orelse ieq(r, 15) orelse ieq(c, 0) orelse ieq(c, 7) then 1 else 0
      val () = if ieq(edge, 1) then atlas_set(f, x0 + c, y0 + r, 255) else ()
    in
      box(f, r, c + 1)
    end
in
  if ieq(uf_wide(cp), 0) then box(f, 0, 0) else pix(f, 0, 0)
end

fun scale_of(f: !Font): double = let
  val units = f_int(f, 1)
  val px = f_int(f, 0)
  val den = if units > 0 then units else 1
in
  n_i2d(px) / n_i2d(den)
end

fun raster_ttf(f: !Font, r: !Rend, cp: int, gid: int, g: &gmet >> _): void = let
  val () = f_set(f, 13, 0)
  val () = f_set(f, 14, 0)
  val () = f_set(f, 15, 0)
  val () = load_glyph(f, gid, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0)
  val adv = hmtx_adv(f, gid)
  val sc1 = scale_of(f)
  val ax = iround(n_i2d(adv) * sc1)
  val npts = f_int(f, 13)
in
  if npts <= 0 then fill_g(g, if ax > 0 then ax else f_int(f, 0) / 2, 0, f_int(f, 23), 0, 0, 0, 0)
  else let
    var minx: int = pt_x(f, 0)
    var miny: int = pt_y(f, 0)
    var maxx: int = minx
    var maxy: int = miny
    val () = bbox(f, 1, npts, minx, miny, maxx, maxy)
    val sc = sc1 * 2.0
    val sw = clamp_even(iround(n_i2d(maxx - minx) * sc) + 4)
    val sh = clamp_even(iround(n_i2d(maxy - miny) * sc) + 4)
    val () = contours(f, 0, f_int(f, 14), minx, maxy, sc)
    val () = zero_cov(f)
    val () = scan_rows(f, sw, sh, 0)
    val bw = sw / 2
    val bh = sh / 2
    var x0: int = 0
    var y0: int = 0
    val () = reserve(f, bw, bh, x0, y0)
    val () = blit(f, x0, y0, sw, bw, bh, 0)
    val () = upload(f, r, x0, y0, bw, bh)
    val top = iround(n_i2d(maxy) * sc1)
    val bx = iround(n_i2d(minx) * sc1)
  in
    fill_g(g, if ax > 0 then ax else bw, bx, top, bw, bh, x0, y0)
  end
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
  if f_int(f, 21) = 0 then raster_bitmap(f, r, cp, g)
  else let
    val gid = cmap_gid(f, cp)
  in
    if gid <= 0 then
      if cp = 32 orelse cp = 9 then fill_g(g, f_int(f, 0) / 2, 0, f_int(f, 23), 0, 0, 0, 0)
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

fun kern_search(b: !Buf, off: int, n: int, left: int, right: int, lo: int, hi: int): int =
  if lo >= hi then 0
  else let
    val mid = (lo + hi) / 2
    val pl = u16(b, off + mid * 6)
    val pr = u16(b, off + mid * 6 + 2)
    val key = left * 65536 + right
    val mk = pl * 65536 + pr
  in
    if key = mk then i16(b, off + mid * 6 + 4)
    else if key < mk then kern_search(b, off, n, left, right, lo, mid)
    else kern_search(b, off, n, left, right, mid + 1, hi)
  end

fun kern_at(f: !Font, off: int, left: int, right: int, i: int, p: int, nt: int): int =
  if i >= nt orelse i > 6 then 0
  else let
    val length = file_u16(f, p + 2)
    val cov = file_u16(f, p + 4)
    val fmt = u_land(cov, 255)
    val next = iif(igt(length, 6), iadd(p, length), iadd(p, 6))
  in
    if ieq(fmt, 0) then let
      val np = file_u16(f, iadd(p, 6))
      val v =
        case+ f of
        | @FONT(s) => let
            val k = kern_search(s.file, iadd(p, 14), np, left, right, 0, np)
          in
            fold@(f); k
          end
    in
      if ine(v, 0) then v else kern_at(f, off, left, right, iadd(i, 1), next, nt)
    end else kern_at(f, off, left, right, iadd(i, 1), next, nt)
  end

implement font_kern(f, a, b) =
  if f_int(f, 21) = 0 orelse a <= 0 orelse b <= 0 then 0
  else let
    val off = f_int(f, 12)
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

fun atlas_sum(f: !Font, x: int, y: int, w: int, h: int, row: int, acc: int): int =
  if row >= h then acc
  else let
    fun cols(f: !Font, c: int, a: int): int =
      if c >= w then a else cols(f, c + 1, a + atlas_get(f, x + c, y + row))
  in
    atlas_sum(f, x, y, w, h, row + 1, cols(f, 0, acc))
  end

fun buf_append_str(b: &Buf >> _, s: string): void =
  buf_append(b, c_str_ptr(s), c_strlen(s))

fun buf_cat_range(dst: &Buf >> _, src: !Buf, st: int, en: int): void = let
  val n = buf_len(src)
  val s0 = if ilt(st, 0) then 0 else st
  val s1 = if igt(en, n) then n else en
  val count = if igt(s1, s0) then isub(s1, s0) else 0
in
  if igt(count, 0) then let
    val cap = buf_cap(src)
    val p = mem_ptr_at(buf_ptr(src), cap, s0)
  in
    buf_append(dst, p, count)
  end else ()
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

fun scan_step(dp: ptr, dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _, name_buf: &Buf >> _, isdir: &int >> _): void =
  if ige(cnt, 100) orelse ieq(dir_next(dp, buf_ptr(name_buf), 255, isdir), 0) then ()
  else let
    val np = buf_ptr(name_buf)
    val fname = ptr_string(np)
    val nlen = c_strlen(fname)
    val () = buf_set_len(name_buf, nlen)
    val first_b = (if igt(nlen, 0) then buf_get(name_buf, 0) else 0)
    val () =
      if ieq(first_b, 46) then ()
      else if ieq(isdir, 1) then let
        var sub_dir = buf_make(512)
        val () = buf_append_str(sub_dir, dir)
        val () = buf_push(sub_dir, 47)
        val () = buf_cat_range(sub_dir, name_buf, 0, nlen)
        val () = buf_push(sub_dir, 0)
        val () = scan_fonts_rec(ptr_string(buf_ptr(sub_dir)), iadd(depth, 1), paths, names, meta, cnt)
        val () = buf_free(sub_dir)
      in
      end else let
        val is_t = is_ttf_filename(fname)
      in
        if is_t then let
          var full_p = buf_make(512)
          val () = buf_append_str(full_p, dir)
          val () = buf_push(full_p, 47)
          val () = buf_cat_range(full_p, name_buf, 0, nlen)
          val poff = buf_len(paths)
          val plen = buf_len(full_p)
          val () = buf_cat_range(paths, full_p, 0, plen)
          val noff = buf_len(names)
          val dlen = (if ige(nlen, 4) then isub(nlen, 4) else nlen)
          val () = buf_cat_range(names, name_buf, 0, dlen)
          val idx = cnt
          val () = buf_ensure(meta, iadd(imul(idx, 16), 16))
          val () = buf_set32(meta, imul(idx, 4), poff)
          val () = buf_set32(meta, iadd(imul(idx, 4), 1), plen)
          val () = buf_set32(meta, iadd(imul(idx, 4), 2), noff)
          val () = buf_set32(meta, iadd(imul(idx, 4), 3), dlen)
          val () = cnt := iadd(cnt, 1)
          val () = buf_free(full_p)
        in
        end else ()
      end
  in
    scan_step(dp, dir, depth, paths, names, meta, cnt, name_buf, isdir)
  end

and scan_fonts_rec(dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _): void =
  if igt(depth, 4) orelse ige(cnt, 100) then ()
  else let
    val dp = dir_open(dir)
  in
    if ptr_is_null(dp) then ()
    else let
      var name_buf = buf_make(256)
      var isdir: int = 0
      val () = scan_step(dp, dir, depth, paths, names, meta, cnt, name_buf, isdir)
      val () = buf_free(name_buf)
      val () = dir_close(dp)
    in
    end
  end

implement font_scan_fonts(dir, paths, names, meta, cnt) = let
  val () = buf_set_len(paths, 0)
  val () = buf_set_len(names, 0)
  val () = buf_set_len(meta, 0)
  val () = cnt := 0
in
  scan_fonts_rec(dir, 0, paths, names, meta, cnt)
end

fun load_first_scanned(f: !Font, paths: !Buf, meta: !Buf, cnt: int): int =
  if igt(cnt, 0) then let
    val poff = buf_get32(meta, 0)
    val plen = buf_get32(meta, 1)
    var first_p = buf_make(iadd(plen, 1))
    val () = buf_cat_range(first_p, paths, poff, iadd(poff, plen))
    val () = buf_push(first_p, 0)
    val res = font_use_file(f, ptr_string(buf_ptr(first_p)))
    val () = buf_free(first_p)
  in
    res
  end else 0

fun load_default(f: !Font): int = let
  val env = c_getenv("ANTHRACITE_FONT")
in
  if igt(c_strlen(env), 0) andalso ieq(font_use_file(f, env), 1) then 1
  else let
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
    if ieq(ok, 1) then 1
    else let
      var b = buf_make(512)
      val n = c_fc_font(buf_ptr(b), 511)
      val s = ptr_string(buf_ptr(b))
      val hit = iif(ieq(n, 1) andalso igt(c_strlen(s), 0) andalso ieq(font_use_file(f, s), 1), 1, 0)
      val () = buf_free(b)
    in
      if ieq(hit, 1) then 1
      else font_use_file(f, "/nix/store/v3n8r3sy38l5f1sj76azj1n4n0ndd6a7-dejavu-fonts-2.37/share/fonts/truetype/DejaVuSansMono.ttf")
    end
  end
end

implement font_load_default(f) = load_default(f)

implement font_selftest(r) = let
  val f = font_open()
  var g: gmet = @{ax= 0, bx= 0, top= 0, bw= 0, bh= 0, x0= 0, y0= 0, ok= 0}
  val () = font_glyph(f, r, 65, g)
  val ink = atlas_sum(f, g.x0, g.y0, g.bw, g.bh, 0, 0)
  val ok1 = iif(igt(g.bw, 0) andalso igt(ink, 0), 1, 0)
  val kb = buf_make(16)
  val () = buf_set(kb, 0, 0)
  val () = buf_set(kb, 1, 1)
  val () = buf_set(kb, 2, 0)
  val () = buf_set(kb, 3, 2)
  val () = buf_set(kb, 4, 255)
  val () = buf_set(kb, 5, 226)
  val kv = kern_search(kb, 0, 1, 1, 2, 0, 1)
  val () = buf_free(kb)
  val ok2 = iif(ieq(kv, isub(0, 30)), 1, 0)
  val loaded = load_default(f)
  val gid = iif(ieq(loaded, 1), cmap_gid(f, 65), 0)
  val () = font_glyph(f, r, 65, g)
  val inkA = atlas_sum(f, g.x0, g.y0, g.bw, g.bh, 0, 0)
  val axA = g.ax
  val bwA = g.bw

  val _jb = font_use_file(f, "fonts/JetBrains-Mono-Medium/JetBrainsMono-Regular.ttf")
  val () = font_glyph(f, r, 65, g)
  val inkJB = atlas_sum(f, g.x0, g.y0, g.bw, g.bh, 0, 0)

  val _sc = font_use_file(f, "fonts/Source-Code-Pro-Regular/sourcecodepro/SourceCodePro-Regular.ttf")
  val () = font_glyph(f, r, 65, g)
  val inkSC = atlas_sum(f, g.x0, g.y0, g.bw, g.bh, 0, 0)

  val () = font_free(f)
  val ok3 = iif(ieq(loaded, 1) andalso igt(gid, 0) andalso igt(axA, 0) andalso igt(inkA, 20) andalso igt(inkJB, 20) andalso igt(inkSC, 20), 1, 0)
in
  iif(ieq(ok1, 1) andalso ieq(ok2, 1) andalso ieq(ok3, 1), 1, 0)
end
