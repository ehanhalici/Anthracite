implement rend_quad_pixels(r, tex, mode, x, y, w, h, u0d, v0d, u1d, v1d, c) = let
  val () = performance_note(PERF_GL_QUADS, 1)
  val () = bind_mode(r, mode, tex)
  val x0 = anth_d2f(x)
  val y0 = anth_d2f(y)
  val x1 = anth_d2f(x + w)
  val y1 = anth_d2f(y + h)
  val cr = gl_rf(c)
  val cg = gl_gf(c)
  val cb = gl_bf(c)
  val ca = gl_af(c)
  val uu0 = anth_d2f(u0d)
  val vv0 = anth_d2f(v0d)
  val uu1 = anth_d2f(u1d)
  val vv1 = anth_d2f(v1d)
  val () = push_quad(r, x0, y0, x1, y1, cr, cg, cb, ca, uu0, vv0, uu1, vv1)
in
end

implement rend_quad(r,tex,mode,x,y,w,h,u0d,v0d,u1d,v1d,c) =
  rend_quad_pixels(r,tex,mode,n_i2d(x),n_i2d(y),n_i2d(w),n_i2d(h),u0d,v0d,u1d,v1d,c)

fun blur_texture_params(): void = let
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
in
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
end

fun blur_texture_prepare(r: !Rend): void =
  case+ r of
  | @REND(s) => let
      var tex: uint = s.blur_tex
      val fresh = tex = u0()
      val resized = s.blur_w <> s.vw orelse s.blur_h <> s.vh
      val () = if fresh then glGenTextures(1, tex) else ()
      val () = glBindTexture(GL_TEXTURE_2D, tex)
      val () = if fresh orelse resized then
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, s.vw, s.vh, 0, GL_RGBA, GL_UNSIGNED_BYTE, the_null_ptr)
        else ()
      val () = blur_texture_params()
      val () = s.blur_tex := tex
      val () = s.blur_w := s.vw
      val () = s.blur_h := s.vh
    in
      fold@(r)
    end

fun blur_capture_pixels(r: !Rend): void =
  case+ r of
  | @REND(s) => let
      val () = glBindTexture(GL_TEXTURE_2D, s.blur_tex)
      val () = glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, s.vw, s.vh)
    in
      fold@(r)
    end

implement rend_capture(r) = let
  val () = rend_flush(r)
  val () = blur_texture_prepare(r)
in
  blur_capture_pixels(r)
end

fun blur_info(r: !Rend, tex: &uint >> _, vw: &int >> _, vh: &int >> _): void =
  case+ r of
  | @REND(s) => let
      val () = tex := s.blur_tex
      val () = vw := s.vw
      val () = vh := s.vh
    in
      fold@(r)
    end

fun blur_upload(r: !Rend): void =
  case+ r of
  | @REND(s) => let
      val () = gl_airlock_upload_batch(s.vao, s.vbo, s.batch, s.nvert)
    in
      fold@(r)
    end

fun blur_draw(r: !Rend, radius: int): void =
  case+ r of
  | @REND(s) => let
      val () = glUseProgram(s.blur_prog)
      val () = glUniform2f(s.blur_loc_view, i2f(s.vw), i2f(s.vh))
      val () = glUniform1i(s.blur_loc_tex, 0)
      val () = glUniform2f(s.blur_loc_pixel,
        i2f(radius) / i2f(s.vw), i2f(radius) / i2f(s.vh))
      val () = glActiveTexture(GL_TEXTURE0)
      val () = glBindTexture(GL_TEXTURE_2D, s.blur_tex)
      val () = glDrawArrays(GL_TRIANGLES, 0, s.nvert)
    in
      fold@(r)
    end

fun blur_restore(r: !Rend): void =
  case+ r of
  | @REND(s) => let
      val () = s.nvert := 0
      val () = s.mode := ShadeNone
      val () = s.tex := u0()
      val () = glUseProgram(s.prog)
      val () = glUniform2f(s.loc_view, i2f(s.vw), i2f(s.vh))
      val () = glUniform1i(s.loc_tex, 0)
    in
      fold@(r)
    end

fun ratio(n: int, d: int): double =
  if d <= 0 then 0.0 else n_i2d(n) / n_i2d(d)

implement rend_blur_rect(r, x, y, w, h, radius) =
  if w <= 0 orelse h <= 0 orelse radius <= 0 then ()
  else let
    var tex: uint = u0()
    var vw: int = 1
    var vh: int = 1
    val () = blur_info(r, tex, vw, vh)
    val vtop = ratio(vh - y, vh)
    val vbottom = ratio(vh - (y + h), vh)
    val () = rend_quad(r, tex, ShadeRgba, x, y, w, h,
      ratio(x, vw), vtop, ratio(x + w, vw), vbottom, col_white())
    val () = blur_upload(r)
    val () = blur_draw(r, radius)
  in
    blur_restore(r)
  end

