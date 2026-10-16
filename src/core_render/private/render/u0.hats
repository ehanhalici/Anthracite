fun u0(): uint = u_zero()

fun putf(b: !Buf, i: int, v: float): void =
  buf_set_f32(b, i, v)

fun gl_batch_bind(vao: uint, vbo: uint, nbytes: int): void = let
  val () = glBindVertexArray(vao)
  val () = glBindBuffer(GL_ARRAY_BUFFER, vbo)
  val () = glBufferData(GL_ARRAY_BUFFER, anth_i2lint(nbytes), the_null_ptr, GL_DYNAMIC_DRAW)
  val () = glEnableVertexAttribArray(u_of(RENDER_POSITION_ATTRIBUTE))
  val () = glEnableVertexAttribArray(u_of(RENDER_COLOR_ATTRIBUTE))
  val () = glEnableVertexAttribArray(u_of(RENDER_TEXTURE_ATTRIBUTE))
  val () = gl_attrib(u_of(RENDER_POSITION_ATTRIBUTE), RENDER_POSITION_COMPONENTS, RENDER_VERTEX_BYTES, RENDER_POSITION_OFFSET_BYTES)
  val () = gl_attrib(u_of(RENDER_COLOR_ATTRIBUTE), RENDER_COLOR_COMPONENTS, RENDER_VERTEX_BYTES, RENDER_COLOR_OFFSET_BYTES)
  val () = gl_attrib(u_of(RENDER_TEXTURE_ATTRIBUTE), RENDER_TEXTURE_COMPONENTS, RENDER_VERTEX_BYTES, RENDER_TEXTURE_OFFSET_BYTES)
in
end

fun gl_init_state(prog: uint): void = let
  val () = glEnable(GL_BLEND)
  val () = glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  val () = glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
  val () = glUseProgram(prog)
  val () = glUniform1i(gl_uloc(prog, "u_tex"), 0)
in
end

fun make_rend(prog: uint, blur_prog: uint, vao: uint, vbo: uint, nbytes: int): Rend =
  REND(@{
    prog= prog, blur_prog= blur_prog, blur_tex= u0(), vao= vao, vbo= vbo
  , loc_view= gl_uloc(prog, "u_view")
  , loc_mode= gl_uloc(prog, "u_mode")
  , loc_tex= gl_uloc(prog, "u_tex")
  , blur_loc_view= gl_uloc(blur_prog, "u_view")
  , blur_loc_tex= gl_uloc(blur_prog, "u_tex")
  , blur_loc_pixel= gl_uloc(blur_prog, "u_pixel")
  , batch= buf_make(nbytes)
  , nvert= 0, mode= ShadeNone, tex= u0(), vw= 1, vh= 1, blur_w= 0, blur_h= 0
  })

implement rend_open() = let
  val prog = gl_program()
  val blur_prog = gl_blur_program()
  var vao: uint = u0()
  var vbo: uint = u0()
  val () = glGenVertexArrays(1, vao)
  val () = glGenBuffers(1, vbo)
  val nbytes = RENDER_BATCH_MAX_VERTICES * RENDER_VERTEX_BYTES
  val () = gl_batch_bind(vao, vbo, nbytes)
  val () = gl_init_state(prog)
in
  make_rend(prog, blur_prog, vao, vbo, nbytes)
end

implement rend_close(r) = let
  val+~REND(s) = r
  val () = glDeleteProgram(s.prog)
  val () = glDeleteProgram(s.blur_prog)
  var blur_tex: uint = s.blur_tex
  val () = if blur_tex <> u0() then glDeleteTextures(1, blur_tex) else ()
  var vao: uint = s.vao
  var vbo: uint = s.vbo
  val () = glDeleteVertexArrays(1, vao)
  val () = glDeleteBuffers(1, vbo)
in
  buf_free(s.batch)
end

fun shade_code(m: Shade): int = case+ m of
  | ShadeNone() => ~1
  | ShadeSolid() => 0
  | ShadeAlpha() => 1
  | ShadeRgba() => 2

fun is_shade(a: Shade, b: Shade): bool = shade_code(a) = shade_code(b)

fun gl_airlock_upload_batch(vao: uint, vbo: uint, batch: !Buf, nvert: int): void = let
  val () = glBindVertexArray(vao)
  val () = glBindBuffer(GL_ARRAY_BUFFER, vbo)
in
  glBufferSubData(GL_ARRAY_BUFFER, anth_i2lint(0),
    anth_i2lint(nvert * RENDER_VERTEX_BYTES), buf_ptr(batch))
end

implement rend_flush(r) =
  case+ r of
  | @REND(s) => let
      val n = s.nvert
      val () =
        if n > 0 then let
          val () = gl_airlock_upload_batch(s.vao, s.vbo, s.batch, n)
          val () = glUniform1i(s.loc_mode, shade_code(s.mode))
          val () = glActiveTexture(GL_TEXTURE0)
          val () = glBindTexture(GL_TEXTURE_2D, s.tex)
          val () = glDrawArrays(GL_TRIANGLES, 0, n)
        in
          s.nvert := 0
        end else ()
    in
      fold@(r)
    end

