#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/font.sats"
staload "data_ast/doc.sats"
staload "data_image/image.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_tab.sats"
staload "ui_workspace/ui_render.sats"
staload "ui_workspace/ui_widgets.sats"

fun iand(a: int, n: int): int = anth_iand(a, n)

implement cache_free(c) =
  case+ c of
  | ~CNil() => ()
  | ~CCons(p, t, w, h, rest) => let
      val () = buf_free(p)
      val () = rend_tex_free(t)
      val _w = w
      val _h = h
    in
      cache_free(rest)
    end

fun cache_lookup(c: Cache, path: !Buf, tex: &uint >> _, w: &int >> _, h: &int >> _, hit: &int >> _): Cache =
  case+ c of
  | ~CNil() => let
      val () = hit := 0
    in
      CNil()
    end
  | ~CCons(p, t, iw, ih, rest) =>
      if ieq(beq(p, path, 0), 1) then let
        val () = tex := t
        val () = w := iw
        val () = h := ih
        val () = hit := 1
      in
        CCons(p, t, iw, ih, rest)
      end else let
        val rest2 = cache_lookup(rest, path, tex, w, h, hit)
      in
        CCons(p, t, iw, ih, rest2)
      end

fun cache_put(c: Cache, path: Buf, tex: uint, w: int, h: int): Cache =
  CCons(path, tex, w, h, c)

implement take_path(d, i, dst) = let
  val a0 = doc_get(d, i, 1)
  val b0 = doc_get(d, i, 2)
  var mode: int = 0
  var i0: int = a0
  val () = bclear(dst)
in
  while (ilt(i0, b0)) (
    if ieq(mode, 0) andalso ilt(iadd(i0, 1), b0) andalso ieq(doc_byte(d, i0), 91) andalso ieq(doc_byte(d, iadd(i0, 1)), 91) then (
      mode := 1; i0 := iadd(i0, 2)
    ) else if ieq(mode, 0) andalso ieq(doc_byte(d, i0), 40) then (
      mode := 1; i0 := iadd(i0, 1)
    ) else if ieq(mode, 1) andalso (ieq(doc_byte(d, i0), 124) orelse ieq(doc_byte(d, i0), 35) orelse ieq(doc_byte(d, i0), 93) orelse ieq(doc_byte(d, i0), 41)) then (
      mode := 2; i0 := b0
    ) else (
      if ieq(mode, 1) then buf_push(dst, doc_byte(d, i0)) else ();
      i0 := iadd(i0, 1)
    )
  )
end

implement resolve_path(vault, rel, dst) = let
  val () = bclear(dst)
in
  if igt(buf_len(rel), 0) andalso ieq(buf_get(rel, 0), 47) then bcat(dst, rel, 0, buf_len(rel))
  else let
    val j = join2(vault, rel)
    val () = bcat(dst, j, 0, buf_len(j))
    val () = buf_free(j)
  in
  end
end

implement with_md(path, dst) = let
  val () = bclear(dst)
  val () = bcat(dst, path, 0, buf_len(path))
in
  bstr_if(dst, iif(ieq(ends(path, ".md"), 1) orelse ieq(ends(path, ".png"), 1) orelse ieq(ends(path, ".jpg"), 1) orelse ieq(ends(path, ".jpeg"), 1) orelse ieq(ends(path, ".bmp"), 1), 0, 1), ".md")
end

fun count_nl(b: !Buf, capn: int, i: int, k: int): int =
  if ige(i, buf_len(b)) orelse ige(k, capn) then k
  else count_nl(b, capn, iadd(i, 1), iif(ieq(buf_get(b, i), 10), iadd(k, 1), k))

implement read_or(b, fd, sz) =
  if fd < 0 then let
    val _n = buf_len(b)
  in
    0
  end else fs_read(fd, buf_ptr(b), sz)

fun file_lines(path: !Buf, capn: int): int = let
  val p = cstr(path)
  val sz = fs_size(p)
in
  if sz <= 0 orelse sz > 50000000 then 0
  else let
    val fd = fs_open_read(p)
    var b = buf_make(iadd(sz, 1))
    val n = read_or(b, fd, sz)
    val () = if fd >= 0 then fs_close(fd) else ()
    val () = buf_set_len(b, if igt(n, 0) then n else 0)
    val k = count_nl(b, capn, 0, 1)
    val () = buf_free(b)
  in
    k
  end
end

fun load_tex(path: !Buf, r: !Rend, w: &int >> _, h: &int >> _): uint = let
  val im = img_open()
  val p = cstr(path)
  val ok = img_load(im, p)
  val tex = if ieq(ok, 1) then img_upload(im, r) else 0u
  val () = w := img_w(im)
  val () = h := img_h(im)
  val () = img_free(im)
in
  tex
end

fun ensure_tex(c: &Cache >> _, path: !Buf, r: !Rend, w: &int >> _, h: &int >> _): uint = let
  var tex: uint = 0u
  var iw: int = 0
  var ih: int = 0
  var hit: int = 0
  val c2 = cache_lookup(c, path, tex, iw, ih, hit)
  val () = c := c2
