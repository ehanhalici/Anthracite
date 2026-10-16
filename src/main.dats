#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "os/fs.sats"
staload "core_platform/platform.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "core_runtime/selftest.sats"
staload "core_runtime/application.sats"
staload "data_ast/document/doc.sats"

macdef FIRST_ARGUMENT = 1
macdef FOLD_PATH_ARGUMENT = 2

fun run_display(p: Plat, started_at: lint): void = let
  val r = rend_open()
  val selftest = c_argc() > FIRST_ARGUMENT andalso c_strcmp(c_argv(FIRST_ARGUMENT), "--selftest") = 0
  val () = if selftest then runtime_selftest(p, r, started_at) else application_run(p, r)
  val () = rend_close(r)
in
  plat_close(p)
end

fun start_application(): void = let
  val t0 = mono_ns()
  val p = plat_open()
in
  if not(plat_ok(p)) then let
    val () = println! ("event=display_error status=failed error=cannot_open_display")
  in
    plat_close(p)
  end else run_display(p, t0)
end

implement main0() = let
  val fold_dump = c_argc() > FOLD_PATH_ARGUMENT andalso c_strcmp(c_argv(FIRST_ARGUMENT), "--fold-dump") = 0
in
  if fold_dump then doc_fold_dump(c_argv(FOLD_PATH_ARGUMENT)) else start_application()
end
