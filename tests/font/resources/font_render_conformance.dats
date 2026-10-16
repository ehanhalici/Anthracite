#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "data_font/resources/font.sats"
staload "core_platform/platform.sats"
staload "core_render/render.sats"
staload "font/resources/font_fixture.sats"
staload "font/atlas/font_glyph_id_contracts.sats"
staload "data_font/atlas/font_glyph_id.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "font/text/run/font_run_render_contracts.sats"
staload "font/native/ownership/font_native_contracts.sats"

fun glyph(f: !Font, r: !Rend, cp: int): gmet = let
  var g: gmet = @{ax=0,bx=0,top=0,bw=0,bh=0,x0=0,y0=0,ok=Off()}
  val () = font_glyph(f,r,cp,g)
in g end

fun test_outline(r: !Rend, path: string, invalid: string): int = let
  val f = font_open()
  val loaded = font_use_file(f,path)
  val () = font_set_px(f,48)
  val g = glyph(f,r,65)
  val accepted = font_use_file(f,invalid)
  val after = glyph(f,r,65)
  (* The two attached 100-unit squares span 200 units: 9.6 px at 48 ppem.
     The raster must cover that extent; atlas padding is not part of it. *)
  val ok = loaded andalso not(accepted) andalso ieq(g.ax,0)
    andalso ige(g.bw,10) andalso ige(g.bh,10) andalso ieq(g.top,10)
    andalso ieq(after.ax,g.ax) andalso ieq(after.bw,g.bw) andalso ieq(after.bh,g.bh)
  val () = println!("event=outline_render loaded=",loaded," advance=",g.ax,
    " width=",g.bw," height=",g.bh," top=",g.top," invalid_accepted=",accepted)
  val () = font_free(f)
in if ok then 0 else 1 end

fun test_marks(r: !Rend, path: string): int = let
  val f = font_open()
  val loaded = font_use_file(f,path)
  val mark = glyph(f,r,1614)
  val letter = glyph(f,r,1576)
  val ok = loaded andalso ieq(mark.ax,0) andalso igt(mark.bw,0)
    andalso igt(mark.bh,0) andalso igt(letter.ax,0)
  val () = println!("event=mark_render loaded=",loaded," mark_advance=",mark.ax,
    " mark_width=",mark.bw," letter_advance=",letter.ax)
  val () = font_free(f)
in if ok then 0 else 1 end

fun test_isolation(r: !Rend, latin: string, arabic: string): int = let
  val first = font_open()
  val second = font_open()
  val a = font_use_file(first,latin)
  val b = font_use_file(second,arabic)
  val fallback = font_use_fallback_file(first,arabic)
  val ornament = glyph(first,r,64830)
  val () = font_free(first)
  val surviving = glyph(second,r,64830)
  val ok = a andalso b andalso fallback andalso igt(ornament.bw,0)
    andalso ieq(ornament.ax,surviving.ax) andalso ieq(ornament.bw,surviving.bw)
    andalso ieq(ornament.bh,surviving.bh) andalso ieq(ornament.top,surviving.top)
  val () = font_free(second)
in if ok then 0 else 1 end

fun fixture_write(path: string, invalid: string): int = let
  val b = fixture_outline_font()
  val good = fs_write_buf(path,b,buf_len(b))
  val () = fixture_put32(b,0,0)
  val bad = fs_write_buf(invalid,b,buf_len(b))
  val () = buf_free(b)
in if igt(good,0) andalso igt(bad,0) then 0 else 1 end

fun report_result(a: int, b: int, c: int, d: int): void =
  println!("event=font_render_conformance outline_errors=",a,
    " mark_errors=",b," isolation_errors=",c," ownership_errors=",d)

fun test_faces(r: !Rend): int = let
  val before = mem_live()
  val outlines: int = test_outline(r,c_argv(1),c_argv(2))
  val marks: int = test_marks(r,c_argv(4))
  val isolated: int = test_isolation(r,c_argv(3),c_argv(4))
  val native: int = id_test_faces(r,c_argv(3),c_argv(4))
  val positioned: int = run_render_test_faces(r,c_argv(3),c_argv(4))
  val owned: int = native_font_suite(r)
  val leak_errors: int = if ieq(before,mem_live()) then 0 else 1
  val () = report_result(outlines,marks,isolated,leak_errors)
in iadd(owned,iadd(iadd(outlines,marks),iadd(isolated,iadd(native,iadd(positioned,leak_errors))))) end

fun with_display(): int = let
  val p = plat_open()
in if not(plat_ok(p)) then let val () = plat_close(p) in 1 end else let
    val r = rend_open()
    val () = rend_begin(r,640,480)
    val errors = test_faces(r)
    val () = rend_close(r)
    val () = plat_close(p)
  in errors end end

extern fun native_source_edit_cpu(generated: string,source: string): int = "ext#native_source_edit_cpu"
implement main0() =
  if ieq(c_argc(),3) then (if igt(native_source_edit_cpu(c_argv(1),c_argv(2)),0) then exit(1) else ())
  else if ine(c_argc(),5) andalso ine(c_argc(),7) then exit(2)
  else if igt(fixture_write(c_argv(1),c_argv(2)),0) then exit(1)
  else if igt(with_display(),0) then exit(1) else ()
