#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_render/gl.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"
staload "data_text/source/text_source.sats"

(* Type 2 CFF CharString VM and path point recording. *)
staload "data_font/resources/private/font_storage.sats"
staload "data_font/raster/private/font_outline_cff.sats"

#define CFF_OUTLINE_MAX_POINTS 3000
#define CFF_OUTLINE_MAX_ENDS 512

typedef CffVm = @{
  gid=int, off=int, len=int, pc=int,
  sp=int, depth=int, nstems=int, have_width=bool,
  x16=int, y16=int, cur_start=int, done=bool
}

fun fx_of_int(v: int): int =
  if ile(v, ~32768) then ~2147483647 - 1
  else if ige(v, 32767) then 2147418112
  else imul(v, WORD16_MODULUS)

fun fx_round(v: int): int =
  if ige(v, 0) then idiv(iadd(v, 32768), WORD16_MODULUS)
  else if ile(v, ~2147450880) then ~32768
  else isub(0, idiv(iadd(isub(0, v), 32768), WORD16_MODULUS))

fun push_pt(f: !Font, x16: int, y16: int, fl: int): void = let
  val n = font_get_point_count(f)
in
  if ige(n, 0) andalso ilt(n, CFF_OUTLINE_MAX_POINTS) then let
    val () = pt_set(f, n, fx_round(x16), fx_round(y16), fl)
  in
    font_set_point_count(f, iadd(n, 1))
  end else ()
end

fun close_contour(f: !Font, cur_start: int): int =
  if ilt(cur_start, 0) then ~1
  else let
    val npts = font_get_point_count(f)
    val nends = font_get_contour_count(f)
  in
    if igt(isub(npts, cur_start), 1) andalso ige(nends, 0) andalso ilt(nends, CFF_OUTLINE_MAX_ENDS) then let
      val () = end_set(f, nends, isub(npts, 1))
      val () = font_set_contour_count(f, iadd(nends, 1))
    in ~1 end
    else let
      val () = font_set_point_count(f, cur_start)
    in ~1 end
  end

fun vm_with_cursor(v: CffVm, sp: int, pc: int, x16: int, y16: int, cs: int, hw: bool): CffVm =
  @{gid=v.gid, off=v.off, len=v.len, pc=pc, sp=sp, depth=v.depth,
    nstems=v.nstems, have_width=hw, x16=x16, y16=y16, cur_start=cs, done=v.done}

fun vm_push_op(f: !Font, v: CffVm, fx: int, npc: int): CffVm = let
  val () = if ilt(v.sp, 48) then font_cff_stk_set(f, v.sp, fx) else ()
  val nsp = if ilt(v.sp, 48) then iadd(v.sp, 1) else v.sp
in
  vm_with_cursor(v, nsp, npc, v.x16, v.y16, v.cur_start, v.have_width)
end

fun cff_moveto(f: !Font, v: CffVm, dx16: int, dy16: int): CffVm = let
  val _ = close_contour(f, v.cur_start)
  val nx = iadd(v.x16, dx16)
  val ny = iadd(v.y16, dy16)
  val cs = font_get_point_count(f)
  val () = push_pt(f, nx, ny, 1)
in
  vm_with_cursor(v, 0, iadd(v.pc, 1), nx, ny, cs, true)
end

fun emit_cubic(f: !Font, x16: int, y16: int, dx1: int, dy1: int, dx2: int, dy2: int, dx3: int, dy3: int): @(int, int) = let
  val c1x = iadd(x16, dx1)
  val c1y = iadd(y16, dy1)
  val c2x = iadd(c1x, dx2)
  val c2y = iadd(c1y, dy2)
  val p3x = iadd(c2x, dx3)
  val p3y = iadd(c2y, dy3)
  val () = push_pt(f, c1x, c1y, 2)
  val () = push_pt(f, c2x, c2y, 3)
  val () = push_pt(f, p3x, p3y, 1)
in
  @(p3x, p3y)
end

