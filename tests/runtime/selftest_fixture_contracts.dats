#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "os/fs.sats"
staload "os/selftest_fixture.sats"

fun isolated_paths(first: string, second: string): bool = let
  val path_a = selftest_fixture_path(first, "same.txt")
  val path_b = selftest_fixture_path(second, "same.txt")
  var text = buf_make(1)
  val () = buf_push(text, CHAR_LOWER_A)
  val written = fs_write_buf(buf_cstr(path_a), text, 1)
  val isolated = ieq(written, 1) andalso ieq(fs_exists(buf_cstr(path_b)), 0)
  val () = seen_int(fs_unlink(buf_cstr(path_a)))
  val () = buf_free(text)
  val () = buf_free(path_a)
  val () = buf_free(path_b)
in isolated end

implement main0() = let
  val before = mem_live()
  var first: Buf = buf_make(1)
  var second: Buf = buf_make(1)
  val opened_a = selftest_fixture_open(first)
  val opened_b = selftest_fixture_open(second)
  val unique = opened_a andalso opened_b andalso ine(c_strcmp(buf_cstr(first), buf_cstr(second)), 0)
  val isolated = if unique then isolated_paths(buf_cstr(first), buf_cstr(second)) else false
  val () = if opened_a then seen_int(fs_rmdir(buf_cstr(first))) else ()
  val () = if opened_b then seen_int(fs_rmdir(buf_cstr(second))) else ()
  val () = buf_free(first)
  val () = buf_free(second)
  val ok = isolated andalso ieq(before, mem_live())
  val () = println!("event=selftest_fixture_contracts ok=", ok)
in if ok then () else exit(1) end
