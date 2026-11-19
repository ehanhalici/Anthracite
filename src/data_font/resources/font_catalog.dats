#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef SCAN_ADD_FONT_FULL_P_INITIAL_BYTES = 512
macdef SCAN_STEP_WITH_FUEL_SUB_DIR_INITIAL_BYTES = 512
macdef SCAN_STEP_WITH_FUEL_NAME_BUF_INITIAL_BYTES = 256
macdef LOAD_SCANNED_DEFAULT_PATHS_INITIAL_BYTES = 1024
macdef LOAD_SCANNED_DEFAULT_NAMES_INITIAL_BYTES = 512
macdef LOAD_SCANNED_DEFAULT_META_INITIAL_BYTES = 256
macdef LOAD_FONTCONFIG_DEFAULT_BUFFER_INITIAL_BYTES = 512
macdef FONT_SCAN_MAX = 256


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



(* Filesystem font discovery and default selection. *)
staload "data_font/resources/private/font_catalog.sats"

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

fun ascii_lower(b: int): int =
  if ige(b, 65) andalso ile(b, 90) then iadd(b, 32) else b

fun has_ext4(name: string, n: int, c1: int, c2: int, c3: int): bool = let
  val b0 = c_str_byte(name, isub(n, 4))
  val b1 = ascii_lower(c_str_byte(name, isub(n, 3)))
  val b2 = ascii_lower(c_str_byte(name, isub(n, 2)))
  val b3 = ascii_lower(c_str_byte(name, isub(n, 1)))
in
  ieq(b0, 46) andalso ieq(b1, c1) andalso ieq(b2, c2) andalso ieq(b3, c3)
end

fun is_font_filename(name: string): bool = let
  val n = c_strlen(name)
in
  if ilt(n, 5) then false
  else has_ext4(name, n, 116, 116, 102)
    orelse has_ext4(name, n, 116, 116, 99)
    orelse has_ext4(name, n, 111, 116, 102)
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
  var full_p = buf_make(SCAN_ADD_FONT_FULL_P_INITIAL_BYTES)
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

extern fun scan_step_fuel_exhausted(dp: ptr, dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _, name_buf: &Buf >> _, isdir: &int >> _): void = "mac#anth_die_void"
extern fun scan_subdir_fuel_exhausted(dir: string, nlen: int, name_buf: !Buf, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _): void = "mac#anth_die_void"
extern fun scan_fonts_rec_fuel_exhausted(dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _): void = "mac#anth_die_void"

fun scan_step_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dp: ptr, dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _, name_buf: &Buf >> _, isdir: &int >> _): void =
  if recursion_fuel_available(recfuel) then (
    if ige(cnt, FONT_SCAN_MAX) orelse ieq(dir_next_buf(dp, name_buf, 255, isdir), 0) then ()
    else let
      val fname = buf_cstr(name_buf)
      val nlen = c_strlen(fname)
      val () = buf_set_len(name_buf, nlen)
      val first_b = (if igt(nlen, 0) then buf_get(name_buf, 0) else 0) : int
      val () =
        if ieq(first_b, 46) then ()
        else if is_dir_mark(dir_mark_of(isdir), DirYes) then scan_subdir(recfuel - 1, dir, nlen, name_buf, depth, paths, names, meta, cnt)
        else if is_font_filename(fname) then scan_add_font(dir, nlen, name_buf, paths, names, meta, cnt)
        else ()
    in
      scan_step_with_fuel(recfuel - 1, dp, dir, depth, paths, names, meta, cnt, name_buf, isdir)
    end
  ) else scan_step_fuel_exhausted(dp, dir, depth, paths, names, meta, cnt, name_buf, isdir)

and scan_subdir {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dir: string, nlen: int, name_buf: !Buf, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _): void =
  if recursion_fuel_available(recfuel) then let
    var sub_dir = buf_make(SCAN_STEP_WITH_FUEL_SUB_DIR_INITIAL_BYTES)
    val () = buf_append_str(sub_dir, dir)
    val () = buf_push(sub_dir, 47)
    val () = buf_cat_range(sub_dir, name_buf, 0, nlen)
    val () = buf_push(sub_dir, 0)
    val () = scan_fonts_rec(recfuel - 1, buf_cstr(sub_dir), iadd(depth, 1), paths, names, meta, cnt)
    val () = buf_free(sub_dir)
  in
  end else scan_subdir_fuel_exhausted(dir, nlen, name_buf, depth, paths, names, meta, cnt)

