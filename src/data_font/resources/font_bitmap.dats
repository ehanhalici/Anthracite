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



(* Bitmap fallback glyph rasterization. *)
staload "data_font/raster/private/font_math.sats"
staload "data_font/resources/private/font_storage.sats"
staload "data_font/atlas/private/font_atlas.sats"
staload "data_font/atlas/private/font_cache.sats"
staload "data_font/resources/private/font_bitmap.sats"

fun colmask(c: int): int =
  if c <= 0 then 128
  else if c = 1 then 64
  else if c = 2 then 32
  else if c = 3 then 16
  else if c = 4 then 8
  else if c = 5 then 4
  else if c = 6 then 2
  else 1

extern fun write_pix_loop_fuel_exhausted(f: !Font, x0: int, y0: int, cp: int, ww: int, r: int, c: int): void = "mac#anth_die_void"

fun write_pix_loop_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, x0: int, y0: int, cp: int, ww: int, r: int, c: int): void =
  if recursion_fuel_available(recfuel) then (
    if r >= 16 then ()
    else if c >= ww then write_pix_loop_with_fuel(recfuel - 1, f, x0, y0, cp, ww, r + 1, 0)
    else let
      val colb = c >= 8
      val bitn = if colb then c - 8 else c
      val on = bit(uf_byte(cp, r, if colb then 1 else 0), colmask(bitn))
      val () = if on = 1 then atlas_set(f, x0 + c, y0 + r, 255) else ()
    in
      write_pix_loop_with_fuel(recfuel - 1, f, x0, y0, cp, ww, r, c + 1)
    end
  ) else write_pix_loop_fuel_exhausted(f, x0, y0, cp, ww, r, c)

fun write_pix_loop(f: !Font, x0: int, y0: int, cp: int, ww: int, r: int, c: int): void = write_pix_loop_with_fuel(airlock_nat(MAX_REC_FUEL), f, x0, y0, cp, ww, r, c)

extern fun write_box_loop_fuel_exhausted(f: !Font, x0: int, y0: int, r: int, c: int): void = "mac#anth_die_void"

fun write_box_loop_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, x0: int, y0: int, r: int, c: int): void =
  if recursion_fuel_available(recfuel) then (
    if r >= 16 then ()
    else if c >= 8 then write_box_loop_with_fuel(recfuel - 1, f, x0, y0, r + 1, 0)
    else let
      val edge = ieq(r, 0) orelse ieq(r, 15) orelse ieq(c, 0) orelse ieq(c, 7)
      val () = if edge then atlas_set(f, x0 + c, y0 + r, 255) else ()
    in
      write_box_loop_with_fuel(recfuel - 1, f, x0, y0, r, c + 1)
    end
  ) else write_box_loop_fuel_exhausted(f, x0, y0, r, c)

fun write_box_loop(f: !Font, x0: int, y0: int, r: int, c: int): void = write_box_loop_with_fuel(airlock_nat(MAX_REC_FUEL), f, x0, y0, r, c)

datatype GlyphWide = WideMissing | WideNarrow | WideFull

fun wide_of(n: int): GlyphWide =
  if ieq(n, 0) then WideMissing()
  else if ieq(n, 16) then WideFull()
  else WideNarrow()

fun wide_px(w: GlyphWide): int = case+ w of
  | WideMissing() => 8
  | WideNarrow() => 8
  | WideFull() => 16

fun write_bitmap(f: !Font, x0: int, y0: int, cp: int): void = let
  val w = wide_of(uf_wide(cp))
  val ww = wide_px(w)
in
  case+ w of
  | WideMissing() => write_box_loop(f, x0, y0, 0, 0)
  | WideNarrow() => write_pix_loop(f, x0, y0, cp, ww, 0, 0)
  | WideFull() => write_pix_loop(f, x0, y0, cp, ww, 0, 0)
end

implement raster_bitmap(f, r, cp, g) = let
  var x0: int = 0
  var y0: int = 0
  val w = wide_px(wide_of(uf_wide(cp)))
  val () = reserve(f, r, w, 16, x0, y0)
  val () = write_bitmap(f, x0, y0, cp)
  val () = upload(f, r, x0, y0, w, 16)
in
  fill_g(g, w, 0, 14, w, 16, x0, y0)
end