in
  if ieq(hit, 1) then let
    val () = w := iw
    val () = h := ih
  in
    tex
  end else let
    val t = load_tex(path, r, w, h)
    val owned = bcopy(path)
    val () = c := cache_put(c, owned, t, w, h)
  in
    t
  end
end

fun bind_one(d: !Doc, i: int, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int): void = let
  val k = doc_get(d, i, 0)
  var rel = buf_make(8)
  var full = buf_make(8)
  var shown = buf_make(8)
  val () = take_path(d, i, rel)
  val () = resolve_path(vault, rel, full)
  val () = with_md(full, shown)
in
  if ieq(k, 26) then let
    var iw: int = 0
    var ih: int = 0
    val _t = ensure_tex(c, shown, r, iw, ih)
    val dw = if ile(iw, 0) then 32 else imin(colw, imax(iw, 32))
    val dh = if ile(iw, 0) then 32 else imax(9, idiv(imul(ih, dw), iw))
    val () = doc_set(d, i, 10, dh)
    val () = buf_free(rel)
    val () = buf_free(full)
  in
    buf_free(shown)
  end else if ieq(k, 17) then let
    val lines = file_lines(shown, 12)
    val () = doc_set(d, i, 10, imax(9, imul(imin(lines, 12), lh)))
    val () = buf_free(rel)
    val () = buf_free(full)
  in
    buf_free(shown)
  end else let
    val () = buf_free(rel)
    val () = buf_free(full)
  in
    buf_free(shown)
  end
end

fun bind_media(d: !Doc, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int, i: int): void =
  if ige(i, doc_nnodes(d)) then ()
  else let
    val () = bind_one(d, i, c, r, vault, lh, colw)
  in
    bind_media(d, c, r, vault, lh, colw, iadd(i, 1))
  end

implement prep_doc(d, c, r, vault, lh, colw) = let
  val () = bind_media(d, c, r, vault, lh, colw, 0)
in
  doc_layout(d, lh)
end

fun kind_col(k: int): uint =
  if ige(k, 2) andalso ile(k, 7) then col_heading()
  else if ieq(k, 16) orelse ieq(k, 17) orelse ieq(k, 31) then col_link()
  else if ieq(k, 18) then col_tag()
  else if ieq(k, 22) then col_hightxt()
  else if ieq(k, 28) then col_white()
  else if ieq(k, 29) then col_accent()
  else if ieq(k, 30) then col_muted()
  else if ieq(k, 23) orelse ieq(k, 24) then col_math()
  else if ieq(k, 12) then col_code()
  else if ieq(k, 11) then col_quote()
  else if ieq(k, 19) then col_task()
  else if ieq(k, 25) then col_fm()
  else if ieq(k, 20) orelse ieq(k, 21) then col_accent()
  else col_text()

fun is_box(k: int): int =
  if ieq(k, 1) orelse (ige(k, 2) andalso ile(k, 7)) orelse ieq(k, 10) orelse ieq(k, 11) orelse ieq(k, 12) orelse ieq(k, 14) orelse ieq(k, 19) orelse ieq(k, 21) orelse ieq(k, 25) then 1 else 0

fun draw_bytes(f: !Font, r: !Rend, d: !Doc, a: int, b: int, x: int, oy: int, scroll: int, c: uint, scratch: &Buf >> _): void = let
  var i0: int = a
  val line0 = doc_line_of(d, a)
  val ls0 = doc_line_start(d, line0)
  val scap = buf_cap(scratch)
  val n_pre = if igt(a, ls0) then doc_slice(d, ls0, a, buf_ptr(scratch), scap) else 0
  val pre_w = if igt(n_pre, 0) then font_width(f, r, buf_ptr(scratch), n_pre) else 0
  var x0: int = iadd(x, pre_w)
in
  while (ilt(i0, b)) (
    if ieq(doc_byte(d, i0), 10) then (
      x0 := x; i0 := iadd(i0, 1)
    ) else let
      var j: int = i0
      val () = while (ilt(j, b) andalso ine(doc_byte(d, j), 10)) (j := iadd(j, 1))
      val n = doc_slice(d, i0, j, buf_ptr(scratch), scap)
      val y0 = isub(iadd(oy, doc_line_y(d, doc_line_of(d, i0))), scroll)
      val adv = font_draw(f, r, x0, y0, buf_ptr(scratch), n, c)
      val () = x0 := iadd(x0, adv)
      val () = i0 := j
    in
    end
  )
end

fun paint_file(f: !Font, r: !Rend, b: !Buf, n: int, nlines: int, x: int, lh: int, c: uint, i0: int, line: int, x0: int, y0: int): void =
  if ige(i0, n) orelse ige(line, nlines) then ()
  else if ieq(buf_get(b, i0), 10) then
    paint_file(f, r, b, n, nlines, x, lh, c, iadd(i0, 1), iadd(line, 1), x, iadd(y0, lh))
  else let
    val cap = buf_cap(b)
    val adv = font_draw(f, r, x0, y0, mem_ptr_at(buf_ptr(b), cap, i0), 1, c)
  in
    paint_file(f, r, b, n, nlines, x, lh, c, iadd(i0, 1), line, iadd(x0, adv), y0)
  end

