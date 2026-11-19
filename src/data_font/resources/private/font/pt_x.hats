implement pt_x(f, i) =
  case+ f of
  | @FONT(s) => let
      val v = buf_get32(s.xs, i)
    in
      fold@(f); v
    end

implement pt_y(f, i) =
  case+ f of
  | @FONT(s) => let
      val v = buf_get32(s.ys, i)
    in
      fold@(f); v
    end

implement pt_on(f, i) =
  case+ f of
  | @FONT(s) => let
      val v = buf_get(s.fl, i)
    in
      fold@(f); v
    end

implement end_set(f, i, v) =
  case+ f of
  | @FONT(s) => let
      val () = buf_set32(s.ends, i, v)
    in
      fold@(f)
    end

implement end_get(f, i) =
  case+ f of
  | @FONT(s) => let
      val v = buf_get32(s.ends, i)
    in
      fold@(f); v
    end

fun edge_store(f: !Font, n: int, x0: int, y0: int, x1: int, y1: int): void =
  case+ f of
  | @FONT(s) => let
      val b = n * 4
      val () = buf_set32(s.edges, b, x0)
      val () = buf_set32(s.edges, b + 1, y0)
      val () = buf_set32(s.edges, b + 2, x1)
      val () = buf_set32(s.edges, b + 3, y1)
      val () = s.nedges := n + 1
    in
      fold@(f)
    end

implement edge_push(f, x0, y0, x1, y1) =
  if x0 = x1 andalso y0 = y1 then ()
  else let
    val n = font_get_edge_count(f)
  in
    if n >= FONT_MAX_EDGES then ()
    else edge_store(f, n, x0, y0, x1, y1)
  end

implement edge_get(f, e, k) =
  case+ f of
  | @FONT(s) => let
      val v = buf_get32(s.edges, e * 4 + k)
    in
      fold@(f); v
    end

implement set_x(f, i, x) =
  case+ f of
  | @FONT(s) => let
      val () = buf_set32(s.xs, i, x)
    in
      fold@(f)
    end


implement set_fl(f, i, v) =
  case+ f of
  | @FONT(s) => let
      val () = buf_set(s.fl, i, v)
    in
      fold@(f)
    end

implement component_at(f, span, p) = case+ f of
  | @FONT(s) => let
      val result = glyph_component_read(s.file,span,p,s.nglyph)
    in fold@(f); result end

implement zero_cov(f) =
  case+ f of
  | @FONT(s) => let
      val () = buf_zero(s.cov)
    in
      fold@(f)
    end

implement cov_set(f, i, v) =
  case+ f of
  | @FONT(s) => let
      val () = if i >= 0 then buf_set(s.cov, i, v) else ()
    in
      fold@(f)
    end

implement cov_get(f, i) =
  case+ f of
  | @FONT(s) => let
      val v = if i >= 0 then buf_get(s.cov, i) else 0
    in
      fold@(f); v
    end

implement atlas_set(f, x, y, v) =
  case+ f of
  | @FONT(s) => let
      val () = if x >= 0 andalso y >= 0 andalso x < s.aw andalso y < s.ah then buf_set(s.atlas, y * s.aw + x, v) else ()
    in
      fold@(f)
    end

implement atlas_get(f, x, y) =
  case+ f of
  | @FONT(s) => let
      val v = if x >= 0 andalso y >= 0 andalso x < s.aw andalso y < s.ah then buf_get(s.atlas, y * s.aw + x) else 0
    in
      fold@(f); v
    end

implement cache_i(f, slot, k) =
  case+ f of
  | @FONT(s) => let
      val v = buf_get32(s.cache, slot * 12 + k)
    in
      fold@(f); v
    end

implement cache_s(f, slot, k, v) =
  case+ f of
  | @FONT(s) => let
      val () = buf_set32(s.cache, slot * 12 + k, v)
    in
      fold@(f)
    end

implement ensure_tex(f, r) =
  case+ f of
  | @FONT(s) => let
      val t0 = s.tex
      val fresh = (t0 = ztex())
      val t = if fresh then rend_tex_r8(r, t0, s.aw, s.ah) else t0
      val () = if fresh then (
        performance_note(PERF_FONT_ATLAS_UPLOADS, 1);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, s.aw);
        rend_tex_sub_buf(r, t, 0, 0, s.aw, s.ah, s.atlas, 0);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, 0)
      ) else ()
      val () = s.tex := t
    in
      fold@(f)
    end

