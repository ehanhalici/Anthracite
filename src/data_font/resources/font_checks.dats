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
staload "data_font/resources/font_embedded.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"
staload "data_text/source/text_source.sats"



(* Font rendering selftests. *)
staload "data_font/resources/private/font_storage.sats"
staload "data_font/resources/private/font_legacy_pairs.sats"
staload "data_font/resources/private/font_catalog.sats"

macdef TTC_SAMPLE_REF = "embedded:SGr-Iosevka-Regular"

extern fun atlas_cols_fuel_exhausted(f: !Font, c: int, w: int, x: int, y: int, row: int, a: int): int = "mac#anth_die_int"

fun atlas_cols {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, c: int, w: int, x: int, y: int, row: int, a: int): int =
  if recursion_fuel_available(recfuel) then (
    if c >= w then a
    else atlas_cols(recfuel - 1, f, c + 1, w, x, y, row, a + atlas_get(f, x + c, y + row))
  ) else atlas_cols_fuel_exhausted(f, c, w, x, y, row, a)

extern fun atlas_sum_fuel_exhausted(f: !Font, x: int, y: int, w: int, h: int, row: int, acc: int): int = "mac#anth_die_int"

fun atlas_sum_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, x: int, y: int, w: int, h: int, row: int, acc: int): int =
  if recursion_fuel_available(recfuel) then (
    if row >= h then acc
    else let
      val acc2 = atlas_cols(airlock_nat(MAX_REC_FUEL), f, 0, w, x, y, row, acc)
    in
      atlas_sum_with_fuel(recfuel - 1, f, x, y, w, h, row + 1, acc2)
    end
  ) else atlas_sum_fuel_exhausted(f, x, y, w, h, row, acc)

fun atlas_sum(f: !Font, x: int, y: int, w: int, h: int, row: int, acc: int): int = atlas_sum_with_fuel(airlock_nat(MAX_REC_FUEL), f, x, y, w, h, row, acc)

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

fun chk_lower(b: int): int =
  if ige(b, 65) andalso ile(b, 90) then iadd(b, 32) else b

fun chk_cmp_ci {n:nat} .<n>. (
  rem: int(n), b: !Buf, o1: int, l1: int, o2: int, l2: int, k: int
): int =
  if rem = 0 then 0
  else if ige(k, l1) andalso ige(k, l2) then 0
  else if ige(k, l1) then ~1
  else if ige(k, l2) then 1
  else let
    val c1 = chk_lower(buf_get(b, iadd(o1, k)))
    val c2 = chk_lower(buf_get(b, iadd(o2, k)))
  in
    if ilt(c1, c2) then ~1
    else if igt(c1, c2) then 1
    else chk_cmp_ci(rem - 1, b, o1, l1, o2, l2, iadd(k, 1))
  end

fun chk_entries_m {n:nat} .<n>. (
  rem: int(n), names: !Buf, meta: !Buf, i: int, cnt: int
): bool =
  if rem = 0 then true
  else if ige(i, cnt) then true
  else let
    val i4 = imul(i, 4)
    val pl = buf_get32(meta, iadd(i4, 1))
    val no = buf_get32(meta, iadd(i4, 2))
    val nl = buf_get32(meta, iadd(i4, 3))
    val entry_ok = igt(nl, 0) andalso igt(pl, nl)
    val order_ok =
      if igt(i, 0) then let
        val p4 = imul(isub(i, 1), 4)
        val pno = buf_get32(meta, iadd(p4, 2))
        val pnl = buf_get32(meta, iadd(p4, 3))
        val nc = chk_cmp_ci(airlock_nat(iadd(imax(0, imin(pnl, nl)), 1)), names, pno, pnl, no, nl, 0)
      in
        ile(nc, 0)
      end else true
  in
    if entry_ok andalso order_ok then chk_entries_m(rem - 1, names, meta, iadd(i, 1), cnt)
    else false
  end

(* The listing (possibly empty) is ordered and the default face, when set, is listed. *)
fun embedded_entries_ok(names: !Buf, meta: !Buf, c: int): bool =
  chk_entries_m(airlock_nat(c), names, meta, 0, c)
  andalso (ieq(c_strlen(embedded_font_default_ref()), 0) orelse ige(embedded_font_find(embedded_font_default_ref()), 0))

fun embedded_listing_selftest(): int = let
  var paths = buf_make(1024)
  var names = buf_make(512)
  var meta = buf_make(256)
  var cnt: int = 0
  val () = font_list_embedded(paths, names, meta, cnt)
  val ok = embedded_entries_ok(names, meta, cnt)
  val () = buf_free(paths)
  val () = buf_free(names)
  val () = buf_free(meta)
in
  (if ok then 1 else 0)
end

(* Faces come from the optional fonts/ directory; one that was not embedded has
   nothing to load, and the previous face stays active. *)
fun optional_face_loads(f: !Font, face_ref: string): bool =
  if ilt(embedded_font_find(face_ref), 0) then true else font_use_file(f, face_ref)

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
  val jb_ok = optional_face_loads(f, "embedded:JetBrainsMono-Regular")
  val inkJB = glyph_ink65(f, r, g)
  val sc_ok = optional_face_loads(f, "embedded:SourceCodePro-Regular")
  val tex_dropped = (font_tex(f) = u_zero()) orelse ilt(embedded_font_find("embedded:SourceCodePro-Regular"), 0)
  val inkSC = glyph_ink65(f, r, g)
  val () = font_glyph(f, r, 1576, g)
  val ar_ok = (if igt(g.bw, 0) then 1 else 0) : int
  val ttc_ok = optional_face_loads(f, TTC_SAMPLE_REF)
  val inkTTC = glyph_ink65(f, r, g)
  val otf_ok = optional_face_loads(f, "embedded:IbmPlexMono-7L4D")
  val inkOTF = glyph_ink65(f, r, g)
  val () = font_free(f)
  val ok4 = embedded_listing_selftest()
  val ok3 = (if loaded andalso igt(gid, 0) andalso igt(axA, 0) andalso igt(inkA, 20) andalso igt(inkJB, 20) andalso igt(inkSC, 20) andalso igt(inkTTC, 20) andalso igt(inkOTF, 20) andalso jb_ok andalso sc_ok andalso ttc_ok andalso otf_ok andalso tex_dropped andalso ieq(ar_ok, 1) then 1 else 0) : int
in
  (if ieq(ok1, 1) andalso ieq(ok2, 1) andalso ieq(ok3, 1) andalso ieq(ok4, 1) then 1 else 0)
end
