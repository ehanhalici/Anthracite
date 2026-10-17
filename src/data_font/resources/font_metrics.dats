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
staload "data_font/resources/font.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"
staload "data_text/source/text_source.sats"



(* Font size and line metric configuration. *)
staload "data_font/resources/private/font_storage.sats"
staload "data_font/atlas/private/font_cache.sats"
staload "data_font/resources/private/font_metrics.sats"

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

implement store_ttf_metrics(f) = let
  val want = font_get_px(f)
  val px: int = if igt(want, 0) then want else 16
  val units = font_get_units(f)
  val asc = font_get_ascender(f)
  val desc = font_get_descender(f)
  val lgap = font_get_line_gap(f)
  val () = font_set_px_val(f, px)
  val () = font_set_line_h(f, ttf_line_height(px, units, asc, desc, lgap))
  val () = font_set_ascender_px(f, ttf_ascent_px(px, units, asc))
  val () = font_set_has_ttf(f, On())
  val () = clear_atlas(f)
  val () = clear_cache(f, 0)
in
end

fun scaled_line_h(f: !Font, px: int): int = let
  val units = font_get_units(f)
  val asc = font_get_ascender(f)
  val desc = font_get_descender(f)
  val lgap = font_get_line_gap(f)
  val den = if igt(units, 0) then units else 1
  val span = iadd(isub(asc, desc), lgap)
  val numer: int = imul(span, px)
  val lh0 = if igt(units, 0) then idiv(numer, den) else iadd(px, 2)
in
  if ilt(lh0, px) then px else lh0
end

fun scaled_asc_px(f: !Font, px: int): int = let
  val units = font_get_units(f)
  val den = if igt(units, 0) then units else 1
  val ap = if igt(units, 0) then idiv(imul(font_get_ascender(f), px), den) else isub(px, 2)
in
  if igt(ap, 0) then ap else 12
end

implement font_set_px(f, px0) = let
  val px = if ilt(px0, 8) then 8 else if igt(px0, 48) then 48 else px0
in
  if ieq(font_get_px(f), px) then ()
  else let
    val lh = scaled_line_h(f, px)
    val ap = scaled_asc_px(f, px)
    val () = font_set_px_val(f, px)
    val () = font_set_line_h(f, if ilt(lh, 8) then 8 else lh)
    val () = font_set_ascender_px(f, if igt(ap, 0) then ap else 12)
    val () = clear_atlas(f)
    val () = clear_cache(f, 0)
  in
    drop_tex(f)
  end
end

implement scale_of(f) = let
  val units = font_get_units(f)
  val px = font_get_px(f)
  val den = if units > 0 then units else 1
in
  n_i2d(px) / n_i2d(den)
end
