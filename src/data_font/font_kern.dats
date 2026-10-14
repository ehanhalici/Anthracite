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



(* Legacy kerning integration. *)
staload "data_font/private/font_storage.sats"
staload "data_font/private/font_metrics.sats"
staload "data_font/private/font_math.sats"

fun u_land(a: int, m: int): int = anth_iand(a, m)

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