fun run_rlineto {n:nat} .<n>. (
  rem: int(n), f: !Font, i: int, sp: int, x16: int, y16: int
): @(int, int) =
  if rem = 0 then @(x16, y16)
  else if igt(iadd(i, 2), sp) then @(x16, y16)
  else let
    val nx = iadd(x16, font_cff_stk_get(f, i))
    val ny = iadd(y16, font_cff_stk_get(f, iadd(i, 1)))
    val () = push_pt(f, nx, ny, 1)
  in
    run_rlineto(rem - 1, f, iadd(i, 2), sp, nx, ny)
  end

fun run_alt_lineto {n:nat} .<n>. (
  rem: int(n), f: !Font, i: int, sp: int, is_x: bool, x16: int, y16: int
): @(int, int) =
  if rem = 0 then @(x16, y16)
  else if ige(i, sp) then @(x16, y16)
  else let
    val d = font_cff_stk_get(f, i)
    val nx = if is_x then iadd(x16, d) else x16
    val ny = if is_x then y16 else iadd(y16, d)
    val () = push_pt(f, nx, ny, 1)
  in
    run_alt_lineto(rem - 1, f, iadd(i, 1), sp, not(is_x), nx, ny)
  end

fun run_rrcurveto {n:nat} .<n>. (
  rem: int(n), f: !Font, i: int, lim: int, x16: int, y16: int
): @(int, int) =
  if rem = 0 then @(x16, y16)
  else if igt(iadd(i, 6), lim) then @(x16, y16)
  else let
    val @(nx, ny) = emit_cubic(f, x16, y16,
      font_cff_stk_get(f, i), font_cff_stk_get(f, iadd(i, 1)),
      font_cff_stk_get(f, iadd(i, 2)), font_cff_stk_get(f, iadd(i, 3)),
      font_cff_stk_get(f, iadd(i, 4)), font_cff_stk_get(f, iadd(i, 5)))
  in
    run_rrcurveto(rem - 1, f, iadd(i, 6), lim, nx, ny)
  end

fun run_vvcurveto {n:nat} .<n>. (
  rem: int(n), f: !Font, i: int, sp: int, dx1_first: int, first: bool, x16: int, y16: int
): @(int, int) =
  if rem = 0 then @(x16, y16)
  else if igt(iadd(i, 4), sp) then @(x16, y16)
  else let
    val dx1 = if first then dx1_first else 0
    val @(nx, ny) = emit_cubic(f, x16, y16,
      dx1, font_cff_stk_get(f, i),
      font_cff_stk_get(f, iadd(i, 1)), font_cff_stk_get(f, iadd(i, 2)),
      0, font_cff_stk_get(f, iadd(i, 3)))
  in
    run_vvcurveto(rem - 1, f, iadd(i, 4), sp, 0, false, nx, ny)
  end

fun run_hhcurveto {n:nat} .<n>. (
  rem: int(n), f: !Font, i: int, sp: int, dy1_first: int, first: bool, x16: int, y16: int
): @(int, int) =
  if rem = 0 then @(x16, y16)
  else if igt(iadd(i, 4), sp) then @(x16, y16)
  else let
    val dy1 = if first then dy1_first else 0
    val @(nx, ny) = emit_cubic(f, x16, y16,
      font_cff_stk_get(f, i), dy1,
      font_cff_stk_get(f, iadd(i, 1)), font_cff_stk_get(f, iadd(i, 2)),
      font_cff_stk_get(f, iadd(i, 3)), 0)
  in
    run_hhcurveto(rem - 1, f, iadd(i, 4), sp, 0, false, nx, ny)
  end

fun emit_alt_cubic(f: !Font, vert: bool, x16: int, y16: int, a0: int, a1: int, a2: int, a3: int, extra: int): @(int, int) =
  if vert then emit_cubic(f, x16, y16, 0, a0, a1, a2, a3, extra)
  else emit_cubic(f, x16, y16, a0, 0, a1, a2, extra, a3)

fun run_alt_curveto {n:nat} .<n>. (
  rem: int(n), f: !Font, i: int, sp: int, vert: bool, x16: int, y16: int
): @(int, int) =
  if rem = 0 then @(x16, y16)
  else if igt(iadd(i, 4), sp) then @(x16, y16)
  else let
    val tail = isub(sp, i)
    val has_extra = ieq(tail, 5)
    val extra = if has_extra then font_cff_stk_get(f, iadd(i, 4)) else 0
    val @(nx, ny) = emit_alt_cubic(f, vert, x16, y16,
      font_cff_stk_get(f, i), font_cff_stk_get(f, iadd(i, 1)),
      font_cff_stk_get(f, iadd(i, 2)), font_cff_stk_get(f, iadd(i, 3)), extra)
    val step = if has_extra then 5 else 4
  in
    run_alt_curveto(rem - 1, f, iadd(i, step), sp, not(vert), nx, ny)
  end

