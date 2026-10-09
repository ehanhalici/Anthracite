#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "core_render/gl.sats"
staload "core_render/render.sats"

#define MAXV 4096

datavtype Rend_ = REND of @{
  prog= uint
, vao= uint
, vbo= uint
, loc_view= int
, loc_mode= int
, loc_tex= int
, batch= Buf
, nvert= int
, mode= Shade
, tex= uint
, vw= int
, vh= int
}
(* skill.md 1. kural istisnasi: ATS2 soyut tip gerceklemesi (sats'taki absviewtype). Kanit disi cast veya ham C yoktur. *)
assume Rend = Rend_

fun u0(): uint = u_zero()

fun putf(b: !Buf, i: int, v: float): void =
  buf_set_f32(b, i, v)

fun gl_batch_bind(vao: uint, vbo: uint, nbytes: int): void = let
  val () = glBindVertexArray(vao)
  val () = glBindBuffer(GL_ARRAY_BUFFER, vbo)
  val () = glBufferData(GL_ARRAY_BUFFER, anth_i2lint(nbytes), the_null_ptr, GL_DYNAMIC_DRAW)
  val () = glEnableVertexAttribArray(u_of(0))
  val () = glEnableVertexAttribArray(u_of(1))
  val () = glEnableVertexAttribArray(u_of(2))
  val () = gl_attrib(u_of(0), 2, 32, 0)
  val () = gl_attrib(u_of(1), 4, 32, 8)
  val () = gl_attrib(u_of(2), 2, 32, 24)
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

implement rend_open() = let
  val prog = gl_program()
  var vao: uint = u0()
  var vbo: uint = u0()
  val () = glGenVertexArrays(1, vao)
  val () = glGenBuffers(1, vbo)
  val nbytes = MAXV * 8 * 4
  val () = gl_batch_bind(vao, vbo, nbytes)
  val () = gl_init_state(prog)
in
  REND(@{
    prog= prog, vao= vao, vbo= vbo
  , loc_view= gl_uloc(prog, "u_view")
  , loc_mode= gl_uloc(prog, "u_mode")
  , loc_tex= gl_uloc(prog, "u_tex")
  , batch= buf_make(nbytes)
  , nvert= 0, mode= ShadeNone, tex= u0(), vw= 1, vh= 1
  })
end

implement rend_close(r) = let
  val+~REND(s) = r
  val () = glDeleteProgram(s.prog)
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

implement rend_flush(r) =
  case+ r of
  | @REND(s) => let
      val n = s.nvert
      val () =
        if n > 0 then let
          val () = glBindVertexArray(s.vao)
          val () = glBindBuffer(GL_ARRAY_BUFFER, s.vbo)
          val () = glBufferSubData(GL_ARRAY_BUFFER, anth_i2lint(0), anth_i2lint(n * 32), buf_ptr(s.batch))
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
      val changed: int = (if not(is_shade(s.mode, mode)) orelse s.tex <> tex then 1 else 0): int
    in
      fold@(r);
      if changed <> 0 then let
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

extern fun push_exh(r: !Rend, x: float, y: float, cr: float, cg: float, cb: float, ca: float, u: float, v: float): void = "mac#anth_die_void"

fun push_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), r: !Rend, x: float, y: float, cr: float, cg: float, cb: float, ca: float, u: float, v: float): void =
  if recfuel > 0 then (
    case+ r of
    | @REND(s) => let
        val n = s.nvert
      in
        if n >= MAXV - 1 then let
          val () = fold@(r)
          val () = rend_flush(r)
        in
          push_m(recfuel - 1, r, x, y, cr, cg, cb, ca, u, v)
        end else let
          val base = n * 8
          val () = put_vertex(s.batch, base, x, y, cr, cg, cb, ca, u, v)
          val () = s.nvert := n + 1
        in
          fold@(r)
        end
      end
  ) else push_exh(r, x, y, cr, cg, cb, ca, u, v)

fun push(r: !Rend, x: float, y: float, cr: float, cg: float, cb: float, ca: float, u: float, v: float): void = push_m(airlock_nat(MAX_REC_FUEL), r, x, y, cr, cg, cb, ca, u, v)

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

implement rend_quad(r, tex, mode, x, y, w, h, u0d, v0d, u1d, v1d, c) = let
  val () = bind_mode(r, mode, tex)
  val x0 = i2f(x)
  val y0 = i2f(y)
  val x1 = i2f(x + w)
  val y1 = i2f(y + h)
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
