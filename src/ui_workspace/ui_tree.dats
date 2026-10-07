#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "os/fs.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_tree.sats"

fun tree_add(meta: &Buf >> _, text: &Buf >> _, n: &int >> _, depth: int, isdir: int, path: !Buf): void = let
  val () = buf_ensure(meta, imul(iadd(n, 1), 16))
  val () = buf_set32(meta, imul(n, 4), depth)
  val () = buf_set32(meta, iadd(imul(n, 4), 1), isdir)
  val () = buf_set32(meta, iadd(imul(n, 4), 2), buf_len(text))
  val () = buf_set32(meta, iadd(imul(n, 4), 3), buf_len(path))
  val () = bcat(text, path, 0, buf_len(path))
in
  n := iadd(n, 1)
end

fun tree_add_if(meta: &Buf >> _, text: &Buf >> _, n: &int >> _, depth: int, isdir: int, path: !Buf, go: int): void =
  if ieq(go, 1) then tree_add(meta, text, n, depth, isdir, path)
  else let
    val () = touchb(meta)
    val () = touchb(text)
  in
    ()
  end

fun scan_skip(name: !Buf): int =
  if ieq(buf_len(name), 0) then 1
  else if ieq(buf_get(name, 0), 46) then 1
  else 0

fun child_kind(child: !Buf, skip: int, isdir: int): int =
  if ieq(skip, 1) then 0
  else if ieq(isdir, 1) then 1
  else if ieq(isdir, 0) then 0
  else fs_isdir(cstr(child))

fun scan_dir_impl(path: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _): void =
  if igt(depth, 6) orelse ige(n, 400) then let
    val () = touchb(meta)
  in
    touchb(text)
  end else let
    val p = cstr(path)
    val dp = dir_open(p)
    var name = buf_make(256)
    var isdir: int = 0
    val () = scan_open(dp, path, depth, meta, text, n, name, isdir)
  in
    buf_free(name)
  end
and scan_open(dp: ptr, path: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _, name: &Buf >> _, isdir: &int >> _): void =
  if dp = 0 then let
    val () = touchb(meta)
    val () = touchb(text)
    val () = touchb(name)
  in
    ()
  end else let
    val () = scan_step(dp, path, depth, meta, text, n, name, isdir)
    val () = dir_close(dp)
  in
    ()
  end
and scan_step(dp: ptr, path: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _, name: &Buf >> _, isdir: &int >> _): void =
  if dir_next(dp, buf_ptr(name), 255, isdir) = 0 then let
    val () = touchb(meta)
    val () = touchb(text)
    val () = touchb(name)
  in
    ()
  end else let
    val np = buf_ptr(name)
    val () = buf_set_len(name, c_strlen(ptr_string(np)))
    val skip = scan_skip(name)
    val child = join2(path, name)
    val isd = child_kind(child, skip, isdir)
    val goadd = if ieq(skip, 0) andalso ilt(n, 400) then 1 else 0
    val () = tree_add_if(meta, text, n, depth, isd, child, goadd)
    val godir = if ieq(skip, 0) andalso ieq(isd, 1) then 1 else 0
    val () = scan_maybe(child, iadd(depth, 1), meta, text, n, godir)
    val () = buf_free(child)
  in
    scan_step(dp, path, depth, meta, text, n, name, isdir)
  end
and scan_maybe(child: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _, go: int): void =
  if ieq(go, 1) then scan_dir_impl(child, depth, meta, text, n)
  else let
    val () = touchb(meta)
  in
    touchb(text)
  end

implement scan_dir(path, depth, meta, text, n) =
  scan_dir_impl(path, depth, meta, text, n)

implement write_text(path, body) = let
  val fd = fs_open_write(cstr(path))
in
  if fd < 0 then 0
  else let
    val n = fs_write(fd, buf_ptr(body), buf_len(body))
    val () = fs_close(fd)
  in
    if ige(n, 0) then 1 else 0
  end
end

implement do_create(dir, name, isdir) = let
  val nlen = buf_len(name)
in
  if nlen <= 0 then ()
  else let
    var path = buf_make(8)
    val () = child_path(dir, name, path)
    val has_dot = has_dot_char(name, 0)
    val need_md = if ieq(isdir, 0) andalso ieq(has_dot, 0) then 1 else 0
    val () = bstr_if(path, need_md, ".md")
    val p = cstr(path)
    val () = if ieq(isdir, 1) then let val _m = fs_mkdir(p) in end else let
      val fd = fs_open_write(p)
    in
      if fd >= 0 then fs_close(fd) else ()
    end
  in
    buf_free(path)
  end
end

implement do_rename(old, name) = let
  var dir = buf_make(8)
  var path = buf_make(8)
  val () = dirname_of(old, dir)
  val () = child_path(dir, name, path)
  val _r = fs_rename(cstr(old), cstr(path))
  val () = buf_free(dir)
in
  buf_free(path)
end

implement do_delete(path) = let
  val p = cstr(path)
  val _u = if ieq(fs_isdir(p), 1) then fs_rmdir(p) else fs_unlink(p)
in
end
