#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef INIT_FALLBACK_FONT_PBUF_INITIAL_BYTES = 512


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



(* Validated primary and fallback face loading. *)
staload "data_font/resources/private/font_storage.sats"
staload "data_font/atlas/private/font_cache.sats"
staload "data_font/resources/private/font_metrics.sats"

fun install_face_metrics(f: !Font, info: SfntInfo): void = let
  val () = font_set_units(f,info.units)
  val () = font_set_ascender(f,info.ascender)
  val () = font_set_descender(f,info.descender)
  val () = font_set_line_gap(f,info.line_gap)
  val () = font_set_horizontal_metric_count(f,info.hmetrics)
  val () = font_set_glyph_count(f,info.glyphs)
in font_set_loca_fmt(f,toggle_of(info.long_loca)) end

implement font_use_fallback_file(f,path) = case+ sfnt_open(path) of
  | ~RejectedSfnt(error) => false
  | ~LoadedSfnt(face) => let
      val+ ~SfntFace(b,info) = face
      val () = install_fallback(f,b,info)
      val () = clear_cache(f,0)
    in true end

fun load_fallback_path(f: !Font, path: string): void =
  if font_use_fallback_file(f,path) then ()
  else println!("event=font_fallback status=unavailable")

fun init_fallback_font(f: !Font): void =
  if font_has_fb(f) then ()
  else let
    val pbuf = buf_make(INIT_FALLBACK_FONT_PBUF_INITIAL_BYTES)
    val ok = c_fc_arabic_font_buf(pbuf,512)
    val () = if igt(ok,0) then load_fallback_path(f,buf_cstr(pbuf)) else ()
    val () = buf_free(pbuf)
  in () end

fun fit_px_after_load(f: !Font): void = let
  val cur_px = font_get_px(f)
  val px_val = if cur_px >= 8 then cur_px else 18
  val () = font_set_px_val(f, 0)
in
  font_set_px(f, px_val)
end

fun commit_font(f: !Font, face: SfntFace): void = let
  val+ ~SfntFace(b,info) = face
  val () = put_file(f,b)
  val () = install_face_metrics(f,info)
  val () = install_face_tables(f,info)
  val () = store_ttf_metrics(f)
in fit_px_after_load(f); init_fallback_font(f) end

implement font_use_file(f, path) = let
  val sz = fs_size(path)
in
  if sz <= 12 orelse sz > 20000000 then false
  else case+ sfnt_open(path) of
    | ~RejectedSfnt(error) => false
    | ~LoadedSfnt(face) => let val () = commit_font(f,face) in true end
end