fun draw_file_lines(f: !Font, r: !Rend, path: !Buf, x: int, y: int, lh: int, nlines: int, c: uint): void = let
  val p = cstr(path)
  val sz = fs_size(p)
in
  if sz <= 0 orelse sz > 50000000 then ()
  else let
    val fd = fs_open_read(p)
    var b = buf_make(iadd(sz, 1))
    val n0 = read_or(b, fd, sz)
    val () = if fd >= 0 then fs_close(fd) else ()
    val n = if igt(n0, 0) then n0 else 0
    val () = buf_set_len(b, n)
    val () = paint_file(f, r, b, n, nlines, x, lh, c, 0, 0, x, y)
  in
    buf_free(b)
  end
end

fun draw_plain_doc(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, pw: int, ph: int, scroll: int, lh: int, scratch: &Buf >> _): void = let
  val nlines = doc_nlines(d)
  val safe_lh = if igt(lh, 0) then lh else 18
  val li_start = imax(0, idiv(scroll, safe_lh))
  val li_end = imin(nlines, iadd(idiv(iadd(scroll, ph), safe_lh), 2))
  val scap = buf_cap(scratch)
  var li: int = li_start
in
  while (ilt(li, li_end)) (
    let
      val st = doc_line_start(d, li)
      val en0 = if ilt(iadd(li, 1), nlines) then doc_line_start(d, iadd(li, 1)) else doc_len(d)
      val en = if igt(en0, st) andalso ieq(doc_byte(d, isub(en0, 1)), 10) then isub(en0, 1) else en0
      val max_draw = imin(isub(en, st), 500)
      val n = if igt(max_draw, 0) then doc_slice(d, st, iadd(st, max_draw), buf_ptr(scratch), scap) else 0
      val yy = isub(iadd(oy, imul(li, safe_lh)), scroll)
      val _adv = if igt(n, 0) then font_draw(f, r, colx, yy, buf_ptr(scratch), n, col_text()) else 0
    in
      li := iadd(li, 1)
    end
  )
end

fun count_before(d: !Doc, a: int, p: int, k0: int): int =
  if ige(p, a) then k0
  else count_before(d, a, iadd(p, 1), iif(ieq(doc_byte(d, p), 10), iadd(k0, 1), k0))

fun draw_arrow(f: !Font, r: !Rend, d: !Doc, i: int, k: int, colx: int, y: int): void =
  if (ige(k, 2) andalso ile(k, 7)) orelse ieq(k, 10) orelse ieq(k, 19) then let
    val folded = doc_get(d, i, 4)
    val arr = if ieq(folded, 1) then ">" else "v"
    val acol = if ieq(folded, 1) then col_accent() else col_muted()
    val _da = draw_s(f, r, isub(colx, 16), y, arr, acol)
  in
  end else ()

fun draw_view_slice(f: !Font, r: !Rend, d: !Doc, a: int, b: int, colx: int, oy: int, scroll: int, lh: int, ph: int, c: uint, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): int = let
  var i0: int = a
  val scap = buf_cap(scratch)
  var total_adv: int = 0
in
  while (ilt(i0, b)) (
    if ieq(doc_byte(d, i0), 10) then (
      pen_x := colx;
      pen_line := iadd(pen_line, 1);
      i0 := iadd(i0, 1)
    ) else let
      var j: int = i0
      val () = while (ilt(j, b) andalso ine(doc_byte(d, j), 10)) (j := iadd(j, 1))
      val cur_line = doc_line_of(d, i0)
      val () = if ine(cur_line, pen_line) then (pen_line := cur_line; pen_x := colx) else ()
      val yy = isub(iadd(oy, doc_line_y(d, cur_line)), scroll)
      val n = doc_slice(d, i0, j, buf_ptr(scratch), scap)
      val adv = if igt(n, 0) then (
        if ilt(iadd(yy, lh), oy) orelse igt(yy, iadd(oy, ph)) then
          font_width(f, r, buf_ptr(scratch), n)
        else
          font_draw(f, r, pen_x, yy, buf_ptr(scratch), n, c)
      ) else 0
      val () = pen_x := iadd(pen_x, adv)
      val () = total_adv := iadd(total_adv, adv)
      val () = i0 := j
    in
    end
  );
  total_adv
end

fun draw_node(f: !Font, r: !Rend, d: !Doc, i: int, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: int): void = let
  val k = doc_get(d, i, 0)
  val y = isub(iadd(oy, doc_get(d, i, 13)), scroll)
  val h = doc_get(d, i, 5)
  val colx = column_x(ox, pw)
  val hidden = doc_get(d, i, 9)
  val p_idx = doc_get(d, i, 6)
  val p_k = if ige(p_idx, 0) then doc_get(d, p_idx, 0) else 0
  val in_heading = if ige(p_k, 2) andalso ile(p_k, 7) then 1 else 0