fun bind_mode(r: !Rend, mode: Shade, tex: uint): void =
  case+ r of
  | @REND(s) => let
      val changed = not(is_shade(s.mode, mode)) orelse s.tex <> tex
    in
      fold@(r);
      if changed then let
        val () = rend_flush(r)
      in
        case+ r of
        | @REND(s2) => let
            val () = s2.mode := mode
            val () = s2.tex := tex
          in
            fold@(r)
          end
      end else ()
    end

fun put_vertex(b: !Buf, base: int, x: float, y: float, cr: float, cg: float, cb: float, ca: float, u: float, v: float): void = let
  val () = putf(b, base + 0, x)
  val () = putf(b, base + 1, y)
  val () = putf(b, base + 2, cr)
  val () = putf(b, base + 3, cg)
  val () = putf(b, base + 4, cb)
  val () = putf(b, base + 5, ca)
  val () = putf(b, base + 6, u)
  val () = putf(b, base + 7, v)
in
end

extern fun push_fuel_exhausted(r: !Rend, x: float, y: float, cr: float, cg: float, cb: float, ca: float, u: float, v: float): void = "mac#anth_die_void"

fun push_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), r: !Rend, x: float, y: float, cr: float, cg: float, cb: float, ca: float, u: float, v: float): void =
  if recfuel > 0 then (
    case+ r of
    | @REND(s) => let
        val n = s.nvert
      in
        if n >= RENDER_BATCH_MAX_VERTICES - 1 then let
          val () = fold@(r)
          val () = rend_flush(r)
        in
          push_with_fuel(recfuel - 1, r, x, y, cr, cg, cb, ca, u, v)
        end else let
          val base = n * 8
          val () = put_vertex(s.batch, base, x, y, cr, cg, cb, ca, u, v)
          val () = s.nvert := n + 1
        in
          fold@(r)
        end
      end
  ) else push_fuel_exhausted(r, x, y, cr, cg, cb, ca, u, v)

fun push(r: !Rend, x: float, y: float, cr: float, cg: float, cb: float, ca: float, u: float, v: float): void = push_with_fuel(airlock_nat(MAX_REC_FUEL), r, x, y, cr, cg, cb, ca, u, v)

fun i2f(i: int): float = anth_d2f(n_i2d(i))

implement rend_begin(r, w, h) =
  case+ r of
  | @REND(s) => let
      val () = s.vw := (if w > 0 then w else 1)
      val () = s.vh := (if h > 0 then h else 1)
      val () = s.nvert := 0
      val () = s.mode := ShadeNone
      val () = glViewport(0, 0, s.vw, s.vh)
      val () = glDisable(GL_SCISSOR_TEST)
      val () = glClearColor(gl_rf(col_bg()), gl_gf(col_bg()), gl_bf(col_bg()), gl_af(col_bg()))
      val () = glClear(GL_COLOR_BUFFER_BIT)
      val () = glUseProgram(s.prog)
      val () = glUniform2f(s.loc_view, i2f(s.vw), i2f(s.vh))
      val () = glUniform1i(s.loc_tex, 0)
    in
      fold@(r)
    end

implement rend_rect(r, x, y, w, h, c) = let
  val () = bind_mode(r, ShadeSolid, u0())
  val x0 = i2f(x)
  val y0 = i2f(y)
  val x1 = i2f(x + w)
  val y1 = i2f(y + h)
  val cr = gl_rf(c)
  val cg = gl_gf(c)
  val cb = gl_bf(c)
  val ca = gl_af(c)
  val z = i2f(0)
  val () = push(r, x0, y0, cr, cg, cb, ca, z, z)
  val () = push(r, x1, y0, cr, cg, cb, ca, z, z)
  val () = push(r, x1, y1, cr, cg, cb, ca, z, z)
  val () = push(r, x0, y0, cr, cg, cb, ca, z, z)
  val () = push(r, x1, y1, cr, cg, cb, ca, z, z)
  val () = push(r, x0, y1, cr, cg, cb, ca, z, z)
in
end

fun push_quad(r: !Rend, x0: float, y0: float, x1: float, y1: float, cr: float, cg: float, cb: float, ca: float, uu0: float, vv0: float, uu1: float, vv1: float): void = let
  val () = push(r, x0, y0, cr, cg, cb, ca, uu0, vv0)
  val () = push(r, x1, y0, cr, cg, cb, ca, uu1, vv0)
  val () = push(r, x1, y1, cr, cg, cb, ca, uu1, vv1)
  val () = push(r, x0, y0, cr, cg, cb, ca, uu0, vv0)
  val () = push(r, x1, y1, cr, cg, cb, ca, uu1, vv1)
  val () = push(r, x0, y1, cr, cg, cb, ca, uu0, vv1)
in
end