and scan_fonts_rec {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _): void =
  if recursion_fuel_available(recfuel) then (
    if igt(depth, 4) orelse ige(cnt, FONT_SCAN_MAX) then ()
    else let
      val dp = dir_open(dir)
    in
      if ptr_is_null(dp) then ()
      else let
        var name_buf = buf_make(SCAN_STEP_WITH_FUEL_NAME_BUF_INITIAL_BYTES)
        var isdir: int = 0
        val () = scan_step_with_fuel(recfuel - 1, dp, dir, depth, paths, names, meta, cnt, name_buf, isdir)
        val () = buf_free(name_buf)
        val () = dir_close(dp)
      in
      end
    end
  ) else scan_fonts_rec_fuel_exhausted(dir, depth, paths, names, meta, cnt)

fun scan_step(dp: ptr, dir: string, depth: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _, cnt: &int >> _, name_buf: &Buf >> _, isdir: &int >> _): void = scan_step_with_fuel(airlock_nat(MAX_REC_FUEL), dp, dir, depth, paths, names, meta, cnt, name_buf, isdir)

fun cmp_buf_ci_m {n:nat} .<n>. (
  rem: int(n), b: !Buf, o1: int, l1: int, o2: int, l2: int, k: int
): int =
  if rem = 0 then 0
  else if ige(k, l1) andalso ige(k, l2) then 0
  else if ige(k, l1) then ~1
  else if ige(k, l2) then 1
  else let
    val c1 = ascii_lower(buf_get(b, iadd(o1, k)))
    val c2 = ascii_lower(buf_get(b, iadd(o2, k)))
  in
    if ilt(c1, c2) then ~1
    else if igt(c1, c2) then 1
    else cmp_buf_ci_m(rem - 1, b, o1, l1, o2, l2, iadd(k, 1))
  end

fun font_entry_gt(paths: !Buf, names: !Buf, meta: !Buf, i: int, j: int): bool = let
  val i4 = imul(i, 4)
  val j4 = imul(j, 4)
  val no1 = buf_get32(meta, iadd(i4, 2))
  val nl1 = buf_get32(meta, iadd(i4, 3))
  val no2 = buf_get32(meta, iadd(j4, 2))
  val nl2 = buf_get32(meta, iadd(j4, 3))
  val nc = cmp_buf_ci_m(airlock_nat(iadd(imax(0, imin(nl1, nl2)), 1)), names, no1, nl1, no2, nl2, 0)
in
  if igt(nc, 0) then true
  else if ilt(nc, 0) then false
  else let
    val po1 = buf_get32(meta, i4)
    val pl1 = buf_get32(meta, iadd(i4, 1))
    val po2 = buf_get32(meta, j4)
    val pl2 = buf_get32(meta, iadd(j4, 1))
    val pc = cmp_buf_ci_m(airlock_nat(iadd(imax(0, imin(pl1, pl2)), 1)), paths, po1, pl1, po2, pl2, 0)
  in
    igt(pc, 0)
  end
end

fun swap_word(meta: &Buf >> _, a: int, b: int): void = let
  val va = buf_get32(meta, a)
  val vb = buf_get32(meta, b)
  val () = buf_set32(meta, a, vb)
in
  buf_set32(meta, b, va)
end

fun meta_swap(meta: &Buf >> _, i: int, j: int): void = let
  val a = imul(i, 4)
  val b = imul(j, 4)
  val () = swap_word(meta, a, b)
  val () = swap_word(meta, iadd(a, 1), iadd(b, 1))
  val () = swap_word(meta, iadd(a, 2), iadd(b, 2))
in
  swap_word(meta, iadd(a, 3), iadd(b, 3))
end

fun sort_fonts_inner {k:nat} .<k>. (
  rem: int(k), paths: !Buf, names: !Buf, meta: &Buf >> _, j: int
): void =
  if rem = 0 then ()
  else if ile(j, 0) then ()
  else if font_entry_gt(paths, names, meta, isub(j, 1), j) then let
    val () = meta_swap(meta, isub(j, 1), j)
  in
    sort_fonts_inner(rem - 1, paths, names, meta, isub(j, 1))
  end else ()

fun sort_fonts_outer {n:nat} .<n>. (
  rem: int(n), paths: !Buf, names: !Buf, meta: &Buf >> _, i: int, cnt: int
): void =
  if rem = 0 then ()
  else if ige(i, cnt) then ()
  else let
    val () = sort_fonts_inner(airlock_nat(i), paths, names, meta, i)
  in
    sort_fonts_outer(rem - 1, paths, names, meta, iadd(i, 1), cnt)
  end

implement font_scan_fonts(dir, paths, names, meta, cnt) = let
  val () = buf_set_len(paths, 0)
  val () = buf_set_len(names, 0)
  val () = buf_set_len(meta, 0)
  val () = cnt := 0
  val () = scan_fonts_rec(airlock_nat(MAX_REC_FUEL), dir, 0, paths, names, meta, cnt)
  val c = cnt
