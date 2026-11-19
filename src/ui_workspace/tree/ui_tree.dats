#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef SCAN_DIR_IMPL_NAME_INITIAL_BYTES = 256
macdef DO_CREATE_PATH_INITIAL_BYTES = 8
macdef DO_RENAME_DIR_INITIAL_BYTES = 8
macdef DO_RENAME_PATH_INITIAL_BYTES = 8


staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "os/diag.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/tree/ui_tree.sats"

fun tree_add(meta: &Buf >> _, text: &Buf >> _, n: &int >> _, depth: int, isdir: DirMark, path: !Buf): void = let
  val () = buf_ensure(meta, imul(iadd(n, 1), 16))
  val () = buf_set32(meta, imul(n, 4), depth)
  val () = buf_set32(meta, iadd(imul(n, 4), 1), dir_mark_int(isdir))
  val () = buf_set32(meta, iadd(imul(n, 4), 2), buf_len(text))
  val () = buf_set32(meta, iadd(imul(n, 4), 3), buf_len(path))
  val () = buffer_append_range(text, path, 0, buf_len(path))
in
  n := iadd(n, 1)
end

fun tree_add_if(meta: &Buf >> _, text: &Buf >> _, n: &int >> _, depth: int, isdir: DirMark, path: !Buf, go: Toggle): void =
  if is_on(go) then tree_add(meta, text, n, depth, isdir, path)
  else let
    val () = buffer_preserve(meta)
    val () = buffer_preserve(text)
  in
    ()
  end

extern fun scan_step_fuel_exhausted(dp: ptr, path: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _, name: &Buf >> _, isdir: &int >> _): void = "mac#anth_die_void"

fun scan_dir_impl {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), path: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _): void =
  if recursion_fuel_available(recfuel) then (
    if igt(depth, MAX_TREE_DEPTH) orelse ige(n, MAX_TREE_ITEMS) then let
      val () = buffer_preserve(meta)
    in
      buffer_preserve(text)
    end else let
      val p = buffer_c_string(path)
      val dp = dir_open(p)
      var name = buf_make(SCAN_DIR_IMPL_NAME_INITIAL_BYTES)
      var isdir: int = 0
      val () = scan_open(recfuel - 1, dp, path, depth, meta, text, n, name, isdir)
    in
      buf_free(name)
    end
  ) else let
    val () = buffer_preserve(meta)
  in
    buffer_preserve(text)
  end
and scan_open {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dp: ptr, path: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _, name: &Buf >> _, isdir: &int >> _): void =
  if recursion_fuel_available(recfuel) then (
    if dp = 0 then let
      val () = buffer_preserve(meta)
      val () = buffer_preserve(text)
      val () = buffer_preserve(name)
    in
      ()
    end else let
      val () = scan_step(recfuel - 1, dp, path, depth, meta, text, n, name, isdir)
      val () = dir_close(dp)
    in
      ()
    end
  ) else let
    val () = buffer_preserve(meta)
    val () = buffer_preserve(text)
  in
    buffer_preserve(name)
  end
and scan_step {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dp: ptr, path: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _, name: &Buf >> _, isdir: &int >> _): void =
  if recursion_fuel_available(recfuel) then (
    if dir_next_buf(dp, name, 255, isdir) = 0 then let
      val () = buffer_preserve(meta)
      val () = buffer_preserve(text)
      val () = buffer_preserve(name)
    in
      ()
    end else let
      val () = scan_entry(recfuel - 1, path, depth, meta, text, n, name, isdir)
    in
      scan_step(recfuel - 1, dp, path, depth, meta, text, n, name, isdir)
    end
  ) else scan_step_fuel_exhausted(dp, path, depth, meta, text, n, name, isdir)
and scan_entry {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), path: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _, name: &Buf >> _, isdir: &int >> _): void =
  if recursion_fuel_available(recfuel) then let
    val ns = buf_cstr(name)
    val () = buf_set_len(name, c_strlen(ns))
    val skip = scan_skip(name)
    val child = join2(path, name)
    val isd = child_kind(child, toggle_of(skip), dir_mark_of(isdir))
    val goadd = not(skip) andalso ilt(n, MAX_TREE_ITEMS)
    val () = tree_add_if(meta, text, n, depth, isd, child, toggle_of(goadd))
    val godir = not(skip) andalso is_dir_mark(isd, DirYes)
    val () = scan_maybe(recfuel - 1, child, iadd(depth, 1), meta, text, n, toggle_of(godir))
    val () = buf_free(child)
  in
  end else let
    val () = buffer_preserve(meta)
    val () = buffer_preserve(text)
  in
    buffer_preserve(name)
  end