implement upload_atlas(f, r, tex, x, y, w, h) =
  case+ f of
  | @FONT(s) => let
      val () = performance_note(PERF_FONT_ATLAS_UPLOADS, 1)
      val () = glPixelStorei(GL_UNPACK_ROW_LENGTH, s.aw)
      val () = rend_tex_sub_buf(r, tex, x, y, w, h, s.atlas, y * s.aw + x)
      val () = glPixelStorei(GL_UNPACK_ROW_LENGTH, 0)
    in
      fold@(f)
    end

implement kern_fmt0_value(f, p, left, right) = let
  val np = file_u16(f, iadd(p, 6))
in
  case+ f of
  | @FONT(s) => let
      val k = kern_search(s.file, iadd(p, 14), np, left, right, 0, np)
    in
      fold@(f); k
    end
end

#include "data_font/native/ownership/private/font_native_binding_impl.hats"
staload "data_font/resources/font_document_metrics.sats"
#include "data_font/resources/private/font_document_metrics_impl.hats"
#include "data_font/native/ownership/private/font_native_shape_impl.hats"
#include "data_font/native/ownership/private/font_native_coverage_impl.hats"
#include "data_font/text/private/font_text_owner_impl.hats"

implement font_outline_is_cff(f) = case+ f of
  | @FONT(s) => let
      val is_cff = if s.info.present then (case+ s.info.info.outline of
        | OutlineTrueType() => false
        | OutlineCff() => true) else false
    in fold@(f); is_cff end

implement font_cff_glyph_span(f, gid) = case+ f of
  | @FONT(s) => let
      val res = sfnt_cff_glyph_span(s.file, s.cff_ctx, gid)
    in fold@(f); res end

implement font_cff_gsubr_count(f) = case+ f of
  | @FONT(s) => let
      val n = sfnt_cff_gsubr_count(s.file, s.cff_ctx)
    in fold@(f); n end

implement font_cff_gsubr_span(f, idx) = case+ f of
  | @FONT(s) => let
      val res = sfnt_cff_gsubr_span(s.file, s.cff_ctx, idx)
    in fold@(f); res end

implement font_cff_lsubr_count(f, gid) = case+ f of
  | @FONT(s) => let
      val n = sfnt_cff_lsubr_count(s.file, s.cff_ctx, gid)
    in fold@(f); n end

implement font_cff_lsubr_span(f, gid, idx) = case+ f of
  | @FONT(s) => let
      val res = sfnt_cff_lsubr_span(s.file, s.cff_ctx, gid, idx)
    in fold@(f); res end

implement font_cff_stk_get(f, i) = case+ f of
  | @FONT(s) => let
      val v = if ige(i, 0) andalso ilt(i, 64) then buf_get32(s.cff_stk, i) else 0
    in fold@(f); v end

implement font_cff_stk_set(f, i, v) = case+ f of
  | @FONT(s) => let
      val () = if ige(i, 0) andalso ilt(i, 64) then buf_set32(s.cff_stk, i, v) else ()
    in fold@(f) end

implement font_cff_ret_get(f, frame, k) = case+ f of
  | @FONT(s) => let
      val v = if ige(frame, 0) andalso ilt(frame, 16) andalso ige(k, 0) andalso ilt(k, 3)
              then buf_get32(s.cff_ret, iadd(imul(frame, 3), k)) else 0
    in fold@(f); v end

implement font_cff_ret_set(f, frame, k, v) = case+ f of
  | @FONT(s) => let
      val () = if ige(frame, 0) andalso ilt(frame, 16) andalso ige(k, 0) andalso ilt(k, 3)
               then buf_set32(s.cff_ret, iadd(imul(frame, 3), k), v) else ()
    in fold@(f) end

implement font_cff_i32(f, off) = let
  val hi = file_u16(f, off)
  val lo = file_u16(f, iadd(off, 2))
in
  if ilt(hi, 32768) then iadd(imul(hi, WORD16_MODULUS), lo)
  else if ieq(hi, 32768) andalso ieq(lo, 0) then ~2147483647 - 1
  else iadd(imul(isub(hi, WORD16_MODULUS), WORD16_MODULUS), lo)
end