fun rect_push_quad(
  r: !Rend, x: int, y: int, w: int, h: int, pad: int, c_top: uint, c_bot: uint
): void = let
  val x0 = i2f(x - pad); val y0 = i2f(y - pad)
  val x1 = i2f(x + w + pad); val y1 = i2f(y + h + pad)
  val u0 = i2f(~pad); val v0 = i2f(~pad)
  val u1 = i2f(w + pad); val v1 = i2f(h + pad)
  val rt = gl_rf(c_top); val gt = gl_gf(c_top); val bt = gl_bf(c_top); val at = gl_af(c_top)
  val rb = gl_rf(c_bot); val gb = gl_gf(c_bot); val bb = gl_bf(c_bot); val ab = gl_af(c_bot)
  val () = push(r, x0, y0, rt, gt, bt, at, u0, v0)
  val () = push(r, x1, y0, rt, gt, bt, at, u1, v0)
  val () = push(r, x1, y1, rb, gb, bb, ab, u1, v1)
  val () = push(r, x0, y0, rt, gt, bt, at, u0, v0)
  val () = push(r, x1, y1, rb, gb, bb, ab, u1, v1)
  val () = push(r, x0, y1, rb, gb, bb, ab, u0, v1)
in
end

fun rect_draw(
  r: !Rend, w: int, h: int, rtl: int, rtr: int, rbr: int, rbl: int,
  bth: int, bcol: uint, softness: int
): void =
  case+ r of
  | @REND(s) => let
      val () = glUseProgram(s.rect_prog)
      val () = glUniform2f(s.rect_loc_view, i2f(s.vw), i2f(s.vh))
      val () = glUniform2f(s.rect_loc_size, i2f(w), i2f(h))
      val () = glUniform4f(s.rect_loc_radii, i2f(rtl), i2f(rtr), i2f(rbr), i2f(rbl))
      val () = glUniform4f(s.rect_loc_border, gl_rf(bcol), gl_gf(bcol), gl_bf(bcol), gl_af(bcol))
      val () = glUniform4f(s.rect_loc_params, i2f(bth), i2f(softness), i2f(0), i2f(0))
      val () = glDrawArrays(GL_TRIANGLES, 0, s.nvert)
    in
      fold@(r)
    end

implement rend_rrect_ex(r, x, y, w, h, rtl, rtr, rbr, rbl, c_top, c_bot, bth, bcol, softness) =
  if w <= 0 orelse h <= 0 then ()
  else let
    val () = performance_note(PERF_GL_QUADS, 1)
    val () = rend_flush(r)
    val pad = if softness > 1 then softness else 0
    val () = rect_push_quad(r, x, y, w, h, pad, c_top, c_bot)
    val () = blur_upload(r)
    val () = rect_draw(r, w, h, rtl, rtr, rbr, rbl, bth, bcol, softness)
  in
    blur_restore(r)
  end

implement rend_rrect(r, x, y, w, h, rad, c) =
  rend_rrect_ex(r, x, y, w, h, rad, rad, rad, rad, c, c, 0, col_clear(), 1)

implement rend_scissor(r, x, y, w, h) = let
  val () = rend_flush(r)
in
  case+ r of
  | @REND(s) => let
      val gy = s.vh - (y + h)
      val () = glEnable(GL_SCISSOR_TEST)
      val () = glScissor(x, gy, w, h)
    in
      fold@(r)
    end
end

implement rend_scissor_off(r) = let
  val () = rend_flush(r)
  val () = glDisable(GL_SCISSOR_TEST)
in
end

fun tex_params(): void = let
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
  val () = glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
in
end

implement rend_tex_r8(r, tex0, w, h) = let
  var tex: uint = tex0
  val () = if tex0 = u0() then glGenTextures(1, tex) else ()
  val () = glBindTexture(GL_TEXTURE_2D, tex)
  val () = glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, w, h, 0, GL_RED, GL_UNSIGNED_BYTE, the_null_ptr)
  val () = tex_params()
  val () = rend_flush(r)
in
  tex
end

implement rend_tex_sub_r8(r, tex, x, y, w, h, pixels) = let
  val () = rend_flush(r)
  val () = glBindTexture(GL_TEXTURE_2D, tex)
  val () = glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, w, h, GL_RED, GL_UNSIGNED_BYTE, pixels)
in
end

implement rend_tex_sub_buf(r, tex, x, y, w, h, pixels, off) =
  rend_tex_sub_r8(r, tex, x, y, w, h, mem_ptr_at(buf_ptr(pixels), buf_cap(pixels), off))

implement rend_tex_rgba(r, w, h, pixels) = let
  var tex: uint = u0()
  val () = rend_flush(r)
  val () = glGenTextures(1, tex)
  val () = glBindTexture(GL_TEXTURE_2D, tex)
  val () = glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels)
  val () = tex_params()
in
  tex
end

implement rend_tex_buf(r, w, h, pixels) =
  rend_tex_rgba(r, w, h, buf_ptr(pixels))

implement rend_tex_free(tex) = let
  var t: uint = tex
  val () = if tex <> u0() then glDeleteTextures(1, t) else ()
in
end
