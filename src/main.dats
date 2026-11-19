#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "os/fs.sats"
staload "mem.sats"
staload "config/conf.sats"
staload "core_platform/platform.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "core_runtime/selftest.sats"
staload "core_runtime/application.sats"
staload "core_runtime/performance.sats"
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

fun lock_dir_path(base: &Buf >> Buf, ok: bool): int =
  if not(ok) then ~2
  else let
    val lock_suf = "/instance.lock"
    val () = buf_append(base, c_str_ptr(lock_suf), c_strlen(lock_suf))
    var owner_pid: int = 0
    val path = buf_cstr(base)
    val fd = fs_instance_lock(path, owner_pid)
    val () = if ieq(fd, ~1) then
      println!("event=single_instance status=blocked reason=already_running pid=", owner_pid, " lock_path=", path)
    else ()
  in
    fd
  end

fun acquire_instance_lock(): int = let
  var base = buf_make(256)
  val ok = conf_init_dirs(base)
  val fd = lock_dir_path(base, ok)
  val () = buf_free(base)
in
  fd
end

fun is_selftest_arg(): bool =
  c_argc() > FIRST_ARGUMENT andalso c_strcmp(c_argv(FIRST_ARGUMENT), "--selftest") = 0

fun run_with_instance_guard(): void = let
  val selftest_isolated = is_selftest_arg() andalso ieq(c_strlen(c_getenv("ANTHRACITE_CONFIG_DIR")), 0)
  val lock_fd = if selftest_isolated then ~3 else acquire_instance_lock()
in
  if ieq(lock_fd, ~1) then exit(1)
  else let
    val () = start_application()
  in
    fs_instance_unlock(lock_fd)
  end
end

implement main0() = let
  val () = performance_runtime_init()
  val fold_dump = c_argc() > FOLD_PATH_ARGUMENT andalso c_strcmp(c_argv(FIRST_ARGUMENT), "--fold-dump") = 0
in
  if fold_dump then doc_fold_dump(c_argv(FOLD_PATH_ARGUMENT)) else run_with_instance_guard()
end
