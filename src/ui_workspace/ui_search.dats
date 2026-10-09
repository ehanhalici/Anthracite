#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_search.sats"
staload "airlock.sats"
staload "os/diag.sats"


fun eq_loop {rem:nat} .<rem>. (b: !Buf, q: !Buf, i: int, rem: int(rem), k: int): int =
  if rem > 0 then
    (if ine(buf_get(b, iadd(i, k)), buf_get(q, k)) then 0 else eq_loop(b, q, i, rem - 1, iadd(k, 1)))
  else 1

fun eq_at(b: !Buf, q: !Buf, i: int, k: int): int =
  if ige(k, buf_len(q)) then 1
  else eq_loop(b, q, i, airlock_span(k, buf_len(q)), k)

fun has_at(b: !Buf, q: !Buf, i: int): int =
  if igt(iadd(i, buf_len(q)), buf_len(b)) then 0 else eq_at(b, q, i, 0)

fun find_loop {rem:nat} .<rem>. (b: !Buf, q: !Buf, rem: int(rem), i: int): int =
  if rem > 0 then
    (if ieq(has_at(b, q, i), 1) then i else find_loop(b, q, rem - 1, iadd(i, 1)))
  else ~1

fun find_in(b: !Buf, q: !Buf, z: int, i: int): int =
  if igt(iadd(i, buf_len(q)), z) then ~1
  else find_loop(b, q, airlock_span(iadd(i, buf_len(q)), iadd(z, 1)), i)

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

fun header_if(hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, path: !Buf, line: int, headed: Toggle): void =
  if is_off(headed) then push_header(hits, hmeta, hn, path, line)
  else let
    val () = touchb(hits)
  in
    touchb(hmeta)
  end

fun record_line(b: !Buf, path: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, ls: int, i0: int, line: int, headed: Toggle, at: int): int =
  if ilt(at, 0) then let
    val () = touchb(hits)
    val () = touchb(hmeta)
  in
    toggle_int(headed)
  end else let
    val () = header_if(hits, hmeta, hn, path, line, headed)
    val () = push_hit(hits, hmeta, hn, b, q, ls, i0, at)
  in
    1
  end

fun read_or(b: &Buf >> _, fd: int, sz: int): int =
  if fd < 0 then 0 else fs_read_buf(fd, b, sz)

fun walk_stop(hits: &Buf >> _, hmeta: &Buf >> _): void = let
  val () = touchb(hits)
in
  touchb(hmeta)
end

(* rem = buf_len(b) + 1 - i0: the line walk visits positions i0 .. buf_len(b). *)
fun walk_loop {rem:nat} .<rem>. (b: !Buf, path: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, rem: int(rem), i0: int, line: int, ls: int, headed: Toggle): void =
  if rem > 0 then
    (if ige(hn, MAX_SEARCH_HITS) then walk_stop(hits, hmeta)
     else if ieq(i0, buf_len(b)) orelse ieq(buf_get(b, i0), 10) then let
       val at = find_in(b, q, i0, ls)
       val hd = record_line(b, path, q, hits, hmeta, hn, ls, i0, line, headed, at)
     in
       walk_loop(b, path, q, hits, hmeta, hn, rem - 1, iadd(i0, 1), iadd(line, 1), iadd(i0, 1), toggle_of(ieq(hd, 1)))
     end else let
       val () = touchb(hits)
       val () = touchb(hmeta)
     in
       walk_loop(b, path, q, hits, hmeta, hn, rem - 1, iadd(i0, 1), line, ls, headed)
     end)
  else walk_stop(hits, hmeta)

fun walk_lines(b: !Buf, path: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, i0: int, line: int, ls: int, headed: Toggle): void =
  if igt(i0, buf_len(b)) then walk_stop(hits, hmeta)
  else walk_loop(b, path, q, hits, hmeta, hn, airlock_span(i0, iadd(buf_len(b), 1)), i0, line, ls, headed)

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
    val () = walk_lines(b, path, q, hits, hmeta, hn, 0, 1, 0, Off)
  in
    buf_free(b)
  end
