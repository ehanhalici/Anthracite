#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/font.sats"
staload "ui_workspace/ui_common.sats"

implement touchb(b) = ()
implement bclear(b) = buf_set_len(b, 0)
implement bpush(b, v) = buf_push(b, v)

implement push_if(b, go, v) =
  if ieq(go, 1) then buf_push(b, v) else touchb(b)

implement bappend(b, s, i, n) =
  if ige(i, n) then touchb(b)
  else let
    val () = buf_push(b, c_str_byte(s, i))
  in
    bappend(b, s, iadd(i, 1), n)
  end

implement bstr(b, s) = bappend(b, s, 0, c_strlen(s))

implement bstr_if(b, go, s) =
  if ieq(go, 1) then bstr(b, s) else touchb(b)

implement bcat(dst, src, i, n) =
  if ige(i, n) then touchb(dst)
  else let
    val () = buf_push(dst, buf_get(src, i))
  in
    bcat(dst, src, iadd(i, 1), n)
  end

implement bcat_if(dst, src, i, n, go) =
  if ieq(go, 1) then bcat(dst, src, i, n) else touchb(dst)

implement beq(a, b, i) =
  if ine(buf_len(a), buf_len(b)) then 0
  else if ige(i, buf_len(a)) then 1
  else if ine(buf_get(a, i), buf_get(b, i)) then 0
  else beq(a, b, iadd(i, 1))

implement bcopy(src) = let
  var d = buf_make(iadd(buf_len(src), 1))
  val n = buf_len(src)
  val () = bcat(d, src, 0, n)
in
  d
end

implement cstr(b) = let
  val n = buf_len(b)
  val () = buf_set(b, n, 0)
in
  ptr_string(buf_ptr(b))
end

fun ends_at(b: !Buf, s: string, n: int, m: int, i: int): int =
  if ige(i, m) then 1
  else if ine(buf_get(b, iadd(isub(n, m), i)), c_str_byte(s, i)) then 0
  else ends_at(b, s, n, m, iadd(i, 1))

implement ends(b, s) = let
  val n = buf_len(b)
  val m = c_strlen(s)
in
  if ilt(n, m) then 0 else ends_at(b, s, n, m, 0)
end

implement draw_s(f, r, x, y, s, c) =
  font_draw(f, r, x, y, c_str_ptr(s), c_strlen(s), c)

implement join2(a, b) = let
  var d = buf_make(iadd(iadd(buf_len(a), buf_len(b)), 2))
  val na = buf_len(a)
  val slash = if igt(na, 0) andalso ine(buf_get(a, isub(na, 1)), 47) then 1 else 0
  val () = bcat(d, a, 0, na)
  val () = push_if(d, slash, 47)
  val () = bcat(d, b, 0, buf_len(b))
in
  d
end

implement last_slash(path, i, a) =
  if ige(i, buf_len(path)) then a
  else last_slash(path, iadd(i, 1), iif(ieq(buf_get(path, i), 47), iadd(i, 1), a))

implement base_name(path, dst) = let
  val a = last_slash(path, 0, 0)
  val () = bclear(dst)
in
  bcat(dst, path, a, buf_len(path))
end

fun slash_at(path: !Buf, i: int, a: int): int =
  if ige(i, buf_len(path)) then a
  else slash_at(path, iadd(i, 1), iif(ieq(buf_get(path, i), 47), i, a))

implement dirname_of(path, dst) = let
  val sl = slash_at(path, 0, ~1)
  val () = bclear(dst)
in
  bcat_if(dst, path, 0, sl, iif(ige(sl, 0), 1, 0))
end

implement child_path(dir, name, dst) = let
  val () = bclear(dst)
  val () = bcat(dst, dir, 0, buf_len(dir))
  val nd = buf_len(dir)
  val need_slash = if igt(nd, 0) andalso ine(buf_get(dir, isub(nd, 1)), 47) then 1 else 0
  val () = if ieq(need_slash, 1) then buf_push(dst, 47) else ()
in
  bcat(dst, name, 0, buf_len(name))
end

implement row_path(text, meta, row, dst) = let
  val off = buf_get32(meta, iadd(imul(row, 4), 2))
  val n = buf_get32(meta, iadd(imul(row, 4), 3))
  val () = bclear(dst)
in
  bcat(dst, text, off, iadd(off, n))
end

implement has_dot_char(b, i) =
  if ige(i, buf_len(b)) then 0
  else if ieq(buf_get(b, i), 46) then 1
  else has_dot_char(b, iadd(i, 1))

implement uok(t) = anth_u2i(t)
