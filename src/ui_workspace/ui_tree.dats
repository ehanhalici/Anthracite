#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "os/diag.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_tree.sats"

fun tree_add(meta: &Buf >> _, text: &Buf >> _, n: &int >> _, depth: int, isdir: DirMark, path: !Buf): void = let
  val () = buf_ensure(meta, imul(iadd(n, 1), 16))
  val () = buf_set32(meta, imul(n, 4), depth)
  val () = buf_set32(meta, iadd(imul(n, 4), 1), dir_mark_int(isdir))
  val () = buf_set32(meta, iadd(imul(n, 4), 2), buf_len(text))
  val () = buf_set32(meta, iadd(imul(n, 4), 3), buf_len(path))
  val () = bcat(text, path, 0, buf_len(path))
in
  n := iadd(n, 1)
end

fun tree_add_if(meta: &Buf >> _, text: &Buf >> _, n: &int >> _, depth: int, isdir: DirMark, path: !Buf, go: Toggle): void =
  if is_on(go) then tree_add(meta, text, n, depth, isdir, path)
  else let
    val () = touchb(meta)
    val () = touchb(text)
  in
    ()
  end

extern fun scan_step_exh(dp: ptr, path: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _, name: &Buf >> _, isdir: &int >> _): void = "mac#anth_die_void"

fun scan_dir_impl {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), path: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _): void =
  if recfuel > 0 then (
    if igt(depth, MAX_TREE_DEPTH) orelse ige(n, MAX_TREE_ITEMS) then let
      val () = touchb(meta)
    in
      touchb(text)
    end else let
      val p = cstr(path)
      val dp = dir_open(p)
      var name = buf_make(256)
      var isdir: int = 0
      val () = scan_open(recfuel - 1, dp, path, depth, meta, text, n, name, isdir)
    in
      buf_free(name)
    end
  ) else let
    val () = touchb(meta)
  in
    touchb(text)
  end
and scan_open {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dp: ptr, path: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _, name: &Buf >> _, isdir: &int >> _): void =
  if recfuel > 0 then (
    if dp = 0 then let
      val () = touchb(meta)
      val () = touchb(text)
      val () = touchb(name)
    in
      ()
    end else let
      val () = scan_step(recfuel - 1, dp, path, depth, meta, text, n, name, isdir)
      val () = dir_close(dp)
    in
      ()
    end
  ) else let
    val () = touchb(meta)
    val () = touchb(text)
  in
    touchb(name)
  end
and scan_step {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dp: ptr, path: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _, name: &Buf >> _, isdir: &int >> _): void =
  if recfuel > 0 then (
    if dir_next_buf(dp, name, 255, isdir) = 0 then let
      val () = touchb(meta)
      val () = touchb(text)
      val () = touchb(name)
    in
      ()
    end else let
      val () = scan_entry(recfuel - 1, path, depth, meta, text, n, name, isdir)
    in
      scan_step(recfuel - 1, dp, path, depth, meta, text, n, name, isdir)
    end
  ) else scan_step_exh(dp, path, depth, meta, text, n, name, isdir)
and scan_entry {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), path: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _, name: &Buf >> _, isdir: &int >> _): void =
  if recfuel > 0 then let
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
    val () = touchb(meta)
    val () = touchb(text)
  in
    touchb(name)
  end
and scan_maybe {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), child: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _, go: Toggle): void =
  if recfuel > 0 then (
    if is_on(go) then scan_dir_impl(recfuel - 1, child, depth, meta, text, n)
    else let
      val () = touchb(meta)
    in
      touchb(text)
    end
  ) else let
    val () = touchb(meta)
  in
    touchb(text)
  end

implement scan_dir(path, depth, meta, text, n) =
  scan_dir_impl(airlock_nat(MAX_REC_FUEL), path, depth, meta, text, n)

implement write_text(path, body) = let
  val n = buf_len(body)
in
  fs_write_buf(cstr(path), body, n)
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
    var path = buf_make(8)
    val () = child_path(dir, name, path)
    val has_dot = has_dot_char(name, 0)
    val need_md = not(isdir) andalso not(has_dot)
    val () = bstr_if(path, toggle_of(need_md), ".md")
    val p = cstr(path)
    val () = if isdir then create_dir_report(p) else create_file_report(p)
  in
    buf_free(path)
  end
end

implement do_rename(old, name) = let
  var dir = buf_make(8)
  var path = buf_make(8)
  val () = dirname_of(old, dir)
  val () = child_path(dir, name, path)
  val rn = fs_rename(cstr(old), cstr(path))
  val () = if ieq(rn, 0) then () else report_failure("tree_rename", cstr(old))
  val () = buf_free(dir)
in
  buf_free(path)
end

implement do_delete(path) = let
  val p = cstr(path)
  val u_ok = if path_is_dir(p) then fs_rmdir(p) else fs_unlink(p)
in
end