and scan_maybe {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), child: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _, go: Toggle): void =
  if recursion_fuel_available(recfuel) then (
    if is_on(go) then scan_dir_impl(recfuel - 1, child, depth, meta, text, n)
    else let
      val () = buffer_preserve(meta)
    in
      buffer_preserve(text)
    end
  ) else let
    val () = buffer_preserve(meta)
  in
    buffer_preserve(text)
  end

implement scan_dir(path, depth, meta, text, n) =
  scan_dir_impl(airlock_nat(MAX_REC_FUEL), path, depth, meta, text, n)

implement write_text(path, body) = let
  val n = buf_len(body)
in
  fs_write_buf(buffer_c_string(path), body, n)
end

fun create_dir_report(p: string): void =
  if ieq(fs_mkdir(p), 0) then () else report_failure("create_dir", p)

fun create_file_report(p: string): void =
  if ieq(fs_atomic_write(p, the_null_ptr, 0), 1) then ()
  else report_failure("create_file", p)

implement do_create(dir, name, isdir) = let
  val nlen = buf_len(name)
in
  if nlen <= 0 then ()
  else let
    var path = buf_make(DO_CREATE_PATH_INITIAL_BYTES)
    val () = child_path(dir, name, path)
    val has_dot = has_dot_char(name, 0)
    val need_md = not(isdir) andalso not(has_dot)
    val () = buffer_append_string_if(path, toggle_of(need_md), ".md")
    val p = buffer_c_string(path)
    val () = if isdir then create_dir_report(p) else create_file_report(p)
  in
    buf_free(path)
  end
end

fun rn_is_ws(b: int): bool = ieq(b, 32) orelse ieq(b, 9)

fun rn_trim_left_m {rem:nat} .<rem>. (b: !Buf, i: int, n: int, rem: int(rem)): int =
  if rem = 0 then n
  else if ige(i, n) then n
  else if rn_is_ws(buf_get(b, i)) then rn_trim_left_m(b, iadd(i, 1), n, rem - 1)
  else i

fun rn_trim_right_m {rem:nat} .<rem>. (b: !Buf, st: int, en: int, rem: int(rem)): int =
  if rem = 0 then st
  else if ile(en, st) then st
  else if rn_is_ws(buf_get(b, isub(en, 1))) then rn_trim_right_m(b, st, isub(en, 1), rem - 1)
  else en

fun rn_has_slash_m {rem:nat} .<rem>. (b: !Buf, i: int, en: int, rem: int(rem)): bool =
  if rem = 0 then false
  else if ige(i, en) then false
  else if ieq(buf_get(b, i), 47) then true
  else rn_has_slash_m(b, iadd(i, 1), en, rem - 1)

fun rename_trimmed_step(old: !Buf, trimmed: !Buf, out_new: &Buf >> Buf): bool = let
  var dir = buf_make(DO_RENAME_DIR_INITIAL_BYTES)
  val () = dirname_of(old, dir)
  val () = child_path(dir, trimmed, out_new)
  val old_is_md = not(path_is_dir(buffer_c_string(old))) andalso ends_ci(old, ".md")
  val need_md = old_is_md andalso not(ends_ci(trimmed, ".md"))
  val () = buffer_append_string_if(out_new, toggle_of(need_md), ".md")
  val () = buf_free(dir)
in
  if ieq(c_strcmp(buffer_c_string(old), buffer_c_string(out_new)), 0) then false
  else let
    val rn = fs_rename(buffer_c_string(old), buffer_c_string(out_new))
    val () = if ieq(rn, 0) then () else report_failure("tree_rename", buffer_c_string(old))
  in
    ieq(rn, 0)
  end
end

fun rn_validate_and_go(old: !Buf, trimmed: !Buf, out_new: &Buf >> Buf): bool = let
  val tlen = buf_len(trimmed)
  val ts = buffer_c_string(trimmed)
  val bad = ieq(c_strcmp(ts, "."), 0) orelse ieq(c_strcmp(ts, ".."), 0)
    orelse rn_has_slash_m(trimmed, 0, tlen, airlock_nat(tlen))
in
  if bad then false else rename_trimmed_step(old, trimmed, out_new)
