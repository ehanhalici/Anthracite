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



(* Filesystem font discovery and default selection. *)
staload "data_font/private/font_catalog.sats"

fun buf_append_str(b: &Buf >> _, s: string): void =
  buf_append(b, c_str_ptr(s), c_strlen(s))

fun buf_cat_range(dst: &Buf >> _, src: !Buf, st: int, en: int): void = let
  val n = buf_len(src)
  val s0 = if ilt(st, 0) then 0 else st
  val s1 = if igt(en, n) then n else en
  val count = if igt(s1, s0) then isub(s1, s0) else 0
in
  if igt(count, 0) then buf_append_at(dst, src, s0, count) else ()
end

fun is_ttf_filename(name: string): bool = let
  val n = c_strlen(name)
in
  if ilt(n, 4) then false
  else let
    val b0 = c_str_byte(name, isub(n, 4))
    val b1 = c_str_byte(name, isub(n, 3))
    val b2 = c_str_byte(name, isub(n, 2))
    val b3 = c_str_byte(name, isub(n, 1))
    val is_dot = ieq(b0, 46)
    val is_t1 = (ieq(b1, 116) orelse ieq(b1, 84))
    val is_t2 = (ieq(b2, 116) orelse ieq(b2, 84))
    val is_f  = (ieq(b3, 102) orelse ieq(b3, 70))
  in
    is_dot andalso is_t1 andalso is_t2 andalso is_f
  end
end

fun meta_put(meta: &Buf >> _, idx: int, poff: int, plen: int, noff: int, dlen: int): void = let
  val () = buf_ensure(meta, iadd(imul(idx, 16), 16))
  val () = buf_set32(meta, imul(idx, 4), poff)
  val () = buf_set32(meta, iadd(imul(idx, 4), 1), plen)
  val () = buf_set32(meta, iadd(imul(idx, 4), 2), noff)
  val () = buf_set32(meta, iadd(imul(idx, 4), 3), dlen)
in
end

fun scan_add_font(dir: string, nlen: int, name_buf: !Buf, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _): void = let
  var full_p = buf_make(512)
  val () = buf_append_str(full_p, dir)
  val () = buf_push(full_p, 47)
  val () = buf_cat_range(full_p, name_buf, 0, nlen)
  val poff = buf_len(paths)
  val plen = buf_len(full_p)
  val () = buf_cat_range(paths, full_p, 0, plen)
  val noff = buf_len(names)
  val dlen = (if ige(nlen, 4) then isub(nlen, 4) else nlen) : int
  val () = buf_cat_range(names, name_buf, 0, dlen)
  val idx = cnt
  val () = meta_put(meta, idx, poff, plen, noff, dlen)
  val () = cnt := iadd(cnt, 1)
  val () = buf_free(full_p)
in
end

extern fun scan_step_exh(dp: ptr, dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _, name_buf: &Buf >> _, isdir: &int >> _): void = "mac#anth_die_void"
extern fun scan_subdir_exh(dir: string, nlen: int, name_buf: !Buf, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _): void = "mac#anth_die_void"
extern fun scan_fonts_rec_exh(dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _): void = "mac#anth_die_void"

fun scan_step_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dp: ptr, dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _, name_buf: &Buf >> _, isdir: &int >> _): void =
  if recfuel > 0 then (
    if ige(cnt, 100) orelse ieq(dir_next_buf(dp, name_buf, 255, isdir), 0) then ()
    else let
      val fname = buf_cstr(name_buf)
      val nlen = c_strlen(fname)
      val () = buf_set_len(name_buf, nlen)
      val first_b = (if igt(nlen, 0) then buf_get(name_buf, 0) else 0) : int
      val () =
        if ieq(first_b, 46) then ()
        else if is_dir_mark(dir_mark_of(isdir), DirYes) then scan_subdir(recfuel - 1, dir, nlen, name_buf, depth, paths, names, meta, cnt)
        else if is_ttf_filename(fname) then scan_add_font(dir, nlen, name_buf, paths, names, meta, cnt)
        else ()
    in
      scan_step_m(recfuel - 1, dp, dir, depth, paths, names, meta, cnt, name_buf, isdir)
    end
  ) else scan_step_exh(dp, dir, depth, paths, names, meta, cnt, name_buf, isdir)

