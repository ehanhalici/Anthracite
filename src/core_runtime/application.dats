#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "mem.sats"
staload "os/fs.sats"
staload "core_platform/platform.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "ui_workspace/application/ui.sats"
staload "core_runtime/event_loop.sats"
staload "core_runtime/application.sats"
staload "core_runtime/text_engine_startup.sats"

fun vault_at(cwd: !Buf, use_arg: bool): string =
  if use_arg then let
    val () = seen_buf(cwd)
  in
    c_argv(1)
  end else ""

fun workspace_path(): string = let
  var cwd = buf_make(4096)
  val count = c_cwd_buf(cwd, 4095)
  val size = if count > 0 then count else 0
  val () = buf_set_len(cwd, size)
  val () = buf_set(cwd, size, 0)
  val has_vault = c_argc() > 1
  val path = vault_at(cwd, has_vault)
  val () = buf_free(cwd)
in
  path
end

fun run_workspace(p: !Plat, r: !Rend, path: string): void = let
  val app = app_open(path)
  val font = font_open()
  val ready = workspace_font_start(font)
  val () = event_loop_run(p, app, font, r, ready)
  val () = font_free(font)
in
  app_free(app)
end

implement application_run(p, r) =
  run_workspace(p, r, workspace_path())