end

implement do_rename_resolved(old, name, out_new) = let
  val () = buffer_clear(out_new)
  val n = buf_len(name)
  val st = rn_trim_left_m(name, 0, n, airlock_nat(n))
  val en = rn_trim_right_m(name, st, n, airlock_nat(n))
in
  if ige(st, en) then false
  else let
    var trimmed = buf_make(DO_RENAME_PATH_INITIAL_BYTES)
    val () = buffer_append_range(trimmed, name, st, en)
    val ok = rn_validate_and_go(old, trimmed, out_new)
    val () = buf_free(trimmed)
  in
    ok
  end
end

implement do_rename(old, name) = let
  var out_new = buf_make(DO_RENAME_PATH_INITIAL_BYTES)
  val _ = do_rename_resolved(old, name, out_new)
in
  buf_free(out_new)
end

implement do_delete(path) = let
  val p = buffer_c_string(path)
  val u_ok = if path_is_dir(p) then fs_rmdir(p) else fs_unlink(p)
in
end

fun last_dot_m {rem:nat} .<rem>. (b: !Buf, i: int, last_d: int, rem: int(rem)): int =
  if rem = 0 then last_d
  else let
    val d2 = if ieq(buf_get(b, i), 46) andalso igt(i, 0) then i else last_d
  in
    last_dot_m(b, iadd(i, 1), d2, rem - 1)
  end

fun split_stem_ext(name: !Buf, is_dir: bool, stem: &Buf >> Buf, ext: &Buf >> Buf): void = let
  val n = buf_len(name)
  val dot = if is_dir orelse ile(n, 1) then ~1 else last_dot_m(name, 0, ~1, airlock_nat(n))
  val () = buffer_clear(stem)
  val () = buffer_clear(ext)
in
  if igt(dot, 0) then (
    buffer_append_range(stem, name, 0, dot);
    buffer_append_range(ext, name, dot, n)
  ) else
    buffer_append_range(stem, name, 0, n)
end

fun make_dup_candidate(dir: !Buf, stem: !Buf, ext: !Buf, n: int, dst: &Buf >> Buf): void = let
  val () = buffer_clear(dst)
  val dlen = buf_len(dir)
  val () = buffer_append_all(dst, dir)
  val () = if igt(dlen, 0) andalso ine(buf_get(dir, isub(dlen, 1)), 47) then buffer_push_byte(dst, 47) else ()
  val () = buffer_append_all(dst, stem)
  val () = buffer_push_byte(dst, 32)
  val () = buffer_append_integer(dst, n)
in
  buffer_append_all(dst, ext)
end

fun find_dup_path_m {rem:nat} .<rem>. (
  rem: int(rem), dir: !Buf, stem: !Buf, ext: !Buf, idx: int, out: &Buf >> Buf
): bool =
  if rem = 0 then false
  else let
    val () = make_dup_candidate(dir, stem, ext, idx, out)
  in
    if ieq(fs_exists(buffer_c_string(out)), 0) then true
    else find_dup_path_m(rem - 1, dir, stem, ext, iadd(idx, 1), out)
  end

fun copy_dir_tree {depth:nat} .<depth, 2, 0>. (
  depth: int(depth), src: !Buf, dst: !Buf
): bool =
  if depth = 0 then false
  else if ine(fs_mkdir(buffer_c_string(dst)), 0) then false
  else let
    val dp = dir_open(buffer_c_string(src))
  in
    if dp = the_null_ptr then false
    else let
      val ok = copy_dir_step(depth, dp, src, dst, airlock_nat(MAX_DIR_ENTRIES))
      val () = dir_close(dp)
    in
      ok
    end
  end
and copy_dir_step {depth:pos}{rem:nat} .<depth, 1, rem>. (
  depth: int(depth), dp: ptr, src: !Buf, dst: !Buf, rem: int(rem)
): bool =
  if rem = 0 then true
  else let
    var name = buf_make(SCAN_DIR_IMPL_NAME_INITIAL_BYTES)
    var isdir: int = 0
    val has_next = dir_next_buf(dp, name, 255, isdir)
  in
    if ieq(has_next, 0) then (buf_free(name); true)
    else let
      val nlen = c_strlen(buf_cstr(name))
      val () = buf_set_len(name, nlen)
      val ok_entry = copy_dir_entry(depth, src, dst, name, isdir)
      val () = buf_free(name)
    in
      if ok_entry then copy_dir_step(depth, dp, src, dst, rem - 1) else false
    end
  end