and scan_subdir {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dir: string, nlen: int, name_buf: !Buf, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _): void =
  if recfuel > 0 then let
    var sub_dir = buf_make(512)
    val () = buf_append_str(sub_dir, dir)
    val () = buf_push(sub_dir, 47)
    val () = buf_cat_range(sub_dir, name_buf, 0, nlen)
    val () = buf_push(sub_dir, 0)
    val () = scan_fonts_rec(recfuel - 1, buf_cstr(sub_dir), iadd(depth, 1), paths, names, meta, cnt)
    val () = buf_free(sub_dir)
  in
  end else scan_subdir_exh(dir, nlen, name_buf, depth, paths, names, meta, cnt)

and scan_fonts_rec {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _): void =
  if recfuel > 0 then (
    if igt(depth, 4) orelse ige(cnt, 100) then ()
    else let
      val dp = dir_open(dir)
    in
      if ptr_is_null(dp) then ()
      else let
        var name_buf = buf_make(256)
        var isdir: int = 0
        val () = scan_step_m(recfuel - 1, dp, dir, depth, paths, names, meta, cnt, name_buf, isdir)
        val () = buf_free(name_buf)
        val () = dir_close(dp)
      in
      end
    end
  ) else scan_fonts_rec_exh(dir, depth, paths, names, meta, cnt)

fun scan_step(dp: ptr, dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _, name_buf: &Buf >> _, isdir: &int >> _): void = scan_step_m(airlock_nat(MAX_REC_FUEL), dp, dir, depth, paths, names, meta, cnt, name_buf, isdir)

implement font_scan_fonts(dir, paths, names, meta, cnt) = let
  val () = buf_set_len(paths, 0)
  val () = buf_set_len(names, 0)
  val () = buf_set_len(meta, 0)
  val () = cnt := 0
in
  scan_fonts_rec(airlock_nat(MAX_REC_FUEL), dir, 0, paths, names, meta, cnt)
end

fun load_first_scanned(f: !Font, paths: !Buf, meta: !Buf, cnt: int): bool =
  if igt(cnt, 0) then let
    val poff = buf_get32(meta, 0)
    val plen = buf_get32(meta, 1)
    var first_p = buf_make(iadd(plen, 1))
    val () = buf_cat_range(first_p, paths, poff, iadd(poff, plen))
    val () = buf_push(first_p, 0)
    val res = font_use_file(f, buf_cstr(first_p))
    val () = buf_free(first_p)
  in
    res
  end else false

fun load_scanned_default(f: !Font): bool = let
  var paths = buf_make(1024)
  var names = buf_make(512)
  var meta = buf_make(256)
  var cnt: int = 0
  val () = font_scan_fonts("fonts", paths, names, meta, cnt)
  val ok = load_first_scanned(f, paths, meta, cnt)
  val () = buf_free(paths)
  val () = buf_free(names)
  val () = buf_free(meta)
in
  ok
end

fun load_fontconfig_default(f: !Font): bool = let
  var b = buf_make(512)
  val n = c_fc_font_buf(b, 511)
  val s = buf_cstr(b)
  val hit = ieq(n, 1) andalso igt(c_strlen(s), 0) andalso font_use_file(f, s)
  val () = buf_free(b)
in
  hit
end

implement load_default(f) = let
  val env = c_getenv("ANTHRACITE_FONT")
in
  if igt(c_strlen(env), 0) andalso font_use_file(f, env) then true
  else if load_scanned_default(f) then true
  else if load_fontconfig_default(f) then true
  else font_use_file(f, "/nix/store/v3n8r3sy38l5f1sj76azj1n4n0ndd6a7-dejavu-fonts-2.37/share/fonts/truetype/DejaVuSansMono.ttf")
end

implement font_load_default(f) = load_default(f)