fun run_rcurveline(f: !Font, v: CffVm): CffVm =
  if ilt(v.sp, 2) then vm_with_cursor(v, 0, iadd(v.pc, 1), v.x16, v.y16, v.cur_start, v.have_width)
  else let
    val clim = isub(v.sp, 2)
    val @(cx, cy) = run_rrcurveto(airlock_nat(imax(0, v.sp)), f, 0, clim, v.x16, v.y16)
    val @(nx, ny) = run_rlineto(1, f, clim, v.sp, cx, cy)
  in
    vm_with_cursor(v, 0, iadd(v.pc, 1), nx, ny, v.cur_start, v.have_width)
  end

fun run_rlinecurve(f: !Font, v: CffVm): CffVm =
  if ilt(v.sp, 6) then vm_with_cursor(v, 0, iadd(v.pc, 1), v.x16, v.y16, v.cur_start, v.have_width)
  else let
    val llim = isub(v.sp, 6)
    val @(lx, ly) = run_rlineto(airlock_nat(imax(0, v.sp)), f, 0, llim, v.x16, v.y16)
    val @(nx, ny) = run_rrcurveto(1, f, llim, v.sp, lx, ly)
  in
    vm_with_cursor(v, 0, iadd(v.pc, 1), nx, ny, v.cur_start, v.have_width)
  end

fun run_flex_pair(f: !Font, x16: int, y16: int,
  dx1: int, dy1: int, dx2: int, dy2: int, dx3: int, dy3: int,
  dx4: int, dy4: int, dx5: int, dy5: int, dx6: int, dy6: int): @(int, int) = let
  val @(mx, my) = emit_cubic(f, x16, y16, dx1, dy1, dx2, dy2, dx3, dy3)
in
  emit_cubic(f, mx, my, dx4, dy4, dx5, dy5, dx6, dy6)
end

fun sk(f: !Font, k: int): int = font_cff_stk_get(f, k)

fun run_flex1(f: !Font, v: CffVm): CffVm =
  if ilt(v.sp, 11) then vm_with_cursor(v, 0, iadd(v.pc, 2), v.x16, v.y16, v.cur_start, v.have_width)
  else let
    val sdx = iadd(iadd(sk(f, 0), sk(f, 2)), iadd(sk(f, 4), iadd(sk(f, 6), sk(f, 8))))
    val sdy = iadd(iadd(sk(f, 1), sk(f, 3)), iadd(sk(f, 5), iadd(sk(f, 7), sk(f, 9))))
    val d6 = sk(f, 10)
    val dx6 = if igt(abs(sdx), abs(sdy)) then d6 else isub(0, sdx)
    val dy6 = if igt(abs(sdx), abs(sdy)) then isub(0, sdy) else d6
    val @(nx, ny) = run_flex_pair(f, v.x16, v.y16,
      sk(f, 0), sk(f, 1), sk(f, 2), sk(f, 3), sk(f, 4), sk(f, 5), sk(f, 6), sk(f, 7), sk(f, 8), sk(f, 9), dx6, dy6)
  in
    vm_with_cursor(v, 0, iadd(v.pc, 2), nx, ny, v.cur_start, v.have_width)
  end