and copy_dir_entry {depth:pos} .<depth, 0, 0>. (
  depth: int(depth), src: !Buf, dst: !Buf, name: !Buf, isdir: int
): bool = let
  val ns = buffer_c_string(name)
in
  if ieq(c_strcmp(ns, "."), 0) orelse ieq(c_strcmp(ns, ".."), 0) then true
  else let
    val c_src = join2(src, name)
    val c_dst = join2(dst, name)
    val is_d = path_is_dir(buffer_c_string(c_src)) orelse ieq(isdir, 1)
    val ok =
      if is_d then copy_dir_tree(depth - 1, c_src, c_dst)
      else ieq(fs_copy_file(buffer_c_string(c_src), buffer_c_string(c_dst)), 0)
  in
    buf_free(c_src); buf_free(c_dst); ok
  end
end

fun dup_with_parts(
  src_path: !Buf, is_dir: bool, dir: !Buf, stem: !Buf, ext: !Buf, out_path: &Buf >> Buf
): bool = let
  val dlen = buf_len(dir)
  val found: bool = if igt(dlen, 0) then find_dup_path_m(airlock_nat(1000), dir, stem, ext, 1, out_path) else false
in
  if found then (
    if is_dir then copy_dir_tree(16, src_path, out_path)
    else ieq(fs_copy_file(buffer_c_string(src_path), buffer_c_string(out_path)), 0)
  ) else false
end

implement do_duplicate(src_path, is_dir, out_path) = let
  val () = buffer_clear(out_path)
  val slen = buf_len(src_path)
in
  if ile(slen, 0) then false
  else let
    var dir = buf_make(64)
    var name = buf_make(64)
    var stem = buf_make(64)
    var ext = buf_make(16)
    val () = dirname_of(src_path, dir)
    val () = base_name(src_path, name)
    val () = split_stem_ext(name, is_dir, stem, ext)
    val ok = dup_with_parts(src_path, is_dir, dir, stem, ext, out_path)
    val () = buf_free(dir); val () = buf_free(name); val () = buf_free(stem); val () = buf_free(ext)
  in
    ok
  end
end

fun buf_prefix_eq_m {rem:nat} .<rem>. (a: !Buf, b: !Buf, i: int, rem: int(rem)): bool =
  if rem = 0 then true
  else ieq(buf_get(a, i), buf_get(b, i)) andalso buf_prefix_eq_m(a, b, iadd(i, 1), rem - 1)

fun has_dotdot_segment_m {rem:nat} .<rem>. (
  b: !Buf, i: int, en: int, at_seg_start: bool, rem: int(rem)
): bool =
  if rem = 0 then false
  else if ige(i, en) then false
  else let
    val c = buf_get(b, i)
  in
    if at_seg_start andalso ieq(c, 46) andalso ilt(iadd(i, 1), en) andalso ieq(buf_get(b, iadd(i, 1)), 46)
       andalso (ieq(iadd(i, 2), en) orelse ieq(buf_get(b, iadd(i, 2)), 47)) then true
    else has_dotdot_segment_m(b, iadd(i, 1), en, ieq(c, 47), rem - 1)
  end

fun path_strictly_inside_vault(vault: !Buf, target: !Buf): bool = let
  val vlen0 = buf_len(vault)
  val vlen = if igt(vlen0, 1) andalso ieq(buf_get(vault, isub(vlen0, 1)), 47) then isub(vlen0, 1) else vlen0
  val tlen = buf_len(target)
in
  igt(vlen, 0) andalso igt(tlen, iadd(vlen, 1))
    andalso ieq(buf_get(target, vlen), 47)
    andalso buf_prefix_eq_m(target, vault, 0, airlock_nat(vlen))
    andalso not(has_dotdot_segment_m(target, iadd(vlen, 1), tlen, true, airlock_nat(imax(0, isub(tlen, iadd(vlen, 1))))))
end

implement do_delete_in_vault(vault, target, is_dir) =
  if not(path_strictly_inside_vault(vault, target)) then false
  else let
    val p = buffer_c_string(target)
  in
    if ieq(fs_exists(p), 0) then false
    else let
      val () = if is_dir orelse path_is_dir(p) then fs_remove_tree(p) else seen_int(fs_unlink(p))
    in
      ieq(fs_exists(p), 0)
    end
  end
