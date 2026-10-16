#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef FONT_OPEN_FILE_INITIAL_BYTES = 1
macdef FONT_OPEN_BUFFER_INITIAL_BYTES = 8192


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
staload "data_font/atlas/font_glyph_id.sats"
staload "data_font/native/shape/native_shape_types.sats"
staload "data_font/native/ownership/font_native_types.sats"
staload "data_font/native/ownership/font_native.sats"
staload "data_font/native/ownership/private/font_native_owner.sats"
staload "data_font/text/font_text_types.sats"
staload "data_font/text/font_text.sats"
staload "data_font/text/private/font_text_owner.sats"
staload "data_font/resources/font_registry.sats"


#define FONT_ATLAS_WIDTH_PIXELS 1024
#define FONT_ATLAS_HEIGHT_PIXELS 1024
#define FONT_MAX_POINTS 3000
#define FONT_OUTLINE_INITIAL_POINTS 3200
#define FONT_MAX_EDGES 10000

datavtype Font_ = FONT of @{
  file= Buf, fb_file= Option_vt(Buf), info= Option(SfntInfo), fb_info= Option(SfntInfo), atlas= Buf, cache= Buf
, xs= Buf, ys= Buf, fl= Buf, ends= Buf, edges= Buf, cov= Buf
, px= int, units= int, asc= int, desc= int, lgap= int
, num_h= int, nglyph= int, loca_fmt= Toggle
, cmap_off= int, glyf_off= int, loca_off= int, hmtx_off= int, kern_off= int
, npts= int, nends= int, nedges= int
, pen_x= int, pen_y= int, row_h= int
, aw= int, ah= int, tex= uint
, has_ttf= Toggle, line_h= int, asc_px= int
, fb_has= Toggle
, fb_units= int, fb_cmap= int, fb_glyf= int, fb_loca= int, fb_hmtx= int, fb_loca_fmt= Toggle
, fb_nglyph= int, fb_num_h= int
, fb_kern= int
, native_primary= Option_vt(NativeShapeCache), native_fallback= Option_vt(NativeShapeCache)
, native_generation= int, native_fb_generation= int
, text_session= Option_vt(FontTextSession)
, registry= int
}
(* skill.md 1. kural istisnasi: ATS2 soyut tip gerceklemesi (sats'taki absviewtype). Kanit disi cast veya ham C yoktur. *)
assume Font = Font_


(* Font resource ownership and private storage access. *)
staload "data_font/resources/private/font_legacy_pairs.sats"
staload "data_font/resources/private/font_storage.sats"


(* Private implementation groups share this owner and its linear representation. *)
#include "data_font/resources/private/font/ztex.hats"
#include "data_font/resources/private/font/font_atlas_w.hats"
#include "data_font/resources/private/font/pt_x.hats"
