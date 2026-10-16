#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "os/fs.sats"
staload "os/selftest_fixture.sats"

macdef FIXTURE_ROOT_CAPACITY_BYTES = 256

implement selftest_fixture_open(root) = let
  val () = buf_ensure(root, FIXTURE_ROOT_CAPACITY_BYTES)
  val ok = fs_make_temp_dir(buf_ptr(root), buf_cap(root))
  val length = if ieq(ok, 1) then c_strlen(buf_cstr(root)) else 0
  val () = buf_set_len(root, length)
  val () = if ieq(ok, 0) then println!("event=selftest_fixture status=failed") else ()
in ieq(ok, 1) end

implement selftest_fixture_path(root, relative) = let
  var path = buf_make(iadd(iadd(c_strlen(root), c_strlen(relative)), 2))
  val () = buf_append(path, c_str_ptr(root), c_strlen(root))
  val () = buf_push(path, CHAR_SLASH)
  val () = buf_append(path, c_str_ptr(relative), c_strlen(relative))
  val length = buf_len(path)
  val () = buf_set(path, length, 0)
in path end
