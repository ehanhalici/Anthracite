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



(* Font rendering selftests. *)
staload "data_font/private/font_storage.sats"
staload "data_font/private/font_legacy_pairs.sats"
staload "data_font/private/font_catalog.sats"

extern fun atlas_cols_exh(f: !Font, c: int, w: int, x: int, y: int, row: int, a: int): int = "mac#anth_die_int"

fun atlas_cols {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, c: int, w: int, x: int, y: int, row: int, a: int): int =
  if recfuel > 0 then (
    if c >= w then a
    else atlas_cols(recfuel - 1, f, c + 1, w, x, y, row, a + atlas_get(f, x + c, y + row))
  ) else atlas_cols_exh(f, c, w, x, y, row, a)

extern fun atlas_sum_exh(f: !Font, x: int, y: int, w: int, h: int, row: int, acc: int): int = "mac#anth_die_int"

fun atlas_sum_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, x: int, y: int, w: int, h: int, row: int, acc: int): int =
  if recfuel > 0 then (
    if row >= h then acc
    else let
      val acc2 = atlas_cols(airlock_nat(MAX_REC_FUEL), f, 0, w, x, y, row, acc)
    in
      atlas_sum_m(recfuel - 1, f, x, y, w, h, row + 1, acc2)
    end
  ) else atlas_sum_exh(f, x, y, w, h, row, acc)

fun atlas_sum(f: !Font, x: int, y: int, w: int, h: int, row: int, acc: int): int = atlas_sum_m(airlock_nat(MAX_REC_FUEL), f, x, y, w, h, row, acc)

fun glyph_ink65(f: !Font, r: !Rend, g: &gmet >> _): int = let
  val () = font_glyph(f, r, 65, g)
in
  atlas_sum(f, g.x0, g.y0, g.bw, g.bh, 0, 0)
end

fun kern_selftest(): int = let
  val kb = buf_make(16)
  val () = buf_set(kb, 0, 0)
  val () = buf_set(kb, 1, 1)
  val () = buf_set(kb, 2, 0)
  val () = buf_set(kb, 3, 2)
  val () = buf_set(kb, 4, 255)
  val () = buf_set(kb, 5, 226)
  val kv = kern_search(kb, 0, 1, 1, 2, 0, 1)
  val () = buf_free(kb)
in
  (if ieq(kv, isub(0, 30)) then 1 else 0)
end

implement font_selftest(r) = let
  val f = font_open()
  var g: gmet = @{ax= 0, bx= 0, top= 0, bw= 0, bh= 0, x0= 0, y0= 0, ok= Off}
  val ink = glyph_ink65(f, r, g)
  val ok1 = (if igt(g.bw, 0) andalso igt(ink, 0) then 1 else 0) : int
  val ok2 = kern_selftest()
  val loaded = load_default(f)
  val gid = (if loaded then cmap_gid(f, 65) else 0) : int
  val inkA = glyph_ink65(f, r, g)
  val axA = g.ax
  val bwA = g.bw
  val jb_ok = font_use_file(f, "fonts/JetBrains-Mono-Medium/JetBrainsMono-Regular.ttf")
  val inkJB = glyph_ink65(f, r, g)
  val sc_ok = font_use_file(f, "fonts/Source-Code-Pro-Regular/sourcecodepro/SourceCodePro-Regular.ttf")
  val inkSC = glyph_ink65(f, r, g)
  val () = font_glyph(f, r, 1576, g)
  val ar_ok = (if igt(g.bw, 0) then 1 else 0) : int
  val () = font_free(f)
  val ok3 = (if loaded andalso igt(gid, 0) andalso igt(axA, 0) andalso igt(inkA, 20) andalso igt(inkJB, 20) andalso igt(inkSC, 20) andalso jb_ok andalso sc_ok andalso ieq(ar_ok, 1) then 1 else 0) : int
in
  (if ieq(ok1, 1) andalso ieq(ok2, 1) andalso ieq(ok3, 1) then 1 else 0)
end