in
  if igt(c, 1) then sort_fonts_outer(airlock_nat(c), paths, names, meta, 1, c) else ()
end

fun match_regular_at(b: !Buf, off: int): bool =
  ieq(ascii_lower(buf_get(b, off)), 114) andalso
  ieq(ascii_lower(buf_get(b, iadd(off, 1))), 101) andalso
  ieq(ascii_lower(buf_get(b, iadd(off, 2))), 103) andalso
  ieq(ascii_lower(buf_get(b, iadd(off, 3))), 117) andalso
  ieq(ascii_lower(buf_get(b, iadd(off, 4))), 108) andalso
  ieq(ascii_lower(buf_get(b, iadd(off, 5))), 97) andalso
  ieq(ascii_lower(buf_get(b, iadd(off, 6))), 114)

fun name_has_regular_m {n:nat} .<n>. (
  rem: int(n), b: !Buf, off: int, len: int, p: int
): bool =
  if rem = 0 then false
  else if igt(iadd(p, 7), len) then false
  else if match_regular_at(b, iadd(off, p)) then true
  else name_has_regular_m(rem - 1, b, off, len, iadd(p, 1))

fun entry_has_regular(names: !Buf, meta: !Buf, idx: int): bool = let
  val noff = buf_get32(meta, iadd(imul(idx, 4), 2))
  val dlen = buf_get32(meta, iadd(imul(idx, 4), 3))
in
  if ilt(dlen, 7) then false
  else name_has_regular_m(airlock_nat(isub(dlen, 6)), names, noff, dlen, 0)
end

fun try_load_one(f: !Font, paths: !Buf, meta: !Buf, idx: int): bool = let
  val poff = buf_get32(meta, imul(idx, 4))
  val plen = buf_get32(meta, iadd(imul(idx, 4), 1))
  var p = buf_make(iadd(imax(0, plen), 1))
  val () = buf_cat_range(p, paths, poff, iadd(poff, plen))
  val () = buf_push(p, 0)
  val res = font_use_file(f, buf_cstr(p))
  val () = buf_free(p)
in
  res
end

fun try_load_scanned_m {n:nat} .<n>. (
  rem: int(n), f: !Font, paths: !Buf, names: !Buf, meta: !Buf, i: int, only_regular: bool
): bool =
  if rem = 0 then false
  else let
    val match = (if only_regular then entry_has_regular(names, meta, i) else true) : bool
  in
    if match andalso try_load_one(f, paths, meta, i) then true
    else try_load_scanned_m(rem - 1, f, paths, names, meta, iadd(i, 1), only_regular)
  end

fun load_scanned_pick(f: !Font, paths: !Buf, names: !Buf, meta: !Buf, c: int): bool =
  if ile(c, 0) then false
  else if try_load_scanned_m(airlock_nat(c), f, paths, names, meta, 0, true) then true
  else try_load_scanned_m(airlock_nat(c), f, paths, names, meta, 0, false)

fun load_scanned_default(f: !Font): bool = let
  var paths = buf_make(LOAD_SCANNED_DEFAULT_PATHS_INITIAL_BYTES)
  var names = buf_make(LOAD_SCANNED_DEFAULT_NAMES_INITIAL_BYTES)
  var meta = buf_make(LOAD_SCANNED_DEFAULT_META_INITIAL_BYTES)
  var cnt: int = 0
  val () = font_scan_fonts("fonts", paths, names, meta, cnt)
  val ok = load_scanned_pick(f, paths, names, meta, cnt)
  val () = buf_free(paths)
  val () = buf_free(names)
  val () = buf_free(meta)
in
  ok
end

fun load_fontconfig_default(f: !Font): bool = let
  var b = buf_make(LOAD_FONTCONFIG_DEFAULT_BUFFER_INITIAL_BYTES)
  val n = c_fc_font_buf(b, 511)
  val s = buf_cstr(b)
  val hit = ieq(n, 1) andalso igt(c_strlen(s), 0) andalso font_use_file(f, s)
  val () = buf_free(b)
in
  hit
end

implement load_default(f) = let
  val env = c_getenv("ANTHRACITE_FONT")
  val env_prim = c_getenv("ANTHRACITE_PRIMARY_FONT")
in
  if igt(c_strlen(env), 0) andalso font_use_file(f, env) then true
  else if igt(c_strlen(env_prim), 0) andalso font_use_file(f, env_prim) then true
  else if load_scanned_default(f) then true
  else load_fontconfig_default(f)
end

implement font_load_default(f) = load_default(f)
