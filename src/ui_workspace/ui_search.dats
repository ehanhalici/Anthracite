#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_search.sats"

fun scan_skip(name: !Buf): int =
  if ieq(buf_len(name), 0) then 1
  else if ieq(buf_get(name, 0), 46) then 1
  else 0

fun child_kind(child: !Buf, skip: int, isdir: int): int =
  if ieq(skip, 1) then 0
  else if ieq(isdir, 1) then 1
  else if ieq(isdir, 0) then 0
  else fs_isdir(cstr(child))

fun eq_at(b: !Buf, q: !Buf, i: int, k: int): int =
  if ige(k, buf_len(q)) then 1
  else if ine(buf_get(b, iadd(i, k)), buf_get(q, k)) then 0
  else eq_at(b, q, i, iadd(k, 1))

fun has_at(b: !Buf, q: !Buf, i: int): int =
  if igt(iadd(i, buf_len(q)), buf_len(b)) then 0 else eq_at(b, q, i, 0)

fun find_in(b: !Buf, q: !Buf, z: int, i: int): int =
  if igt(iadd(i, buf_len(q)), z) then ~1
  else if ieq(has_at(b, q, i), 1) then i
  else find_in(b, q, z, iadd(i, 1))

fun push_header(hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, path: !Buf, line: int): void = let
  val () = buf_ensure(hmeta, imul(iadd(hn, 2), 16))
  val () = buf_set32(hmeta, imul(hn, 4), ~1)
  val () = buf_set32(hmeta, iadd(imul(hn, 4), 1), buf_len(hits))
  val () = buf_set32(hmeta, iadd(imul(hn, 4), 2), buf_len(path))
  val () = buf_set32(hmeta, iadd(imul(hn, 4), 3), line)
  val () = bcat(hits, path, 0, buf_len(path))
in
  hn := iadd(hn, 1)
end

fun push_hit(hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, b: !Buf, q: !Buf, ls: int, i0: int, at: int): void = let
  val () = buf_ensure(hmeta, imul(iadd(hn, 1), 16))
  val () = buf_set32(hmeta, imul(hn, 4), isub(at, ls))
  val () = buf_set32(hmeta, iadd(imul(hn, 4), 1), buf_len(hits))
  val () = buf_set32(hmeta, iadd(imul(hn, 4), 2), isub(i0, ls))
  val () = buf_set32(hmeta, iadd(imul(hn, 4), 3), buf_len(q))
  val () = bcat(hits, b, ls, i0)
in
  hn := iadd(hn, 1)
end

fun header_if(hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, path: !Buf, line: int, headed: int): void =
  if ieq(headed, 0) then push_header(hits, hmeta, hn, path, line)
  else let
    val () = touchb(hits)
  in
    touchb(hmeta)
  end

fun record_line(b: !Buf, path: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, ls: int, i0: int, line: int, headed: int, at: int): int =
  if ilt(at, 0) then let
    val () = touchb(hits)
    val () = touchb(hmeta)
  in
    headed
  end else let
    val () = header_if(hits, hmeta, hn, path, line, headed)
    val () = push_hit(hits, hmeta, hn, b, q, ls, i0, at)
  in
    1
  end

fun read_or(b: &Buf >> _, fd: int, sz: int): int =
  if fd < 0 then 0 else fs_read(fd, buf_ptr(b), sz)

fun walk_lines(b: !Buf, path: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, i0: int, line: int, ls: int, headed: int): void =
  if igt(i0, buf_len(b)) orelse ige(hn, 200) then let
    val () = touchb(hits)
  in
    touchb(hmeta)
  end else if ieq(i0, buf_len(b)) orelse ieq(buf_get(b, i0), 10) then let
    val at = find_in(b, q, i0, ls)
    val hd = record_line(b, path, q, hits, hmeta, hn, ls, i0, line, headed, at)
  in
    walk_lines(b, path, q, hits, hmeta, hn, iadd(i0, 1), iadd(line, 1), iadd(i0, 1), hd)
  end else let
    val () = touchb(hits)
    val () = touchb(hmeta)
  in
    walk_lines(b, path, q, hits, hmeta, hn, iadd(i0, 1), line, ls, headed)
  end

fun search_file(path: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _): void = let
  val p = cstr(path)
  val sz = fs_size(p)
