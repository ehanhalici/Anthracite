#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "os/fs.sats"
staload "core_platform/platform.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/resources/font.sats"
staload "data_ast/document/doc.sats"
staload "data_image/image.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/application/ui.sats"
staload "core_runtime/clipboard.sats"
staload "core_runtime/selftest.sats"

macdef SELFTEST_MIN_POLL_MS = 80
macdef SELFTEST_POLL_TIMEOUT_MS = 100
macdef SELFTEST_LIVE_MEMORY_BUDGET_BYTES = 12582912
macdef SELFTEST_TITLE_X = 24
macdef SELFTEST_TITLE_Y = 48
macdef SELFTEST_TITLE = "Anthracite"

fun run_core_selftests(r: !Rend): int = let
  val font_result = font_selftest(r)
  val doc_result = doc_selftest()
  val image_result = img_selftest()
  val app_result = app_selftest(r)
  val () = println! ("font_selftest=", font_result)
  val () = println! ("doc_selftest=", doc_result)
  val () = println! ("img_selftest=", image_result)
  val () = println! ("app_selftest=", app_result)
  val ok = if ieq(font_result, 1) andalso ieq(doc_result, 1) andalso ieq(image_result, 1) andalso ieq(app_result, 1) then 1 else 0
in
  ok
end

fun print_start(start: int): void = let
  val () = print("budget start_ms=")
in
  print_int(start)
end

fun print_rss(rss: int): void = let
  val () = print(" rss_kb=")
in
  print_int(rss)
end

fun print_live(live: int): void = let
  val () = print(" live=")
in
  print_int(live)
end

fun print_poll(waited: int): void = let
  val () = print(" poll_ms=")
in
  print_int(waited)
end

fun print_clip(clip_ok: int): void = let
  val () = print(" clip=")
in
  print_int(clip_ok)
end

fun print_health(poll_ok: int, rss_ok: int): void = let
  val () = print(" poll_ok=")
  val () = print_int(poll_ok)
  val () = print(" rss_ok=")
in
  print_int(rss_ok)
end

fun print_budget_metrics(start: int, rss: int, live: int, waited: int, clip_ok: int, poll_ok: int, rss_ok: int): void = let
  val () = print_start(start)
  val () = print_rss(rss)
  val () = print_live(live)
  val () = print_poll(waited)
  val () = print_clip(clip_ok)
  val () = print_health(poll_ok, rss_ok)
in
  print_newline()
end

fun draw_self_frame(p: !Plat, r: !Rend, f: !Font): void = let
  var w: int = 0
  var h: int = 0
  val () = platform_dimensions(p, w, h)
  val () = rend_begin(r, w, h)
  val () = rend_rect(r, 0, 0, w, h, col_bg())
  val () = seen_int(font_draw(f, r, SELFTEST_TITLE_X, SELFTEST_TITLE_Y,
    c_str_ptr(SELFTEST_TITLE), c_strlen(SELFTEST_TITLE), col_text()))
  val () = rend_flush(r)
  val () = plat_swap(p)
in
end

fun self_poll_ms(p: !Plat): int = let
  val before_wait = mono_ns()
  val () = seen_int(plat_wait(p, SELFTEST_POLL_TIMEOUT_MS))
  val after_wait = mono_ns()
in
  anth_ms(before_wait, after_wait)
end

implement runtime_selftest(p, r, started_at) = let
  val f = font_open()
  val () = draw_self_frame(p, r, f)
  val elapsed = anth_ms(started_at, mono_ns())
  val core_ok = run_core_selftests(r)
  val clip_result = clipboard_selftest(p)
  val waited = self_poll_ms(p)
  val rss = rss_kb()
  val live = mem_live()
  val poll_ok = if waited >= SELFTEST_MIN_POLL_MS then 1 else 0
  val rss_ok = if live > 0 andalso live < SELFTEST_LIVE_MEMORY_BUDGET_BYTES then 1 else 0
  val () = print_budget_metrics(elapsed, rss, live, waited, clip_result, poll_ok, rss_ok)
  val () = font_free(f)
  val () = plat_stop(p)
  val all_ok = if ieq(core_ok, 1) andalso ieq(clip_result, 1) andalso ieq(poll_ok, 1) andalso ieq(rss_ok, 1) then 1 else 0
  val () = if ieq(all_ok, 0) then println! ("event=selftest status=failed") else ()
in
  all_ok
end
