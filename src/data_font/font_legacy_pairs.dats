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



(* Legacy kerning pair search. *)
staload "data_font/private/font_legacy_pairs.sats"

extern fun kern_search_exh(b: !Buf, off: int, n: int, left: int, right: int, lo: int, hi: int): int = "mac#anth_die_int"

fun kern_search_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, off: int, n: int, left: int, right: int, lo: int, hi: int): int =
  if recfuel > 0 then (
    if lo >= hi then 0
    else let
      val mid = (lo + hi) / 2
      val pl = sfnt_be16(b, off + mid * 6)
      val pr = sfnt_be16(b, off + mid * 6 + 2)
      val key = left * 65536 + right
      val mk = pl * 65536 + pr
    in
      if key = mk then sfnt_signed16(b, off + mid * 6 + 4)
      else if key < mk then kern_search_m(recfuel - 1, b, off, n, left, right, lo, mid)
      else kern_search_m(recfuel - 1, b, off, n, left, right, mid + 1, hi)
    end
  ) else kern_search_exh(b, off, n, left, right, lo, hi)

implement kern_search(b, off, n, left, right, lo, hi) = kern_search_m(airlock_nat(MAX_REC_FUEL), b, off, n, left, right, lo, hi)
