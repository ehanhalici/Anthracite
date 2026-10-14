#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "os/fs.sats"
staload "core_platform/platform.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "core_runtime/selftest.sats"
staload "core_runtime/application.sats"

implement main0() = let
  val t0 = mono_ns()
  val p = plat_open()
in
  if not(plat_ok(p)) then let
    val () = println! ("event=display_error status=failed error=cannot_open_display")
    val () = plat_close(p)
  in
    ()
  end else let
    val r = rend_open()
    val selftest = c_argc() > 1 andalso c_strcmp(c_argv(1), "--selftest") = 0
    val () = if selftest then runtime_selftest(p, r, t0) else application_run(p, r)
    val () = rend_close(r)
    val () = plat_close(p)
  in
    ()
  end
end