in
  if ine(hidden, 0) orelse (ieq(in_heading, 1) andalso ieq(viewmode, 1)) then ()
  else let
    val () = draw_arrow(f, r, d, i, k, colx, y)
  in
    if ige(k, 2) andalso ile(k, 7) then let
      val () = py := y
      val () = pa := doc_get(d, i, 1)
      val a = doc_get(d, i, 1)
      val b = doc_get(d, i, 2)
      val line = doc_line_of(d, a)
      val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
      val () = pen_line := line
      val () = pen_x := colx
    in
      if ilt(iadd(yy, lh), oy) orelse igt(yy, iadd(oy, ph)) then ()
      else if ieq(viewmode, 1) then let
        val snum = (if ieq(k, 2) then 7
                    else if ieq(k, 3) then 3
                    else if ieq(k, 4) then 5
                    else if ieq(k, 5) then 23
                    else if ieq(k, 6) then 11
                    else 1)
        val sden = (if ieq(k, 2) then 4
                    else if ieq(k, 3) then 2
                    else if ieq(k, 4) then 4
                    else if ieq(k, 5) then 20
                    else if ieq(k, 6) then 10
                    else 1)
        var st: int = a
        val () = while (ilt(st, b) andalso ieq(doc_byte(d, st), 35)) (st := iadd(st, 1))
        val () = while (ilt(st, b) andalso (ieq(doc_byte(d, st), 32) orelse ieq(doc_byte(d, st), 9))) (st := iadd(st, 1))
        var en_h: int = b
        val () = while (igt(en_h, st) andalso (ieq(doc_byte(d, isub(en_h, 1)), 10) orelse ieq(doc_byte(d, isub(en_h, 1)), 13))) (en_h := isub(en_h, 1))
        val scap = buf_cap(scratch)
        val n = if igt(en_h, st) then doc_slice(d, st, en_h, buf_ptr(scratch), scap) else 0
        val _w = if igt(n, 0) then font_draw_scaled(f, r, colx, yy, buf_ptr(scratch), n, col_heading(), snum, sden) else 0
      in
      end else ()
    end else if ieq(is_box(k), 1) then let
      val () = py := y
      val () = pa := doc_get(d, i, 1)
      val () = pen_line := ~1
      val () = pen_x := colx
    in
      if ieq(k, 12) orelse ieq(k, 25) orelse ieq(k, 21) then
        draw_bytes(f, r, d, doc_get(d, i, 1), doc_get(d, i, 2), colx, oy, scroll, kind_col(k), scratch)
      else if ieq(k, 11) then rend_rect(r, isub(colx, 8), y, 3, imax(h, lh), col_quote())
      else ()
    end else if ieq(k, 13) then let
      val () = pen_line := ~1
      val () = pen_x := colx
    in
      rend_rect(r, colx, iadd(y, 4), column_w(pw), 2, col_line())
    end else if ieq(k, 26) then let
      val () = pen_line := ~1
      val () = pen_x := colx
      var rel = buf_make(8)
      var full = buf_make(8)
      var shown = buf_make(8)
      val () = take_path(d, i, rel)
      val () = resolve_path(vault, rel, full)
      val () = with_md(full, shown)
      var iw: int = 0
      var ih: int = 0
      val tex = ensure_tex(c, shown, r, iw, ih)
      val dw = if ile(iw, 0) then 32 else imin(column_w(pw), imax(iw, 32))
      val dh = if ile(ih, 0) then h else imax(h, 9)
      val () = if ine(uok(tex), 0) then rend_quad(r, tex, 2, colx, y, dw, dh, 0.0, 0.0, 1.0, 1.0, col_white()) else ()
      val () = buf_free(rel)
      val () = buf_free(full)
    in
      buf_free(shown)
    end else if ieq(k, 17) then let
      val () = pen_line := ~1
      val () = pen_x := colx
      var rel = buf_make(8)
      var full = buf_make(8)
      var shown = buf_make(8)
      val () = take_path(d, i, rel)
      val () = resolve_path(vault, rel, full)
      val () = with_md(full, shown)
      val () = draw_file_lines(f, r, shown, colx, y, lh, 12, col_muted())
      val () = buf_free(rel)
      val () = buf_free(full)
    in
      buf_free(shown)
    end else if ieq(viewmode, 1) then (
      if ieq(k, 31) then let
        val a = doc_get(d, i, 1)
        val b = doc_get(d, i, 2)
        val st = iadd(a, 1)
        var c_br: int = st
        val () = while (ilt(c_br, b) andalso ine(doc_byte(d, c_br), 93)) (c_br := iadd(c_br, 1))
        val label_en = (if ilt(c_br, b) then c_br else b)
        val line = doc_line_of(d, st)
        val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
        val x0 = (if ine(line, pen_line) then colx else pen_x)
        val tw = draw_view_slice(f, r, d, st, label_en, colx, oy, scroll, lh, ph, col_link(), scratch, pen_x, pen_line)
        val () = if igt(tw, 0) andalso ige(iadd(yy, lh), oy) andalso ile(yy, iadd(oy, ph)) then
          rend_rect(r, x0, iadd(yy, isub(lh, 2)), tw, 1, col_link())
        else ()
      in
      end else if ieq(k, 16) then let
        val a = doc_get(d, i, 1)
        val b = doc_get(d, i, 2)
        val st = iadd(a, 2)
        val en = (if igt(b, 2) then isub(b, 2) else b)
        var p_pipe: int = ~1
        var cur_p: int = st
        val () = while (ilt(cur_p, en)) (
          if ieq(doc_byte(d, cur_p), 124) then p_pipe := cur_p else ();
          cur_p := iadd(cur_p, 1)
        )
        val label_st = (if ige(p_pipe, 0) then iadd(p_pipe, 1) else st)
        val label_en = en
        val line = doc_line_of(d, label_st)
        val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
        val x0 = (if ine(line, pen_line) then colx else pen_x)
        val tw = draw_view_slice(f, r, d, label_st, label_en, colx, oy, scroll, lh, ph, col_link(), scratch, pen_x, pen_line)
        val () = if igt(tw, 0) andalso ige(iadd(yy, lh), oy) andalso ile(yy, iadd(oy, ph)) then
          rend_rect(r, x0, iadd(yy, isub(lh, 2)), tw, 1, col_link())
        else ()
      in
      end else if ieq(k, 28) then let
        val a = doc_get(d, i, 1)
        val b = doc_get(d, i, 2)
        val st = (if ile(iadd(a, 2), b) then iadd(a, 2) else a)
        val en = (if ige(isub(b, 2), st) then isub(b, 2) else b)
        val _tw = draw_view_slice(f, r, d, st, en, colx, oy, scroll, lh, ph, col_white(), scratch, pen_x, pen_line)
      in
      end else if ieq(k, 29) then let
        val a = doc_get(d, i, 1)
        val b = doc_get(d, i, 2)
        val st = (if ile(iadd(a, 1), b) then iadd(a, 1) else a)
        val en = (if ige(isub(b, 1), st) then isub(b, 1) else b)
        val _tw = draw_view_slice(f, r, d, st, en, colx, oy, scroll, lh, ph, col_accent(), scratch, pen_x, pen_line)
      in
      end else if ieq(k, 30) then let
        val a = doc_get(d, i, 1)
        val b = doc_get(d, i, 2)
        val st = (if ile(iadd(a, 2), b) then iadd(a, 2) else a)
        val en = (if ige(isub(b, 2), st) then isub(b, 2) else b)
        val line = doc_line_of(d, st)
        val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
        val x0 = (if ine(line, pen_line) then colx else pen_x)
        val tw = draw_view_slice(f, r, d, st, en, colx, oy, scroll, lh, ph, col_muted(), scratch, pen_x, pen_line)
        val () = if igt(tw, 0) andalso ige(iadd(yy, lh), oy) andalso ile(yy, iadd(oy, ph)) then
          rend_rect(r, x0, iadd(yy, idiv(lh, 2)), tw, 1, col_muted())
        else ()
      in
      end else if ieq(k, 22) then let
        val a = doc_get(d, i, 1)
        val b = doc_get(d, i, 2)
        val st = (if ile(iadd(a, 2), b) then iadd(a, 2) else a)
        val en = (if ige(isub(b, 2), st) then isub(b, 2) else b)
        val line = doc_line_of(d, st)
        val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
        val x0 = (if ine(line, pen_line) then colx else pen_x)
        val scap = buf_cap(scratch)
        val n = if igt(en, st) then doc_slice(d, st, en, buf_ptr(scratch), scap) else 0
        val tw0 = if igt(n, 0) then font_width(f, r, buf_ptr(scratch), n) else 0
        val () = if igt(tw0, 0) andalso ige(iadd(yy, lh), oy) andalso ile(yy, iadd(oy, ph)) then
          rend_rect(r, x0, yy, tw0, lh, col_highbg())
        else ()
        val _tw = draw_view_slice(f, r, d, st, en, colx, oy, scroll, lh, ph, col_hightxt(), scratch, pen_x, pen_line)
      in
      end else if ieq(k, 23) then let
        val a = doc_get(d, i, 1)
        val b = doc_get(d, i, 2)
        val st = (if ile(iadd(a, 1), b) then iadd(a, 1) else a)
        val en = (if ige(isub(b, 1), st) then isub(b, 1) else b)
        val _tw = draw_view_slice(f, r, d, st, en, colx, oy, scroll, lh, ph, col_math(), scratch, pen_x, pen_line)
      in
      end else if ieq(k, 18) then let
        val a = doc_get(d, i, 1)
        val b = doc_get(d, i, 2)
        val _tw = draw_view_slice(f, r, d, a, b, colx, oy, scroll, lh, ph, col_tag(), scratch, pen_x, pen_line)
      in
      end else let
        val a = doc_get(d, i, 1)
        val b = doc_get(d, i, 2)
        val _tw = draw_view_slice(f, r, d, a, b, colx, oy, scroll, lh, ph, col_text(), scratch, pen_x, pen_line)
      in
      end
    ) else if ieq(k, 22) then let
      val a = doc_get(d, i, 1)
      val b = doc_get(d, i, 2)
      val line = doc_line_of(d, a)
      val ls = doc_line_start(d, line)
      val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
      val scap = buf_cap(scratch)
      val n_pre = if igt(a, ls) then doc_slice(d, ls, a, buf_ptr(scratch), scap) else 0
      val pre_w = if igt(n_pre, 0) then font_width(f, r, buf_ptr(scratch), n_pre) else 0
      val n = doc_slice(d, a, b, buf_ptr(scratch), scap)
      val w_hi = font_width(f, r, buf_ptr(scratch), n)
      val () = rend_rect(r, iadd(colx, pre_w), yy, w_hi, lh, col_highbg())
    in
      draw_bytes(f, r, d, a, b, colx, oy, scroll, kind_col(k), scratch)
    end else let
      val a = doc_get(d, i, 1)
      val yy = isub(iadd(oy, doc_line_y(d, doc_line_of(d, a))), scroll)
    in
      if ilt(iadd(yy, lh), oy) orelse igt(yy, iadd(oy, ph)) then ()
      else draw_bytes(f, r, d, a, doc_get(d, i, 2), colx, oy, scroll, kind_col(k), scratch)
    end
  end