fun run_op2(f: !Font, v: CffVm): CffVm =
  if igt(iadd(v.pc, 2), v.len) then
    @{gid=v.gid, off=v.off, len=v.len, pc=v.len, sp=0, depth=v.depth,
      nstems=v.nstems, have_width=v.have_width, x16=v.x16, y16=v.y16, cur_start=v.cur_start, done=true}
  else let
    val op2 = file_u8(f, iadd(v.off, iadd(v.pc, 1)))
  in
    if ieq(op2, 35) andalso ige(v.sp, 12) then let
      val @(nx, ny) = run_flex_pair(f, v.x16, v.y16,
        sk(f, 0), sk(f, 1), sk(f, 2), sk(f, 3), sk(f, 4), sk(f, 5), sk(f, 6), sk(f, 7), sk(f, 8), sk(f, 9), sk(f, 10), sk(f, 11))
    in vm_with_cursor(v, 0, iadd(v.pc, 2), nx, ny, v.cur_start, v.have_width) end
    else if ieq(op2, 34) andalso ige(v.sp, 7) then let
      val @(nx, ny) = run_flex_pair(f, v.x16, v.y16,
        sk(f, 0), 0, sk(f, 1), sk(f, 2), sk(f, 3), 0, sk(f, 4), 0, sk(f, 5), isub(0, sk(f, 2)), sk(f, 6), 0)
    in vm_with_cursor(v, 0, iadd(v.pc, 2), nx, ny, v.cur_start, v.have_width) end
    else if ieq(op2, 36) andalso ige(v.sp, 9) then let
      val dy6 = isub(0, iadd(sk(f, 1), iadd(sk(f, 3), sk(f, 7))))
      val @(nx, ny) = run_flex_pair(f, v.x16, v.y16,
        sk(f, 0), sk(f, 1), sk(f, 2), sk(f, 3), sk(f, 4), 0, sk(f, 5), 0, sk(f, 6), sk(f, 7), sk(f, 8), dy6)
    in vm_with_cursor(v, 0, iadd(v.pc, 2), nx, ny, v.cur_start, v.have_width) end
    else if ieq(op2, 37) then run_flex1(f, v)
    else vm_with_cursor(v, 0, iadd(v.pc, 2), v.x16, v.y16, v.cur_start, v.have_width)
  end

fun lookup_subr_span(f: !Font, gid: int, is_global: bool, bidx: int): SfntOptional =
  if is_global then font_cff_gsubr_span(f, bidx) else font_cff_lsubr_span(f, gid, bidx)

fun vm_call_subr(f: !Font, v: CffVm, is_global: bool): CffVm =
  if ile(v.sp, 0) orelse ige(v.depth, 16) then
    vm_with_cursor(v, 0, iadd(v.pc, 1), v.x16, v.y16, v.cur_start, v.have_width)
  else let
    val nsp = isub(v.sp, 1)
    val raw = font_cff_stk_get(f, nsp)
    val idx = idiv(raw, WORD16_MODULUS)
    val cnt = if is_global then font_cff_gsubr_count(f) else font_cff_lsubr_count(f, v.gid)
    val bidx = iadd(idx, sfnt_cff_subr_bias(cnt))
  in case+ lookup_subr_span(f, v.gid, is_global, bidx) of
    | ~NoSfntTable() => vm_with_cursor(v, nsp, iadd(v.pc, 1), v.x16, v.y16, v.cur_start, v.have_width)
    | ~HasSfntTable(span) => let
        val () = font_cff_ret_set(f, v.depth, 0, v.off)
        val () = font_cff_ret_set(f, v.depth, 1, v.len)
        val () = font_cff_ret_set(f, v.depth, 2, iadd(v.pc, 1))
      in
        @{gid=v.gid, off=span.offset, len=span.length, pc=0, sp=nsp, depth=iadd(v.depth, 1),
          nstems=v.nstems, have_width=v.have_width, x16=v.x16, y16=v.y16, cur_start=v.cur_start, done=false}
      end
  end

fun vm_ret_subr(f: !Font, v: CffVm): CffVm =
  if ile(v.depth, 0) then let
    val cs = close_contour(f, v.cur_start)
  in
    @{gid=v.gid, off=v.off, len=v.len, pc=v.len, sp=0, depth=0,
      nstems=v.nstems, have_width=v.have_width, x16=v.x16, y16=v.y16, cur_start=cs, done=true}
  end else let
    val nd = isub(v.depth, 1)
    val roff = font_cff_ret_get(f, nd, 0)
    val rlen = font_cff_ret_get(f, nd, 1)
    val rpc = font_cff_ret_get(f, nd, 2)
  in
    @{gid=v.gid, off=roff, len=rlen, pc=rpc, sp=v.sp, depth=nd,
      nstems=v.nstems, have_width=v.have_width, x16=v.x16, y16=v.y16, cur_start=v.cur_start, done=false}
  end