end

fun search_file_if(child: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, go: Toggle): void =
  if is_on(go) then search_file(child, q, hits, hmeta, hn)
  else let
    val () = touchb(hits)
  in
    touchb(hmeta)
  end

(* Directory walk. [d] is the remaining descent budget (MAX_TREE_DEPTH - depth)
   and [f] the remaining entry budget of one directory (MAX_DIR_ENTRIES).
   Termination metrics: a subdirectory gets d-1 and a fresh entry budget;
   every entry consumes one unit of f. *)
fun walk_drain(hits: &Buf >> _, hmeta: &Buf >> _, name: &Buf >> _): void = let
  val () = touchb(hits)
  val () = touchb(hmeta)
in
  touchb(name)
end

fun walk_skip(hits: &Buf >> _, hmeta: &Buf >> _): void = let
  val () = touchb(hits)
in
  touchb(hmeta)
end

fun walk_open {d:nat}{f:nat} .<d, f+2>. (path: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, d: int(d), f: int(f)): void = let
  val p = cstr(path)
  val dp = dir_open(p)
  var name = buf_make(256)
  var isdir: int = 0
in
  if dp = 0 then let
    val () = walk_drain(hits, hmeta, name)
  in
    buf_free(name)
  end else let
    val () = walk_entries(dp, path, q, hits, hmeta, hn, d, f, name, isdir)
    val () = dir_close(dp)
  in
    buf_free(name)
  end
end

and walk_entries {d:nat}{f:nat} .<d, f+1>. (dp: ptr, path: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, d: int(d), f: int(f), name: &Buf >> _, isdir: &int >> _): void =
  if f > 0 then
    (if dir_next_buf(dp, name, 255, isdir) = 0 then walk_drain(hits, hmeta, name)
     else let
       val () = walk_entry(path, q, hits, hmeta, hn, d, name, isdir)
     in
       walk_entries(dp, path, q, hits, hmeta, hn, d, f - 1, name, isdir)
     end)
  else let
    val () = report_failure("dir_scan_truncated", cstr(path))
  in
    walk_drain(hits, hmeta, name)
  end

and walk_entry {d:nat} .<d, 1>. (path: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, d: int(d), name: &Buf >> _, isdir: &int >> _): void = let
  val ns = buf_cstr(name)
  val () = buf_set_len(name, c_strlen(ns))
  val skip = scan_skip(name)
  val child = join2(path, name)
  val isd = child_kind(child, toggle_of(skip), dir_mark_of(isdir))
  val godir = if not(skip) andalso ieq(isd, 1) then 1 else 0
  val () = walk_child(child, q, hits, hmeta, hn, d, toggle_of(ieq(godir, 1)))
  val gofile = if not(skip) andalso ieq(isd, 0) andalso ieq(ends(child, ".md"), 1) then 1 else 0
  val () = search_file_if(child, q, hits, hmeta, hn, toggle_of(ieq(gofile, 1)))
  val () = buf_free(child)
in
end

and walk_child {d:nat} .<d, 0>. (child: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, d: int(d), go: Toggle): void =
  if is_on(go) then
    (if d > 0 then walk_open(child, q, hits, hmeta, hn, d - 1, airlock_span(0, MAX_DIR_ENTRIES))
     else walk_skip(hits, hmeta))
  else walk_skip(hits, hmeta)

fun search_dir_impl(path: !Buf, q: !Buf, hits: &Buf >> _, hmeta: &Buf >> _, hn: &int >> _, depth: int): void =
  if igt(depth, MAX_TREE_DEPTH) then walk_skip(hits, hmeta)
  else walk_open(path, q, hits, hmeta, hn, airlock_span(depth, MAX_TREE_DEPTH), airlock_span(0, MAX_DIR_ENTRIES))

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
    font_draw_at(f, r, x, y, hits, off, n, c)
  end
