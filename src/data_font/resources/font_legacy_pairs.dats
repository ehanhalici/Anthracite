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



(* Legacy kerning pair search. *)
staload "data_font/resources/private/font_legacy_pairs.sats"

extern fun kern_search_fuel_exhausted(b: !Buf, off: int, n: int, left: int, right: int, lo: int, hi: int): int = "mac#anth_die_int"

fun kern_search_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, off: int, n: int, left: int, right: int, lo: int, hi: int): int =
  if recfuel > 0 then (
    if lo >= hi then 0
    else let
      val mid = (lo + hi) / 2
      val pl = sfnt_be16(b, off + mid * 6)
      val pr = sfnt_be16(b, off + mid * 6 + 2)
      val key = left * WORD16_MODULUS + right
      val mk = pl * WORD16_MODULUS + pr
    in
      if key = mk then sfnt_signed16(b, off + mid * 6 + 4)
      else if key < mk then kern_search_with_fuel(recfuel - 1, b, off, n, left, right, lo, mid)
      else kern_search_with_fuel(recfuel - 1, b, off, n, left, right, mid + 1, hi)
    end
  ) else kern_search_fuel_exhausted(b, off, n, left, right, lo, hi)

implement kern_search(b, off, n, left, right, lo, hi) = kern_search_with_fuel(airlock_nat(MAX_REC_FUEL), b, off, n, left, right, lo, hi)