fun vm_stems(v: CffVm, is_mask: bool): CffVm = let
  val nst = iadd(v.nstems, idiv(v.sp, 2))
  val mbytes = if is_mask then idiv(iadd(nst, 7), 8) else 0
  val npc = imin(v.len, iadd(iadd(v.pc, 1), mbytes))
in
  @{gid=v.gid, off=v.off, len=v.len, pc=npc, sp=0, depth=v.depth,
    nstems=nst, have_width=true, x16=v.x16, y16=v.y16, cur_start=v.cur_start, done=false}
end

fun vm_curve_or_line(f: !Font, v: CffVm, b0: int): CffVm =
  if ieq(b0, 5) then let
    val @(nx, ny) = run_rlineto(airlock_nat(imax(0, v.sp)), f, 0, v.sp, v.x16, v.y16)
  in vm_with_cursor(v, 0, iadd(v.pc, 1), nx, ny, v.cur_start, v.have_width) end
  else if ieq(b0, 6) then let
    val @(nx, ny) = run_alt_lineto(airlock_nat(imax(0, v.sp)), f, 0, v.sp, true, v.x16, v.y16)
  in vm_with_cursor(v, 0, iadd(v.pc, 1), nx, ny, v.cur_start, v.have_width) end
  else if ieq(b0, 7) then let
    val @(nx, ny) = run_alt_lineto(airlock_nat(imax(0, v.sp)), f, 0, v.sp, false, v.x16, v.y16)
  in vm_with_cursor(v, 0, iadd(v.pc, 1), nx, ny, v.cur_start, v.have_width) end
  else if ieq(b0, 8) then let
    val @(nx, ny) = run_rrcurveto(airlock_nat(imax(0, v.sp)), f, 0, v.sp, v.x16, v.y16)
  in vm_with_cursor(v, 0, iadd(v.pc, 1), nx, ny, v.cur_start, v.have_width) end
  else if ieq(b0, 24) then run_rcurveline(f, v)
  else if ieq(b0, 25) then run_rlinecurve(f, v)
  else if ieq(b0, 26) then let
    val odd = ieq(imod(v.sp, 4), 1)
    val start_i = if odd then 1 else 0
    val dx1 = if odd then font_cff_stk_get(f, 0) else 0
    val @(nx, ny) = run_vvcurveto(airlock_nat(imax(0, v.sp)), f, start_i, v.sp, dx1, true, v.x16, v.y16)
  in vm_with_cursor(v, 0, iadd(v.pc, 1), nx, ny, v.cur_start, v.have_width) end
  else if ieq(b0, 27) then let
    val odd = ieq(imod(v.sp, 4), 1)
    val start_i = if odd then 1 else 0
    val dy1 = if odd then font_cff_stk_get(f, 0) else 0
    val @(nx, ny) = run_hhcurveto(airlock_nat(imax(0, v.sp)), f, start_i, v.sp, dy1, true, v.x16, v.y16)
  in vm_with_cursor(v, 0, iadd(v.pc, 1), nx, ny, v.cur_start, v.have_width) end
  else if ieq(b0, 30) orelse ieq(b0, 31) then let
    val @(nx, ny) = run_alt_curveto(airlock_nat(imax(0, v.sp)), f, 0, v.sp, ieq(b0, 30), v.x16, v.y16)
  in vm_with_cursor(v, 0, iadd(v.pc, 1), nx, ny, v.cur_start, v.have_width) end
  else vm_with_cursor(v, 0, iadd(v.pc, 1), v.x16, v.y16, v.cur_start, v.have_width)

