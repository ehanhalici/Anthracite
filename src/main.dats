#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "os/fs.sats"
staload "mem.sats"
staload "core_platform/platform.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "core_runtime/selftest.sats"
staload "core_runtime/application.sats"
staload "data_ast/document/doc.sats"

macdef FIRST_ARGUMENT = 1
macdef FOLD_PATH_ARGUMENT = 2

fun run_display(p: Plat, started_at: lint): void = let
  val before = mem_live()
  val r = rend_open()
  val selftest = c_argc() > FIRST_ARGUMENT andalso c_strcmp(c_argv(FIRST_ARGUMENT), "--selftest") = 0
  val ok = if selftest then runtime_selftest(p, r, started_at) else let
    val () = application_run(p, r)
  in
    1
  end
  val () = rend_close(r)
  val memory_ok = if selftest then runtime_selftest_memory_check(before) else 1
  val () = plat_close(p)
in
  if ieq(ok, 0) orelse ieq(memory_ok, 0) then exit(1) else ()
end

fun start_application(): void = let
  val t0 = mono_ns()
  val p = plat_open()
in
  if not(plat_ok(p)) then let
    val () = println! ("event=display_error status=failed error=cannot_open_display")
    val () = plat_close(p)
  in
    exit(1)
  end else run_display(p, t0)
end

implement main0() = let
  val fold_dump = c_argc() > FOLD_PATH_ARGUMENT andalso c_strcmp(c_argv(FIRST_ARGUMENT), "--fold-dump") = 0
in
  if fold_dump then doc_fold_dump(c_argv(FOLD_PATH_ARGUMENT)) else start_application()
end