in
  if sz <= 0 orelse sz > 50000000 orelse ile(buf_len(q), 0) then let
    val () = touchb(hits)
  in
    touchb(hmeta)
  end else let
    val fd = fs_open_read(p)
    var b = buf_make(iadd(sz, 1))
    val n0 = read_or(b, fd, sz)
    val () = if fd >= 0 then fs_close(fd) else ()
    val n = if igt(n0, 0) then n0 else 0
    val () = buf_set_len(b, n)
    val () = walk_lines(b, path, q, hits, hmeta, hn, 0, 1, 0, 0)
  in
    buf_free(b)
  end
end

fun search_file_if(child: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, go: int): void =
  if ieq(go, 1) then search_file(child, q, hits, hmeta, hn)
  else let
    val () = touchb(hits)
  in
    touchb(hmeta)
  end

fun search_dir_impl(path: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, depth: int): void =
  if igt(depth, 6) then let
    val () = touchb(hits)
  in
    touchb(hmeta)
  end else let
    val p = cstr(path)
    val dp = dir_open(p)
    var name = buf_make(256)
    var isdir: int = 0
    val () = search_open(dp, path, q, hits, hmeta, hn, depth, name, isdir)
  in
    buf_free(name)
  end
and search_open(dp: ptr, path: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, depth: int, name: &Buf >> _, isdir: &int >> _): void =
  if dp = 0 then let
    val () = touchb(hits)
    val () = touchb(hmeta)
    val () = touchb(name)
  in
    ()
  end else let
    val () = search_step(dp, path, q, hits, hmeta, hn, depth, name, isdir)
    val () = dir_close(dp)
  in
    ()
  end
and search_step(dp: ptr, path: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, depth: int, name: &Buf >> _, isdir: &int >> _): void =
  if dir_next(dp, buf_ptr(name), 255, isdir) = 0 then let
    val () = touchb(hits)
    val () = touchb(hmeta)
    val () = touchb(name)
  in
    ()
  end else let
    val np = buf_ptr(name)
    val () = buf_set_len(name, c_strlen(ptr_string(np)))
    val skip = scan_skip(name)
    val child = join2(path, name)
    val isd = child_kind(child, skip, isdir)
    val godir = if ieq(skip, 0) andalso ieq(isd, 1) then 1 else 0
    val () = search_maybe(child, q, hits, hmeta, hn, iadd(depth, 1), godir)
    val gofile = if ieq(skip, 0) andalso ieq(isd, 0) andalso ieq(ends(child, ".md"), 1) then 1 else 0
    val () = search_file_if(child, q, hits, hmeta, hn, gofile)
    val () = buf_free(child)
  in
    search_step(dp, path, q, hits, hmeta, hn, depth, name, isdir)
  end
and search_maybe(child: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, depth: int, go: int): void =
  if ieq(go, 1) then search_dir_impl(child, q, hits, hmeta, hn, depth)
  else let
    val () = touchb(hits)
  in
    touchb(hmeta)
  end

implement search_dir(path, q, hits, hmeta, hn, depth) =
  search_dir_impl(path, q, hits, hmeta, hn, depth)

implement refresh_search(vault, q, hits, hmeta, hn) = let
  val () = bclear(hits)
  val () = bclear(hmeta)
  val () = hn := 0
in
  search_dir(vault, q, hits, hmeta, hn, 0)
end

implement find_hit_file(hmeta, hits, row, dst) = let
  val () = bclear(dst)
  var r: int = row
  var head_row: int = ~1
in
  while (ige(r, 0) andalso ilt(head_row, 0)) (
    if ilt(buf_get32(hmeta, imul(r, 4)), 0) then head_row := r
    else r := isub(r, 1)
  );
  if ige(head_row, 0) then let
    val off = buf_get32(hmeta, iadd(imul(head_row, 4), 1))
    val n = buf_get32(hmeta, iadd(imul(head_row, 4), 2))
  in
    bcat(dst, hits, off, iadd(off, n))
  end else ()
end

implement hit_text(hits, off, n, f, r, x, y, c) =
  if ile(n, 0) then 0
  else let
    val cap = buf_cap(hits)
  in
    font_draw(f, r, x, y, mem_ptr_at(buf_ptr(hits), cap, off), n, c)
  end
