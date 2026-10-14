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



(* Numeric operations shared by font modules. *)
staload "data_font/private/font_math.sats"

implement bit(a, m) = anth_bit(a, m)

implement iround(d) =
  if d >= 0.0 then n_d2i(n_floor(d + 0.5))
  else 0 - n_d2i(n_floor((0.0 - d) + 0.5))

implement font_mod(a, m) = let
  val r = a - idiv(a, m) * m
in
  if r < 0 then r + m else r
end
