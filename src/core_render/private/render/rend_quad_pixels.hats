implement rend_quad_pixels(r, tex, mode, x, y, w, h, u0d, v0d, u1d, v1d, c) = let
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
