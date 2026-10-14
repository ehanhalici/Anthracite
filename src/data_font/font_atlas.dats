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



(* Atlas packing and texture upload orchestration. *)
staload "data_font/private/font_math.sats"
staload "data_font/private/font_storage.sats"
staload "data_font/private/font_cache.sats"
staload "data_font/private/font_atlas.sats"

implement clamp_even(n) = let
  val c = (if n < 2 then 2 else (if n > 254 then 254 else n)) : int
in
  isub(c, font_mod(c, 2))
end

fun reset_atlas(f: !Font,r: !Rend): void = let
  val () = rend_flush(r)
  val () = clear_atlas(f)
  val () = clear_cache(f, 0)
in
  drop_tex(f)
end

implement reserve(f, r, bw, bh, x, y) = let
  val slot=font_atlas_plan(f,bw,bh)
  val () = if slot.reset then reset_atlas(f,r) else ()
  val () = f_set_pen_x(f, iadd(iadd(slot.x,bw),1))
  val () = f_set_pen_y(f, slot.y)
  val () = f_set_row_h(f, slot.row)
  val () = x := slot.x
  val () = y := slot.y
in
end

implement upload(f, r, x, y, w, h) =
  if w <= 0 orelse h <= 0 then ()
  else let
    val () = ensure_tex(f, r)
    val tex = font_tex(f)
  in
    upload_atlas(f, r, tex, x, y, w, h)
  end