end

fun draw_nodes_impl(f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: int): void =
  if ige(i, doc_nnodes(d)) then ()
  else let
    val () = draw_node(f, r, d, i, ox, oy, pw, ph, scroll, lh, vault, c, scratch, py, pa, pen_x, pen_line, viewmode)
  in
    draw_nodes_impl(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, iadd(i, 1), py, pa, pen_x, pen_line, viewmode)
  end

fun caret_xy(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _, x: &int >> _, y: &int >> _): void = let
  val caret = doc_caret(d)
  val line = doc_line_of(d, caret)
  val ls = doc_line_start(d, line)
  val scap = buf_cap(scratch)
  val n = doc_slice(d, ls, caret, buf_ptr(scratch), scap)
  val adv = font_width(f, r, buf_ptr(scratch), n)
  val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
  val () = x := iadd(colx, adv)
  val _h = lh
in
  y := yy
end

fun draw_sel_line(f: !Font, r: !Rend, d: !Doc, ls: int, le: int, smin: int, smax: int, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void = let
  val a = imax(ls, smin)
  val b = imin(le, smax)
in
  if ilt(a, b) then let
    val scap = buf_cap(scratch)
    val na = doc_slice(d, ls, a, buf_ptr(scratch), scap)
    val wa = font_width(f, r, buf_ptr(scratch), na)
    val nb = doc_slice(d, ls, b, buf_ptr(scratch), scap)
    val wb = font_width(f, r, buf_ptr(scratch), nb)
    val line = doc_line_of(d, ls)
    val sy = isub(iadd(oy, doc_line_y(d, line)), scroll)
    val sx = iadd(colx, wa)
    val sw = imax(isub(wb, wa), 4)
  in
    rend_rect(r, sx, sy, sw, lh, col_sel())
  end else ()
end

fun draw_selection(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void = let
  val caret = doc_caret(d)
  val anchor = doc_anchor(d)
in
  if ine(caret, anchor) then let
    val smin = imin(caret, anchor)
    val smax = imax(caret, anchor)
    val l0 = doc_line_of(d, smin)
    val l1 = doc_line_of(d, smax)
    var li: int = l0
  in
    while (ile(li, l1) andalso ilt(li, doc_nlines(d))) (
      let
        val ls = doc_line_start(d, li)
        val le = if ilt(iadd(li, 1), doc_nlines(d)) then doc_line_start(d, iadd(li, 1)) else doc_len(d)
      in
        draw_sel_line(f, r, d, ls, le, smin, smax, colx, oy, scroll, lh, scratch);
        li := iadd(li, 1)
      end
    )
  end else ()
end

implement draw_doc(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, viewmode) = let
  val height = prep_doc(d, c, r, vault, lh, column_w(pw))
  var py: int = oy
  var pa: int = 0
  val colx = column_x(ox, pw)
  var pen_x: int = colx
  var pen_line: int = ~1
  val () = rend_scissor(r, ox, oy, pw, ph)
  val () = draw_selection(f, r, d, colx, oy, scroll, lh, scratch)
  val () =
    if doc_nnodes(d) > 0 then
      draw_nodes_impl(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, 0, py, pa, pen_x, pen_line, viewmode)
    else
      draw_plain_doc(f, r, d, colx, oy, pw, ph, scroll, lh, scratch)
  val () = if ieq(viewmode, 0) then let
    var cx: int = 0
    var cy: int = 0
    val () = caret_xy(f, r, d, colx, oy, scroll, lh, scratch, cx, cy)
    val bar = if igt(lh, 0) then lh else 1
    val () = rend_rect(r, cx, cy, 2, bar, col_caret())
  in
  end else ()
  val () = rend_scissor_off(r)
  val () = if igt(height, ph) then ui_scroll_bar(r, isub(iadd(ox, pw), 6), oy, 6, ph, 1, height, ph, scroll, 0, 0) else ()
  val _p = py
  val _a = pa
in
  height
end

fun draw_tabrow_impl(f: !Font, r: !Rend, ts: Tabs, x: int, active: int, i: int): Tabs =
  case+ ts of
  | ~TNil() => TNil()
  | ~TCons(doc, path, title, sc, rest) => let
      val tlen = buf_len(title)
      val tw = if igt(tlen, 0) then font_width(f, r, buf_ptr(title), tlen) else 0
      val tab_w = imin(200, imax(100, iadd(tw, 36)))
      val bx = x
      val next_x = iadd(bx, iadd(tab_w, 4))
      val bg = if ieq(i, active) then col_bg() else col_side()
      val () = rend_rect(r, bx, 4, tab_w, 28, bg)
      val () = ui_draw_border(r, bx, 4, tab_w, 28, 1, if ieq(i, active) then col_line() else col_bar())
      val () = if ieq(i, active) then rend_rect(r, bx, 4, tab_w, 2, col_accent()) else ()
      val text_w = isub(tab_w, 32)
      val () = rend_scissor(r, iadd(bx, 8), 4, text_w, 28)
      val _n = font_draw(f, r, iadd(bx, 8), 8, buf_ptr(title), tlen, if ieq(i, active) then col_white() else col_text())
      val () = rend_scissor_off(r)
      val close_x = isub(iadd(bx, tab_w), 18)
      val () = ui_draw_icon(f, r, UI_ICON_CLOSE, close_x, 14, 8, col_muted())
      val _d = touch_doc(doc)
      val _s = sc
      val rest2 = draw_tabrow_impl(f, r, rest, next_x, active, iadd(i, 1))
    in
      TCons(doc, path, title, sc, rest2)
    end

implement draw_tabrow(f, r, ts, x, active, i) = draw_tabrow_impl(f, r, ts, x, active, i)

fun tab_hit_test_impl(f: !Font, r: !Rend, ts: !Tabs, x: int, click_x: int, i: int, out_ti: &int >> _, out_close: &int >> _): void =
  case+ ts of
  | TNil() => ()
  | TCons(_, _, title, _, rest) => let
      val tlen = buf_len(title)
      val tw = if igt(tlen, 0) then font_width(f, r, buf_ptr(title), tlen) else 0
      val tab_w = imin(200, imax(100, iadd(tw, 36)))
      val close_x = isub(iadd(x, tab_w), 24)
    in
      if ige(click_x, x) andalso ilt(click_x, iadd(x, tab_w)) then (
        out_ti := i;
        out_close := (if ige(click_x, close_x) then 1 else 0)
      ) else (
        tab_hit_test_impl(f, r, rest, iadd(x, iadd(tab_w, 4)), click_x, iadd(i, 1), out_ti, out_close)
      )
    end

implement tab_hit_test(f, r, ts, start_x, click_x, out_ti, out_close) =
  tab_hit_test_impl(f, r, ts, start_x, click_x, 0, out_ti, out_close)

fun seal_cs(c: &Cache >> _, scratch: &Buf >> _): int = let
  val saved = c
  val () = c := saved
  val _n = buf_len(scratch)
in
  0
end

fun draw_focus_impl(f: !Font, r: !Rend, ts: Tabs, idx: int, ox: int, oy: int, pw: int, ph: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, viewmode: int): Tabs =
  case+ ts of
  | ~TNil() => let
      val _u = seal_cs(c, scratch)
    in
      TNil()
    end
  | ~TCons(doc, path, title, sc, rest) => let
      val _h = if ieq(i, idx) then draw_doc(f, r, doc, ox, oy, pw, ph, sc, lh, vault, c, scratch, viewmode) else seal_cs(c, scratch)
      val rest2 = draw_focus_impl(f, r, rest, idx, ox, oy, pw, ph, lh, vault, c, scratch, iadd(i, 1), viewmode)
    in
      TCons(doc, path, title, sc, rest2)
    end

implement draw_right(f, r, ts, split, idx, ox, oy, pw, ph, lh, vault, c, scratch, viewmode) =
  if ieq(split, 1) then draw_focus(f, r, ts, idx, ox, oy, pw, ph, lh, vault, c, scratch, 0, viewmode)
  else let
    val _u = seal_cs(c, scratch)
  in
    ts
  end

implement draw_focus(f, r, ts, idx, ox, oy, pw, ph, lh, vault, c, scratch, i, viewmode) = draw_focus_impl(f, r, ts, idx, ox, oy, pw, ph, lh, vault, c, scratch, i, viewmode)

fun node_covering_impl(d: !Doc, y: int, oy: int, scroll: int, i: int, best: int): int =
  if ige(i, doc_nnodes(d)) then best
  else let
    val sy = isub(iadd(oy, doc_get(d, i, 13)), scroll)
    val h = doc_get(d, i, 5)
    val best2 = if igt(h, 0) andalso ige(y, sy) andalso ilt(y, iadd(sy, h)) then i else best
  in
    node_covering_impl(d, y, oy, scroll, iadd(i, 1), best2)
  end

implement node_covering(d, y, oy, scroll, i, best) = node_covering_impl(d, y, oy, scroll, i, best)

fun utf8_char_sz(d: !Doc, i: int, maxlen: int): int =
  if i >= maxlen then 1
  else let
    val b = doc_byte(d, i)
  in
    if b < 128 then 1
    else if b < 224 then (if i + 2 <= maxlen then 2 else maxlen - i)
    else if b < 240 then (if i + 3 <= maxlen then 3 else maxlen - i)
    else (if i + 4 <= maxlen then 4 else maxlen - i)
  end

fun click_place(f: !Font, r: !Rend, d: !Doc, x: int, ls: int, colx: int, scratch: &Buf >> _, keep: int): void = let
  val len = doc_len(d)
  var i0: int = ls
  var pen: int = colx
  val scap = buf_cap(scratch)
in
  while (ilt(i0, len) andalso ine(doc_byte(d, i0), 10) andalso ilt(pen, x)) (
    let
      val clen = utf8_char_sz(d, i0, len)
      val n = doc_slice(d, i0, iadd(i0, clen), buf_ptr(scratch), scap)
      val cw = imax(font_width(f, r, buf_ptr(scratch), n), 1)
    in
      if pen + cw / 2 >= x then (
        pen := x
      ) else (
        pen := iadd(pen, cw);
        i0 := iadd(i0, clen)
      )
    end
  );
  doc_set_caret(d, i0, keep)
end

fun line_y_bsearch(d: !Doc, docy: int, lo: int, hi: int, best: int): int =
  if igt(lo, hi) then best
  else let
    val mid = iadd(lo, idiv(isub(hi, lo), 2))
    val ly = doc_line_y(d, mid)
  in
    if ile(ly, docy) then line_y_bsearch(d, docy, iadd(mid, 1), hi, mid)
    else line_y_bsearch(d, docy, lo, isub(mid, 1), best)
  end

fun line_at_y(d: !Doc, docy: int, i: int, best: int): int =
  line_y_bsearch(d, docy, 0, isub(doc_nlines(d), 1), 0)

fun line_at_y_fast(d: !Doc, docy: int, lh: int): int = let
  val n = doc_nlines(d)
  val safe_lh = if igt(lh, 0) then lh else 18
in
  if ile(n, 1) then 0
  else if ieq(doc_nnodes(d), 0) then
    imax(0, imin(isub(n, 1), idiv(docy, safe_lh)))
  else
    line_at_y(d, docy, 0, 0)
end

fun click_doc(f: !Font, r: !Rend, d: !Doc, x: int, y: int, ox: int, pw: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _, keep: int, hitk: &int >> _, hiti: &int >> _): void = let
  val ni = node_covering_impl(d, y, oy, scroll, 0, ~1)
  val hk = if ige(ni, 0) then doc_get(d, ni, 0) else 0
  val () = hitk := hk
  val () = hiti := ni
  val docy = iadd(isub(y, oy), scroll)
  val line0 = line_at_y_fast(d, docy, lh)
  val ls = doc_line_start(d, imax(0, line0))
  val colx = column_x(ox, pw)
  val _lh = lh
in
  if ige(ni, 0) andalso (ieq(hk, 26) orelse ieq(hk, 17)) then doc_set_caret(d, doc_get(d, ni, 1), 0)
  else click_place(f, r, d, x, ls, colx, scratch, keep)
end

fun click_if(f: !Font, r: !Rend, doc: !Doc, x: int, y: int, ox: int, pw: int, sc: int, lh: int, scratch: &Buf >> _, keep: int, hitk: &int >> _, hiti: &int >> _, go: int): void =
  if ieq(go, 1) then click_doc(f, r, doc, x, y, ox, pw, 36, sc, lh, scratch, keep, hitk, hiti) else touchb(scratch)

fun tabs_click_impl(f: !Font, r: !Rend, ts: Tabs, idx: int, x: int, y: int, ox: int, pw: int, scroll_hint: int, lh: int, scratch: &Buf >> _, keep: int, hitk: &int >> _, hiti: &int >> _, i: int): Tabs =
  case+ ts of
  | ~TNil() => TNil()
  | ~TCons(doc, path, title, sc, rest) => let
      val () = click_if(f, r, doc, x, y, ox, pw, sc, lh, scratch, keep, hitk, hiti, iif(ieq(i, idx), 1, 0))
    in
      TCons(doc, path, title, sc, click_rest(ieq(i, idx), f, r, rest, idx, x, y, ox, pw, scroll_hint, lh, scratch, keep, hitk, hiti, i))
    end
and click_rest(stop: bool, f: !Font, r: !Rend, rest: Tabs, idx: int, x: int, y: int, ox: int, pw: int, scroll_hint: int, lh: int, scratch: &Buf >> _, keep: int, hitk: &int >> _, hiti: &int >> _, i: int): Tabs =
  if stop then let
    val () = touchb(scratch)
  in
    rest
  end else tabs_click_impl(f, r, rest, idx, x, y, ox, pw, scroll_hint, lh, scratch, keep, hitk, hiti, iadd(i, 1))

implement tabs_click(f, r, ts, idx, x, y, ox, pw, scroll_hint, lh, scratch, keep, hitk, hiti, i) = tabs_click_impl(f, r, ts, idx, x, y, ox, pw, scroll_hint, lh, scratch, keep, hitk, hiti, i)

implement draw_nodes(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, i, py, pa, viewmode) = let
  var px: int = column_x(ox, pw)
  var pl: int = ~1
in
  draw_nodes_impl(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, i, py, pa, px, pl, viewmode)
end