fun vm_step_op(f: !Font, v: CffVm, b0: int): CffVm =
  if ieq(b0, 1) orelse ieq(b0, 3) orelse ieq(b0, 18) orelse ieq(b0, 23) then vm_stems(v, false)
  else if ieq(b0, 19) orelse ieq(b0, 20) then vm_stems(v, true)
  else if ieq(b0, 10) then vm_call_subr(f, v, false)
  else if ieq(b0, 29) then vm_call_subr(f, v, true)
  else if ieq(b0, 11) then vm_ret_subr(f, v)
  else if ieq(b0, 12) then run_op2(f, v)
  else if ieq(b0, 14) then let val cs = close_contour(f, v.cur_start) in
    @{gid=v.gid, off=v.off, len=v.len, pc=v.len, sp=0, depth=0,
      nstems=v.nstems, have_width=true, x16=v.x16, y16=v.y16, cur_start=cs, done=true} end
  else if ieq(b0, 21) then (
    if ilt(v.sp, 2) then vm_with_cursor(v, 0, iadd(v.pc, 1), v.x16, v.y16, v.cur_start, true)
    else let val b = if not(v.have_width) andalso igt(v.sp, 2) then 1 else 0
    in cff_moveto(f, v, font_cff_stk_get(f, b), font_cff_stk_get(f, iadd(b, 1))) end
  ) else if ieq(b0, 22) then (
    if ilt(v.sp, 1) then vm_with_cursor(v, 0, iadd(v.pc, 1), v.x16, v.y16, v.cur_start, true)
    else let val b = if not(v.have_width) andalso igt(v.sp, 1) then 1 else 0
    in cff_moveto(f, v, font_cff_stk_get(f, b), 0) end
  ) else if ieq(b0, 4) then (
    if ilt(v.sp, 1) then vm_with_cursor(v, 0, iadd(v.pc, 1), v.x16, v.y16, v.cur_start, true)
    else let val b = if not(v.have_width) andalso igt(v.sp, 1) then 1 else 0
    in cff_moveto(f, v, 0, font_cff_stk_get(f, b)) end
  ) else vm_curve_or_line(f, v, b0)

fun vm_step_byte(f: !Font, v: CffVm): CffVm = let
  val at = iadd(v.off, v.pc)
  val b0 = file_u8(f, at)
in
  if ieq(b0, 28) then (
    if igt(iadd(v.pc, 3), v.len) then vm_ret_subr(f, v)
    else vm_push_op(f, v, fx_of_int(file_i16(f, iadd(at, 1))), iadd(v.pc, 3))
  ) else if ieq(b0, 255) then (
    if igt(iadd(v.pc, 5), v.len) then vm_ret_subr(f, v)
    else vm_push_op(f, v, font_cff_i32(f, iadd(at, 1)), iadd(v.pc, 5))
  ) else if ige(b0, 32) andalso ile(b0, 246) then
    vm_push_op(f, v, fx_of_int(isub(b0, 139)), iadd(v.pc, 1))
  else if ige(b0, 247) andalso ile(b0, 250) then (
    if igt(iadd(v.pc, 2), v.len) then vm_ret_subr(f, v)
    else let val num = iadd(iadd(imul(isub(b0, 247), 256), file_u8(f, iadd(at, 1))), 108)
    in vm_push_op(f, v, fx_of_int(num), iadd(v.pc, 2)) end
  ) else if ige(b0, 251) andalso ile(b0, 254) then (
    if igt(iadd(v.pc, 2), v.len) then vm_ret_subr(f, v)
    else let val num = isub(isub(0, iadd(imul(isub(b0, 251), 256), file_u8(f, iadd(at, 1)))), 108)
    in vm_push_op(f, v, fx_of_int(num), iadd(v.pc, 2)) end
  ) else vm_step_op(f, v, b0)
end

extern fun cff_vm_fuel_exhausted(): void = "mac#anth_die_void"

fun cff_vm_run {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, v: CffVm
): void =
  if recursion_fuel_available(recfuel) then (
    if v.done then ()
    else if ige(v.pc, v.len) then cff_vm_run(recfuel - 1, f, vm_ret_subr(f, v))
    else cff_vm_run(recfuel - 1, f, vm_step_byte(f, v))
  ) else cff_vm_fuel_exhausted()

implement load_cff_outline(f, gid) = let
  val () = font_set_point_count(f, 0)
  val () = font_set_contour_count(f, 0)
  val () = font_set_edge_count(f, 0)
in
  case+ font_cff_glyph_span(f, gid) of
  | ~NoSfntTable() => ()
  | ~HasSfntTable(span) => let
      val v0: CffVm = @{
        gid=gid, off=span.offset, len=span.length, pc=0,
        sp=0, depth=0, nstems=0, have_width=false,
        x16=0, y16=0, cur_start= ~1, done=false
      }
    in
      cff_vm_run(airlock_nat(MAX_REC_FUEL), f, v0)
    end
end
