#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
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

extern fun cache_free_exh(c: Cache): void = "mac#anth_die_void"

fun cache_free_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), c: Cache): void =
  if recfuel > 0 then (
    case+ c of
    | ~CNil() => ()
    | ~CCons(p, t, w, h, rest) => let
        val () = buf_free(p)
        val () = rend_tex_free(t)
        val () = seen_int(w)
        val () = seen_int(h)
      in
        cache_free_m(recfuel - 1, rest)
      end
  ) else cache_free_exh(c)

implement cache_free(c) = cache_free_m(airlock_nat(MAX_REC_FUEL), c)

extern fun cache_lookup_exh(c: Cache, path: !Buf, tex: &uint >> _, w: &int >> _, h: &int >> _, hit: &Toggle >> _): Cache = "mac#anth_die_box"

fun cache_accept(p: Buf, t: uint, iw: int, ih: int, rest: Cache, tex: &uint >> _, w: &int >> _, h: &int >> _, hit: &Toggle >> _): Cache = let
  val () = tex := t
  val () = w := iw
  val () = h := ih
  val () = hit := On
in
  CCons(p, t, iw, ih, rest)
end

fun cache_lookup_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), c: Cache, path: !Buf, tex: &uint >> _, w: &int >> _, h: &int >> _, hit: &Toggle >> _): Cache =
  if recfuel > 0 then (
    case+ c of
    | ~CNil() => let
        val () = hit := Off
      in
        CNil()
      end
    | ~CCons(p, t, iw, ih, rest) =>
        if beq(p, path, 0) then cache_accept(p, t, iw, ih, rest, tex, w, h, hit)
        else let
          val rest2 = cache_lookup_m(recfuel - 1, rest, path, tex, w, h, hit)
        in
          CCons(p, t, iw, ih, rest2)
        end
  ) else cache_lookup_exh(c, path, tex, w, h, hit)

fun cache_lookup(c: Cache, path: !Buf, tex: &uint >> _, w: &int >> _, h: &int >> _, hit: &Toggle >> _): Cache = cache_lookup_m(airlock_nat(MAX_REC_FUEL), c, path, tex, w, h, hit)

fun cache_put(c: Cache, path: Buf, tex: uint, w: int, h: int): Cache =
  CCons(path, tex, w, h, c)

datatype PathScan = ScanSeek | ScanCopy | ScanDone

fun scan_code(m: PathScan): int = case+ m of
  | ScanSeek() => 0
  | ScanCopy() => 1
  | ScanDone() => 2

fun is_scan(a: PathScan, b: PathScan): bool = scan_code(a) = scan_code(b)

fun take_advance(d: !Doc, mode: PathScan, i0: int, b0: int, dst: &Buf >> _): @(PathScan, int) =
  if is_scan(mode, ScanSeek) andalso ilt(iadd(i0, 1), b0) andalso ieq(doc_byte(d, i0), 91) andalso ieq(doc_byte(d, iadd(i0, 1)), 91) then
    @(ScanCopy(), iadd(i0, 2))
  else if is_scan(mode, ScanSeek) andalso ieq(doc_byte(d, i0), 40) then
    @(ScanCopy(), iadd(i0, 1))
  else if is_scan(mode, ScanCopy) andalso (ieq(doc_byte(d, i0), 124) orelse ieq(doc_byte(d, i0), 35) orelse ieq(doc_byte(d, i0), 93) orelse ieq(doc_byte(d, i0), 41)) then
    @(ScanDone(), b0)
  else let
    val () = if is_scan(mode, ScanCopy) then buf_push(dst, doc_byte(d, i0)) else ()
  in
    @(mode, iadd(i0, 1))
  end

extern fun take_path_exh(d: !Doc, mode: PathScan, i0: int, b0: int, dst: &Buf >> _): void = "mac#anth_die_void"

fun take_path_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, mode: PathScan, i0: int, b0: int, dst: &Buf >> _): void =
  if recfuel > 0 then (
    if ilt(i0, b0) then let
      val nxt = take_advance(d, mode, i0, b0, dst)
    in
      take_path_m(recfuel - 1, d, nxt.0, nxt.1, b0, dst)
    end else ()
  ) else take_path_exh(d, mode, i0, b0, dst)

implement take_path(d, i, dst) = let
  val a0 = doc_node_start(d, i)
  val b0 = doc_node_end(d, i)
  val () = bclear(dst)
in
  take_path_m(airlock_nat(MAX_REC_FUEL), d, ScanSeek(), a0, b0, dst)
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
  bstr_if(dst, toggle_of(not(ends(path, ".md") orelse ends(path, ".png") orelse ends(path, ".jpg") orelse ends(path, ".jpeg") orelse ends(path, ".bmp"))), ".md")
end

extern fun count_nl_exh(b: !Buf, capn: int, i: int, k: int): int = "mac#anth_die_int"

fun count_nl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, capn: int, i: int, k: int): int =
  if recfuel > 0 then (
    if ige(i, buf_len(b)) orelse ige(k, capn) then k
    else count_nl_m(recfuel - 1, b, capn, iadd(i, 1), (if ieq(buf_get(b, i), 10) then iadd(k, 1) else k))
  ) else count_nl_exh(b, capn, i, k)

fun count_nl(b: !Buf, capn: int, i: int, k: int): int = count_nl_m(airlock_nat(MAX_REC_FUEL), b, capn, i, k)

implement read_or(b, fd, sz) =
  if fd < 0 then let
    val () = seen_buf(b)
  in
    0
  end else fs_read_buf(fd, b, sz)

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


fun ensure_tex_miss(c: &Cache >> _, path: !Buf, r: !Rend, w: &int >> _, h: &int >> _): uint = let
  val t = load_tex(path, r, w, h)
  val owned = bcopy(path)
  val () = c := cache_put(c, owned, t, w, h)
in
  t
end

fun ensure_tex(c: &Cache >> _, path: !Buf, r: !Rend, w: &int >> _, h: &int >> _): uint = let
  var tex: uint = 0u
  var iw: int = 0
  var ih: int = 0
  var hit: Toggle = Off
  val c2 = cache_lookup(c, path, tex, iw, ih, hit)
  val () = c := c2
in
  if is_on(hit) then let
    val () = w := iw
    val () = h := ih
  in
    tex
  end else ensure_tex_miss(c, path, r, w, h)
end


fun bind_image_height(d: !Doc, i: int, c: &Cache >> _, r: !Rend, shown: !Buf, colw: int): void = let
  var iw: int = 0
  var ih: int = 0
  val () = seen_uint(ensure_tex(c, shown, r, iw, ih))
  val dw = if ile(iw, 0) then 32 else imin(colw, imax(iw, 32))
  val dh = if ile(iw, 0) then 32 else imax(9, idiv(imul(ih, dw), iw))
in
  doc_set(d, i, NF_AUX, dh)
end

fun bind_embed_height(d: !Doc, i: int, shown: !Buf, lh: int): void = let
  val lines = file_lines(shown, 12)
in
  doc_set(d, i, NF_AUX, imax(9, imul(imin(lines, 12), lh)))
end

fun resolve_media_path(d: !Doc, i: int, vault: !Buf, rel: &Buf >> _, full: &Buf >> _, shown: &Buf >> _): void = let
  val () = take_path(d, i, rel)
  val () = resolve_path(vault, rel, full)
  val () = with_md(full, shown)
in
end

fun bind_one_kind(d: !Doc, i: int, k: NodeKind, c: &Cache >> _, r: !Rend, lh: int, colw: int, shown: !Buf): void =
  if is_kind(k, KImage) then bind_image_height(d, i, c, r, shown, colw)
  else if is_kind(k, KEmbed) then bind_embed_height(d, i, shown, lh)
  else ()

fun bind_one(d: !Doc, i: int, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int): void = let
  val k = doc_node_kind(d, i)
  var rel = buf_make(8)
  var full = buf_make(8)
  var shown = buf_make(8)
  val () = resolve_media_path(d, i, vault, rel, full, shown)
  val () = bind_one_kind(d, i, k, c, r, lh, colw, shown)
  val () = buf_free(rel)
  val () = buf_free(full)
in
  buf_free(shown)
end

extern fun bind_media_exh(d: !Doc, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int, i: int): void = "mac#anth_die_void"

fun bind_media_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, doc_nnodes(d)) then ()
    else let
      val () = bind_one(d, i, c, r, vault, lh, colw)
    in
      bind_media_m(recfuel - 1, d, c, r, vault, lh, colw, iadd(i, 1))
    end
  ) else bind_media_exh(d, c, r, vault, lh, colw, i)

fun bind_media(d: !Doc, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int, i: int): void = bind_media_m(airlock_nat(MAX_REC_FUEL), d, c, r, vault, lh, colw, i)

implement prep_doc(d, c, r, vault, lh, colw) = let
  val () = bind_media(d, c, r, vault, lh, colw, 0)
in
  doc_layout(d, lh)
end

fun kind_col(k: NodeKind): uint =
  if is_heading(k) then col_heading()
  else if is_kind(k, KWiki) orelse is_kind(k, KEmbed) orelse is_kind(k, KLink) then col_link()
  else if is_kind(k, KTag) then col_tag()
  else if is_kind(k, KHigh) then col_hightxt()
  else if is_kind(k, KBold) then col_white()
  else if is_kind(k, KItalic) then col_accent()
  else if is_kind(k, KStrike) then col_muted()
  else if is_kind(k, KMath) orelse is_kind(k, KMathb) then col_math()
  else if is_kind(k, KCode) then col_code()
  else if is_kind(k, KQuote) then col_quote()
  else if is_kind(k, KTask) then col_task()
  else if is_kind(k, KFm) then col_fm()
  else if is_kind(k, KFn) orelse is_kind(k, KFndef) then col_accent()
  else col_text()

fun is_box(k: NodeKind): bool =
  is_kind(k, KPara) orelse is_heading(k) orelse is_kind(k, KLi) orelse is_kind(k, KQuote) orelse is_kind(k, KCode) orelse is_kind(k, KTable) orelse is_kind(k, KTask) orelse is_kind(k, KFndef) orelse is_kind(k, KFm)


extern fun text_end_exh(d: !Doc, j: int, b: int): int = "mac#anth_die_int"

fun text_end_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, j: int, b: int): int =
  if recfuel > 0 then (
    if ilt(j, b) andalso ine(doc_byte(d, j), 10) then text_end_m(recfuel - 1, d, iadd(j, 1), b)
    else j
  ) else text_end_exh(d, j, b)

fun text_run_end(d: !Doc, i0: int, b: int): int =
  text_end_m(airlock_nat(MAX_REC_FUEL), d, i0, b)

fun draw_bytes_prefix_width(f: !Font, r: !Rend, d: !Doc, a: int, scratch: &Buf >> _): int = let
  val line0 = doc_line_of(d, a)
  val ls0 = doc_line_start(d, line0)
  val scap = buf_cap(scratch)
  val n_pre = if igt(a, ls0) then doc_slice_buf(d, ls0, a, scratch, scap) else 0
in
  if igt(n_pre, 0) then font_width_buf(f, r, scratch, n_pre) else 0
end

fun draw_bytes_run(f: !Font, r: !Rend, d: !Doc, i0: int, j: int, x0: int, oy: int, scroll: int, c: uint, scratch: &Buf >> _): int = let
  val scap = buf_cap(scratch)
  val n = doc_slice_buf(d, i0, j, scratch, scap)
  val y0 = isub(iadd(oy, doc_line_y(d, doc_line_of(d, i0))), scroll)
in
  font_draw_buf(f, r, x0, y0, scratch, n, c)
end

extern fun draw_bytes_exh(f: !Font, r: !Rend, d: !Doc, i0: int, b: int, x: int, x0: int, oy: int, scroll: int, c: uint, scratch: &Buf >> _): void = "mac#anth_die_void"

fun draw_bytes_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, i0: int, b: int, x: int, x0: int, oy: int, scroll: int, c: uint, scratch: &Buf >> _): void =
  if recfuel > 0 then (
    if ilt(i0, b) then
      if ieq(doc_byte(d, i0), 10) then draw_bytes_m(recfuel - 1, f, r, d, iadd(i0, 1), b, x, x, oy, scroll, c, scratch)
      else let
        val j = text_run_end(d, i0, b)
        val adv = draw_bytes_run(f, r, d, i0, j, x0, oy, scroll, c, scratch)
      in
        draw_bytes_m(recfuel - 1, f, r, d, j, b, x, iadd(x0, adv), oy, scroll, c, scratch)
      end
    else ()
  ) else draw_bytes_exh(f, r, d, i0, b, x, x0, oy, scroll, c, scratch)

fun draw_bytes(f: !Font, r: !Rend, d: !Doc, a: int, b: int, x: int, oy: int, scroll: int, c: uint, scratch: &Buf >> _): void = let
  val pre_w = draw_bytes_prefix_width(f, r, d, a, scratch)
in
  draw_bytes_m(airlock_nat(MAX_REC_FUEL), f, r, d, a, b, x, iadd(x, pre_w), oy, scroll, c, scratch)
end

extern fun paint_file_exh(f: !Font, r: !Rend, b: !Buf, n: int, nlines: int, x: int, lh: int, c: uint, i0: int, line: int, x0: int, y0: int): void = "mac#anth_die_void"

fun paint_file_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, b: !Buf, n: int, nlines: int, x: int, lh: int, c: uint, i0: int, line: int, x0: int, y0: int): void =
  if recfuel > 0 then (
    if ige(i0, n) orelse ige(line, nlines) then ()
    else if ieq(buf_get(b, i0), 10) then
      paint_file_m(recfuel - 1, f, r, b, n, nlines, x, lh, c, iadd(i0, 1), iadd(line, 1), x, iadd(y0, lh))
    else let
      val cap = buf_cap(b)
      val adv = font_draw_at(f, r, x0, y0, b, i0, 1, c)
    in
      paint_file_m(recfuel - 1, f, r, b, n, nlines, x, lh, c, iadd(i0, 1), line, iadd(x0, adv), y0)
    end
  ) else paint_file_exh(f, r, b, n, nlines, x, lh, c, i0, line, x0, y0)

fun paint_file(f: !Font, r: !Rend, b: !Buf, n: int, nlines: int, x: int, lh: int, c: uint, i0: int, line: int, x0: int, y0: int): void = paint_file_m(airlock_nat(MAX_REC_FUEL), f, r, b, n, nlines, x, lh, c, i0, line, x0, y0)

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


fun draw_plain_line(f: !Font, r: !Rend, d: !Doc, li: int, nlines: int, colx: int, oy: int, safe_lh: int, scroll: int, scratch: &Buf >> _): void = let
  val scap = buf_cap(scratch)
  val st = doc_line_start(d, li)
  val en0 = if ilt(iadd(li, 1), nlines) then doc_line_start(d, iadd(li, 1)) else doc_len(d)
  val en = if igt(en0, st) andalso ieq(doc_byte(d, isub(en0, 1)), 10) then isub(en0, 1) else en0
  val max_draw = imin(isub(en, st), 500)
  val n = if igt(max_draw, 0) then doc_slice_buf(d, st, iadd(st, max_draw), scratch, scap) else 0
  val yy = isub(iadd(oy, imul(li, safe_lh)), scroll)
  val () = seen_int(if igt(n, 0) then font_draw_buf(f, r, colx, yy, scratch, n, col_text()) else 0)
in
end

extern fun plain_lines_exh(f: !Font, r: !Rend, d: !Doc, li: int, li_end: int, nlines: int, colx: int, oy: int, safe_lh: int, scroll: int, scratch: &Buf >> _): void = "mac#anth_die_void"

fun plain_lines_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, li: int, li_end: int, nlines: int, colx: int, oy: int, safe_lh: int, scroll: int, scratch: &Buf >> _): void =
  if recfuel > 0 then (
    if ilt(li, li_end) then let
      val () = draw_plain_line(f, r, d, li, nlines, colx, oy, safe_lh, scroll, scratch)
    in
      plain_lines_m(recfuel - 1, f, r, d, iadd(li, 1), li_end, nlines, colx, oy, safe_lh, scroll, scratch)
    end else ()
  ) else plain_lines_exh(f, r, d, li, li_end, nlines, colx, oy, safe_lh, scroll, scratch)

fun draw_plain_doc(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, pw: int, ph: int, scroll: int, lh: int, scratch: &Buf >> _): void = let
  val nlines = doc_nlines(d)
  val safe_lh = if igt(lh, 0) then lh else 18
  val li_start = imax(0, idiv(scroll, safe_lh))
  val li_end = imin(nlines, iadd(idiv(iadd(scroll, ph), safe_lh), 2))
in
  plain_lines_m(airlock_nat(MAX_REC_FUEL), f, r, d, li_start, li_end, nlines, colx, oy, safe_lh, scroll, scratch)
end

extern fun count_before_exh(d: !Doc, a: int, p: int, k0: int): int = "mac#anth_die_int"

fun count_before_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, a: int, p: int, k0: int): int =
  if recfuel > 0 then (
    if ige(p, a) then k0
    else count_before_m(recfuel - 1, d, a, iadd(p, 1), (if ieq(doc_byte(d, p), 10) then iadd(k0, 1) else k0))
  ) else count_before_exh(d, a, p, k0)

fun count_before(d: !Doc, a: int, p: int, k0: int): int = count_before_m(airlock_nat(MAX_REC_FUEL), d, a, p, k0)

fun draw_arrow(f: !Font, r: !Rend, d: !Doc, i: int, k: NodeKind, colx: int, y: int): void =
  if is_heading(k) orelse is_kind(k, KLi) orelse is_kind(k, KTask) then let
    val folded = doc_node_collapsed(d, i)
    val arr = if is_on(folded) then ">" else "v"
    val acol = if is_on(folded) then col_accent() else col_muted()
    val () = draw_s(f, r, isub(colx, 16), y, arr, acol)
  in
  end else ()


fun view_run_adv(f: !Font, r: !Rend, d: !Doc, i0: int, j: int, colx: int, oy: int, scroll: int, lh: int, ph: int, c: uint, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): int = let
  val scap = buf_cap(scratch)
  val cur_line = doc_line_of(d, i0)
  val () = if ine(cur_line, pen_line) then (pen_line := cur_line; pen_x := colx) else ()
  val yy = isub(iadd(oy, doc_line_y(d, cur_line)), scroll)
  val n = doc_slice_buf(d, i0, j, scratch, scap)
in
  if igt(n, 0) then (
    if ilt(iadd(yy, lh), oy) orelse igt(yy, iadd(oy, ph)) then
      font_width_buf(f, r, scratch, n)
    else
      font_draw_buf(f, r, pen_x, yy, scratch, n, c)
  ) else 0
end

extern fun view_slice_exh(f: !Font, r: !Rend, d: !Doc, i0: int, b: int, colx: int, oy: int, scroll: int, lh: int, ph: int, c: uint, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _, total: int): int = "mac#anth_die_int"

fun view_slice_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, i0: int, b: int, colx: int, oy: int, scroll: int, lh: int, ph: int, c: uint, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _, total: int): int =
  if recfuel > 0 then (
    if ilt(i0, b) then
      if ieq(doc_byte(d, i0), 10) then let
        val () = pen_x := colx
        val () = pen_line := iadd(pen_line, 1)
      in
        view_slice_m(recfuel - 1, f, r, d, iadd(i0, 1), b, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line, total)
      end else let
        val j = text_run_end(d, i0, b)
        val adv = view_run_adv(f, r, d, i0, j, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line)
        val () = pen_x := iadd(pen_x, adv)
      in
        view_slice_m(recfuel - 1, f, r, d, j, b, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line, iadd(total, adv))
      end
    else total
  ) else view_slice_exh(f, r, d, i0, b, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line, total)

fun draw_view_slice(f: !Font, r: !Rend, d: !Doc, a: int, b: int, colx: int, oy: int, scroll: int, lh: int, ph: int, c: uint, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): int =
  view_slice_m(airlock_nat(MAX_REC_FUEL), f, r, d, a, b, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line, 0)

fun heading_scale(k: NodeKind, snum: &int >> _, sden: &int >> _): void =
  if is_kind(k, KH1) then (snum := 7; sden := 4)
  else if is_kind(k, KH2) then (snum := 3; sden := 2)
  else if is_kind(k, KH3) then (snum := 5; sden := 4)
  else if is_kind(k, KH4) then (snum := 23; sden := 20)
  else if is_kind(k, KH5) then (snum := 11; sden := 10)
  else (snum := 1; sden := 1)


extern fun skip_hash_exh(d: !Doc, st: int, b: int): int = "mac#anth_die_int"

fun skip_hash_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, st: int, b: int): int =
  if recfuel > 0 then (
    if ilt(st, b) andalso ieq(doc_byte(d, st), 35) then skip_hash_m(recfuel - 1, d, iadd(st, 1), b)
    else st
  ) else skip_hash_exh(d, st, b)

extern fun skip_gap_exh(d: !Doc, st: int, b: int): int = "mac#anth_die_int"

fun skip_gap_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, st: int, b: int): int =
  if recfuel > 0 then (
    if ilt(st, b) andalso (ieq(doc_byte(d, st), 32) orelse ieq(doc_byte(d, st), 9)) then skip_gap_m(recfuel - 1, d, iadd(st, 1), b)
    else st
  ) else skip_gap_exh(d, st, b)

extern fun trim_tail_exh(d: !Doc, en: int, st: int): int = "mac#anth_die_int"

fun trim_tail_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, en: int, st: int): int =
  if recfuel > 0 then (
    if igt(en, st) andalso (ieq(doc_byte(d, isub(en, 1)), 10) orelse ieq(doc_byte(d, isub(en, 1)), 13)) then trim_tail_m(recfuel - 1, d, isub(en, 1), st)
    else en
  ) else trim_tail_exh(d, en, st)

fun draw_heading_text(f: !Font, r: !Rend, d: !Doc, a: int, b: int, k: NodeKind, colx: int, yy: int, scratch: &Buf >> _): void = let
  var snum: int = 1
  var sden: int = 1
  val () = heading_scale(k, snum, sden)
  val st0 = skip_hash_m(airlock_nat(MAX_REC_FUEL), d, a, b)
  val st = skip_gap_m(airlock_nat(MAX_REC_FUEL), d, st0, b)
  val en_h = trim_tail_m(airlock_nat(MAX_REC_FUEL), d, b, st)
  val scap = buf_cap(scratch)
  val n = if igt(en_h, st) then doc_slice_buf(d, st, en_h, scratch, scap) else 0
in
  seen_int(if igt(n, 0) then font_draw_scaled_buf(f, r, colx, yy, scratch, n, col_heading(), snum, sden) else 0)
end

fun draw_node_heading(f: !Font, r: !Rend, d: !Doc, i: int, k: NodeKind,
                      oy: int, ph: int, scroll: int, lh: int, colx: int, y: int,
                      viewmode: ViewMode, scratch: &Buf >> _,
                      py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val () = py := y
  val a = doc_node_start(d, i)
  val b = doc_node_end(d, i)
  val () = pa := a
  val line = doc_line_of(d, a)
  val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
  val () = pen_line := line
  val () = pen_x := colx
in
  if ilt(iadd(yy, lh), oy) orelse igt(yy, iadd(oy, ph)) then ()
  else if is_view_read(viewmode) then draw_heading_text(f, r, d, a, b, k, colx, yy, scratch)
  else ()
end

fun draw_node_box(f: !Font, r: !Rend, d: !Doc, i: int, k: NodeKind,
                  oy: int, scroll: int, lh: int, colx: int, y: int, h: int,
                  scratch: &Buf >> _,
                  py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val () = py := y
  val a = doc_node_start(d, i)
  val b = doc_node_end(d, i)
  val () = pa := a
  val () = pen_line := ~1
  val () = pen_x := colx
in
  if is_kind(k, KCode) orelse is_kind(k, KFm) orelse is_kind(k, KFndef) then
    draw_bytes(f, r, d, a, b, colx, oy, scroll, kind_col(k), scratch)
  else if is_kind(k, KQuote) then
    rend_rect(r, isub(colx, 8), y, 3, imax(h, lh), col_quote())
  else ()
end


fun draw_image_quad(r: !Rend, c: &Cache >> _, shown: !Buf, pw: int, colx: int, y: int, h: int): void = let
  var iw: int = 0
  var ih: int = 0
  val tex = ensure_tex(c, shown, r, iw, ih)
  val dw = if ile(iw, 0) then 32 else imin(column_w(pw), imax(iw, 32))
  val dh = if ile(ih, 0) then h else imax(h, 9)
  val () = if ine(uok(tex), 0) then rend_quad(r, tex, ShadeRgba, colx, y, dw, dh, 0.0, 0.0, 1.0, 1.0, col_white()) else ()
in
end

fun draw_node_image(r: !Rend, d: !Doc, i: int, pw: int, colx: int, y: int, h: int,
                    vault: !Buf, c: &Cache >> _,
                    pen_x: &int >> _, pen_line: &int >> _): void = let
  val () = pen_line := ~1
  val () = pen_x := colx
  var rel = buf_make(8)
  var full = buf_make(8)
  var shown = buf_make(8)
  val () = resolve_media_path(d, i, vault, rel, full, shown)
  val () = draw_image_quad(r, c, shown, pw, colx, y, h)
  val () = buf_free(rel)
  val () = buf_free(full)
  val () = buf_free(shown)
in
end

fun draw_node_embed(f: !Font, r: !Rend, d: !Doc, i: int, colx: int, y: int, lh: int,
                    vault: !Buf, pen_x: &int >> _, pen_line: &int >> _): void = let
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
  val () = buf_free(shown)
in
end

extern fun skip_bracket_exh(d: !Doc, c: int, b: int): int = "mac#anth_die_int"

fun skip_bracket_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, c: int, b: int): int =
  if recfuel > 0 then (
    if ilt(c, b) andalso ine(doc_byte(d, c), 93) then skip_bracket_m(recfuel - 1, d, iadd(c, 1), b)
    else c
  ) else skip_bracket_exh(d, c, b)

fun draw_node_read_link(f: !Font, r: !Rend, d: !Doc, i: int, oy: int, ph: int, scroll: int,
                        lh: int, colx: int, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val a = doc_node_start(d, i)
  val b = doc_node_end(d, i)
  val st = iadd(a, 1)
  val c_br = skip_bracket_m(airlock_nat(MAX_REC_FUEL), d, st, b)
  val label_en = (if ilt(c_br, b) then c_br else b) : int
  val line = doc_line_of(d, st)
  val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
  val x0 = (if ine(line, pen_line) then colx else pen_x) : int
  val tw = draw_view_slice(f, r, d, st, label_en, colx, oy, scroll, lh, ph, col_link(), scratch, pen_x, pen_line)
in
  if igt(tw, 0) andalso ige(iadd(yy, lh), oy) andalso ile(yy, iadd(oy, ph)) then
    rend_rect(r, x0, iadd(yy, isub(lh, 2)), tw, 1, col_link())
  else ()
end


extern fun pipe_at_exh(d: !Doc, cur: int, en: int, found: int): int = "mac#anth_die_int"

fun pipe_at_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, cur: int, en: int, found: int): int =
  if recfuel > 0 then (
    if ilt(cur, en) then
      if ieq(doc_byte(d, cur), 124) then pipe_at_m(recfuel - 1, d, iadd(cur, 1), en, cur)
      else pipe_at_m(recfuel - 1, d, iadd(cur, 1), en, found)
    else found
  ) else pipe_at_exh(d, cur, en, found)

fun wiki_label_start(d: !Doc, st: int, en: int): int = let
  val p_pipe = pipe_at_m(airlock_nat(MAX_REC_FUEL), d, st, en, ~1)
in
  if ige(p_pipe, 0) then iadd(p_pipe, 1) else st
end

fun draw_node_read_wiki(f: !Font, r: !Rend, d: !Doc, i: int, oy: int, ph: int, scroll: int,
                        lh: int, colx: int, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val a = doc_node_start(d, i)
  val b = doc_node_end(d, i)
  val st = iadd(a, 2)
  val en = (if igt(b, 2) then isub(b, 2) else b) : int
  val label_st = wiki_label_start(d, st, en)
  val label_en = en
  val line = doc_line_of(d, label_st)
  val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
  val x0 = (if ine(line, pen_line) then colx else pen_x) : int
  val tw = draw_view_slice(f, r, d, label_st, label_en, colx, oy, scroll, lh, ph, col_link(), scratch, pen_x, pen_line)
in
  if igt(tw, 0) andalso ige(iadd(yy, lh), oy) andalso ile(yy, iadd(oy, ph)) then
    rend_rect(r, x0, iadd(yy, isub(lh, 2)), tw, 1, col_link())
  else ()
end

fun draw_node_read_high(f: !Font, r: !Rend, d: !Doc, i: int, oy: int, ph: int, scroll: int,
                        lh: int, colx: int, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val a = doc_node_start(d, i)
  val b = doc_node_end(d, i)
  val st = (if ile(iadd(a, 2), b) then iadd(a, 2) else a) : int
  val en = (if ige(isub(b, 2), st) then isub(b, 2) else b) : int
  val line = doc_line_of(d, st)
  val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
  val x0 = (if ine(line, pen_line) then colx else pen_x) : int
  val scap = buf_cap(scratch)
  val n = if igt(en, st) then doc_slice_buf(d, st, en, scratch, scap) else 0
  val tw0 = if igt(n, 0) then font_width_buf(f, r, scratch, n) else 0
  val () = if igt(tw0, 0) andalso ige(iadd(yy, lh), oy) andalso ile(yy, iadd(oy, ph)) then
    rend_rect(r, x0, yy, tw0, lh, col_highbg())
  else ()
  val () = seen_int(draw_view_slice(f, r, d, st, en, colx, oy, scroll, lh, ph, col_hightxt(), scratch, pen_x, pen_line))
in
end

fun draw_node_read_bold(f: !Font, r: !Rend, d: !Doc, i: int, oy: int, ph: int, scroll: int,
                        lh: int, colx: int, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val a = doc_node_start(d, i)
  val b = doc_node_end(d, i)
  val st = (if ile(iadd(a, 2), b) then iadd(a, 2) else a) : int
  val en = (if ige(isub(b, 2), st) then isub(b, 2) else b) : int
  val () = seen_int(draw_view_slice(f, r, d, st, en, colx, oy, scroll, lh, ph, col_white(), scratch, pen_x, pen_line))
in
end

fun draw_node_read_italic(f: !Font, r: !Rend, d: !Doc, i: int, oy: int, ph: int, scroll: int,
                          lh: int, colx: int, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val a = doc_node_start(d, i)
  val b = doc_node_end(d, i)
  val st = (if ile(iadd(a, 1), b) then iadd(a, 1) else a) : int
  val en = (if ige(isub(b, 1), st) then isub(b, 1) else b) : int
  val () = seen_int(draw_view_slice(f, r, d, st, en, colx, oy, scroll, lh, ph, col_accent(), scratch, pen_x, pen_line))
in
end

fun draw_node_read_strike(f: !Font, r: !Rend, d: !Doc, i: int, oy: int, ph: int, scroll: int,
                          lh: int, colx: int, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val a = doc_node_start(d, i)
  val b = doc_node_end(d, i)
  val st = (if ile(iadd(a, 2), b) then iadd(a, 2) else a) : int
  val en = (if ige(isub(b, 2), st) then isub(b, 2) else b) : int
  val line = doc_line_of(d, st)
  val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
  val x0 = (if ine(line, pen_line) then colx else pen_x) : int
  val tw = draw_view_slice(f, r, d, st, en, colx, oy, scroll, lh, ph, col_muted(), scratch, pen_x, pen_line)
in
  if igt(tw, 0) andalso ige(iadd(yy, lh), oy) andalso ile(yy, iadd(oy, ph)) then
    rend_rect(r, x0, iadd(yy, idiv(lh, 2)), tw, 1, col_muted())
  else ()
end

fun draw_node_read_math(f: !Font, r: !Rend, d: !Doc, i: int, oy: int, ph: int, scroll: int,
                        lh: int, colx: int, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val a = doc_node_start(d, i)
  val b = doc_node_end(d, i)
  val st = (if ile(iadd(a, 1), b) then iadd(a, 1) else a) : int
  val en = (if ige(isub(b, 1), st) then isub(b, 1) else b) : int
  val () = seen_int(draw_view_slice(f, r, d, st, en, colx, oy, scroll, lh, ph, col_math(), scratch, pen_x, pen_line))
in
end


fun draw_node_read_text(f: !Font, r: !Rend, d: !Doc, i: int, k: NodeKind, oy: int, ph: int, scroll: int,
                        lh: int, colx: int, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val a = doc_node_start(d, i)
  val b = doc_node_end(d, i)
  val c = (if is_kind(k, KTag) then col_tag() else col_text()) : uint
  val () = seen_int(draw_view_slice(f, r, d, a, b, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line))
in
end

fun draw_node_read_inline(f: !Font, r: !Rend, d: !Doc, i: int, k: NodeKind, oy: int, ph: int, scroll: int,
                          lh: int, colx: int, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): void =
  if is_kind(k, KLink) then
    draw_node_read_link(f, r, d, i, oy, ph, scroll, lh, colx, scratch, pen_x, pen_line)
  else if is_kind(k, KWiki) then
    draw_node_read_wiki(f, r, d, i, oy, ph, scroll, lh, colx, scratch, pen_x, pen_line)
  else if is_kind(k, KHigh) then
    draw_node_read_high(f, r, d, i, oy, ph, scroll, lh, colx, scratch, pen_x, pen_line)
  else if is_kind(k, KBold) then
    draw_node_read_bold(f, r, d, i, oy, ph, scroll, lh, colx, scratch, pen_x, pen_line)
  else if is_kind(k, KItalic) then
    draw_node_read_italic(f, r, d, i, oy, ph, scroll, lh, colx, scratch, pen_x, pen_line)
  else if is_kind(k, KStrike) then
    draw_node_read_strike(f, r, d, i, oy, ph, scroll, lh, colx, scratch, pen_x, pen_line)
  else if is_kind(k, KMath) then
    draw_node_read_math(f, r, d, i, oy, ph, scroll, lh, colx, scratch, pen_x, pen_line)
  else
    draw_node_read_text(f, r, d, i, k, oy, ph, scroll, lh, colx, scratch, pen_x, pen_line)


fun edit_highlight_bg(f: !Font, r: !Rend, d: !Doc, a: int, b: int, oy: int, scroll: int, lh: int, colx: int, scratch: &Buf >> _): void = let
  val line = doc_line_of(d, a)
  val ls = doc_line_start(d, line)
  val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
  val scap = buf_cap(scratch)
  val n_pre = if igt(a, ls) then doc_slice_buf(d, ls, a, scratch, scap) else 0
  val pre_w = if igt(n_pre, 0) then font_width_buf(f, r, scratch, n_pre) else 0
  val n = doc_slice_buf(d, a, b, scratch, scap)
  val w_hi = font_width_buf(f, r, scratch, n)
  val () = rend_rect(r, iadd(colx, pre_w), yy, w_hi, lh, col_highbg())
in
end

fun draw_node_edit_fallback(f: !Font, r: !Rend, d: !Doc, i: int, k: NodeKind,
                            oy: int, ph: int, scroll: int, lh: int, colx: int,
                            scratch: &Buf >> _): void =
  if is_kind(k, KHigh) then let
    val a = doc_node_start(d, i)
    val b = doc_node_end(d, i)
    val () = edit_highlight_bg(f, r, d, a, b, oy, scroll, lh, colx, scratch)
  in
    draw_bytes(f, r, d, a, b, colx, oy, scroll, kind_col(k), scratch)
  end else let
    val a = doc_node_start(d, i)
    val b = doc_node_end(d, i)
    val yy = isub(iadd(oy, doc_line_y(d, doc_line_of(d, a))), scroll)
  in
    if ilt(iadd(yy, lh), oy) orelse igt(yy, iadd(oy, ph)) then ()
    else draw_bytes(f, r, d, a, b, colx, oy, scroll, kind_col(k), scratch)
  end


fun draw_node_content(f: !Font, r: !Rend, d: !Doc, i: int, k: NodeKind, oy: int, pw: int, ph: int, scroll: int,
                      lh: int, colx: int, y: int, h: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _,
                      py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: ViewMode): void =
  if is_heading(k) then
    draw_node_heading(f, r, d, i, k, oy, ph, scroll, lh, colx, y, viewmode, scratch, py, pa, pen_x, pen_line)
  else if is_box(k) then
    draw_node_box(f, r, d, i, k, oy, scroll, lh, colx, y, h, scratch, py, pa, pen_x, pen_line)
  else if is_kind(k, KHr) then (
    pen_line := ~1; pen_x := colx;
    rend_rect(r, colx, iadd(y, 4), column_w(pw), 2, col_line())
  )
  else if is_kind(k, KImage) then
    draw_node_image(r, d, i, pw, colx, y, h, vault, c, pen_x, pen_line)
  else if is_kind(k, KEmbed) then
    draw_node_embed(f, r, d, i, colx, y, lh, vault, pen_x, pen_line)
  else if is_view_read(viewmode) then
    draw_node_read_inline(f, r, d, i, k, oy, ph, scroll, lh, colx, scratch, pen_x, pen_line)
  else
    draw_node_edit_fallback(f, r, d, i, k, oy, ph, scroll, lh, colx, scratch)

fun draw_node(f: !Font, r: !Rend, d: !Doc, i: int, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: ViewMode): void = let
  val k = doc_node_kind(d, i)
  val y = isub(iadd(oy, doc_node_y(d, i)), scroll)
  val h = doc_node_height(d, i)
  val colx = column_x(ox, pw)
  val hidden = doc_node_hidden(d, i)
  val p_idx = doc_node_parent(d, i)
  val p_k = if ige(p_idx, 0) then doc_node_kind(d, p_idx) else KNone
  val in_heading = is_heading(p_k)
in
  if is_on(hidden) orelse (in_heading andalso is_view_read(viewmode)) then ()
  else let
    val () = draw_arrow(f, r, d, i, k, colx, y)
  in
    draw_node_content(f, r, d, i, k, oy, pw, ph, scroll, lh, colx, y, h, vault, c, scratch, py, pa, pen_x, pen_line, viewmode)
  end
end

extern fun draw_nodes_impl_exh(f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: ViewMode): void = "mac#anth_die_void"

fun draw_nodes_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: ViewMode): void =
  if recfuel > 0 then (
    if ige(i, doc_nnodes(d)) then ()
    else let
      val () = draw_node(f, r, d, i, ox, oy, pw, ph, scroll, lh, vault, c, scratch, py, pa, pen_x, pen_line, viewmode)
    in
      draw_nodes_impl_m(recfuel - 1, f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, iadd(i, 1), py, pa, pen_x, pen_line, viewmode)
    end
  ) else draw_nodes_impl_exh(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, i, py, pa, pen_x, pen_line, viewmode)

fun draw_nodes_impl(f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: ViewMode): void = draw_nodes_impl_m(airlock_nat(MAX_REC_FUEL), f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, i, py, pa, pen_x, pen_line, viewmode)

fun caret_xy(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _, x: &int >> _, y: &int >> _): void = let
  val caret = doc_caret(d)
  val line = doc_line_of(d, caret)
  val ls = doc_line_start(d, line)
  val scap = buf_cap(scratch)
  val n = doc_slice_buf(d, ls, caret, scratch, scap)
  val adv = font_width_buf(f, r, scratch, n)
  val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
  val () = x := iadd(colx, adv)
  val () = seen_int(lh)
in
  y := yy
end

fun draw_sel_line(f: !Font, r: !Rend, d: !Doc, ls: int, le: int, smin: int, smax: int, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void = let
  val a = imax(ls, smin)
  val b = imin(le, smax)
in
  if ilt(a, b) then let
    val scap = buf_cap(scratch)
    val na = doc_slice_buf(d, ls, a, scratch, scap)
    val wa = font_width_buf(f, r, scratch, na)
    val nb = doc_slice_buf(d, ls, b, scratch, scap)
    val wb = font_width_buf(f, r, scratch, nb)
    val line = doc_line_of(d, ls)
    val sy = isub(iadd(oy, doc_line_y(d, line)), scroll)
    val sx = iadd(colx, wa)
    val sw = imax(isub(wb, wa), 4)
  in
    rend_rect(r, sx, sy, sw, lh, col_sel())
  end else ()
end


extern fun sel_lines_exh(f: !Font, r: !Rend, d: !Doc, li: int, l1: int, smin: int, smax: int, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void = "mac#anth_die_void"

fun sel_lines_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, li: int, l1: int, smin: int, smax: int, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void =
  if recfuel > 0 then (
    if ile(li, l1) andalso ilt(li, doc_nlines(d)) then let
      val ls = doc_line_start(d, li)
      val le = if ilt(iadd(li, 1), doc_nlines(d)) then doc_line_start(d, iadd(li, 1)) else doc_len(d)
      val () = draw_sel_line(f, r, d, ls, le, smin, smax, colx, oy, scroll, lh, scratch)
    in
      sel_lines_m(recfuel - 1, f, r, d, iadd(li, 1), l1, smin, smax, colx, oy, scroll, lh, scratch)
    end else ()
  ) else sel_lines_exh(f, r, d, li, l1, smin, smax, colx, oy, scroll, lh, scratch)

fun draw_sel_lines(f: !Font, r: !Rend, d: !Doc, l0: int, l1: int, smin: int, smax: int, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void =
  sel_lines_m(airlock_nat(MAX_REC_FUEL), f, r, d, l0, l1, smin, smax, colx, oy, scroll, lh, scratch)

fun draw_selection(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void = let
  val caret = doc_caret(d)
  val anchor = doc_anchor(d)
in
  if ine(caret, anchor) then let
    val smin = imin(caret, anchor)
    val smax = imax(caret, anchor)
    val l0 = doc_line_of(d, smin)
    val l1 = doc_line_of(d, smax)
  in
    draw_sel_lines(f, r, d, l0, l1, smin, smax, colx, oy, scroll, lh, scratch)
  end else ()
end


fun draw_caret(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void = let
  var cx: int = 0
  var cy: int = 0
  val () = caret_xy(f, r, d, colx, oy, scroll, lh, scratch, cx, cy)
  val bar = if igt(lh, 0) then lh else 1
  val () = rend_rect(r, cx, cy, 2, bar, col_caret())
in
end

fun draw_doc_content(f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, viewmode: ViewMode, colx: int, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _): void =
  if doc_nnodes(d) > 0 then
    draw_nodes_impl(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, 0, py, pa, pen_x, pen_line, viewmode)
  else
    draw_plain_doc(f, r, d, colx, oy, pw, ph, scroll, lh, scratch)

implement draw_doc(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, viewmode) = let
  val height = prep_doc(d, c, r, vault, lh, column_w(pw))
  var py: int = oy
  var pa: int = 0
  val colx = column_x(ox, pw)
  var pen_x: int = colx
  var pen_line: int = ~1
  val () = rend_scissor(r, ox, oy, pw, ph)
  val () = draw_selection(f, r, d, colx, oy, scroll, lh, scratch)
  val () = draw_doc_content(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, viewmode, colx, py, pa, pen_x, pen_line)
  val () = if is_view_edit(viewmode) then draw_caret(f, r, d, colx, oy, scroll, lh, scratch) else ()
  val () = rend_scissor_off(r)
  val () = if igt(height, ph) then ui_scroll_bar(r, isub(iadd(ox, pw), 6), oy, 6, ph, Vertical, height, ph, scroll, Off, Off) else ()
  val () = seen_int(py)
  val () = seen_int(pa)
in
end


fun tab_item_width(f: !Font, r: !Rend, title: !Buf): int = let
  val tlen = buf_len(title)
  val tw = if igt(tlen, 0) then font_width_buf(f, r, title, tlen) else 0
in
  imin(200, imax(100, iadd(tw, 36)))
end

fun draw_tab_frame(f: !Font, r: !Rend, title: !Buf, bx: int, tab_w: int, i: int, active: int): void = let
  val tlen = buf_len(title)
  val bg = if ieq(i, active) then col_bg() else col_side()
  val () = rend_rect(r, bx, 4, tab_w, 28, bg)
  val () = ui_draw_border(r, bx, 4, tab_w, 28, 1, if ieq(i, active) then col_line() else col_bar())
  val () = if ieq(i, active) then rend_rect(r, bx, 4, tab_w, 2, col_accent()) else ()
  val text_w = isub(tab_w, 32)
  val () = rend_scissor(r, iadd(bx, 8), 4, text_w, 28)
  val () = seen_int(font_draw_buf(f, r, iadd(bx, 8), 8, title, tlen, if ieq(i, active) then col_white() else col_text()))
  val () = rend_scissor_off(r)
  val close_x = isub(iadd(bx, tab_w), 18)
  val () = ui_draw_icon(f, r, UI_ICON_CLOSE, close_x, 14, 8, col_muted())
in
end

extern fun draw_tabrow_impl_exh(f: !Font, r: !Rend, ts: Tabs, x: int, active: int, i: int): Tabs = "mac#anth_die_box"

fun draw_tabrow_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, ts: Tabs, x: int, active: int, i: int): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val tab_w = tab_item_width(f, r, title)
        val bx = x
        val next_x = iadd(bx, iadd(tab_w, 4))
        val () = draw_tab_frame(f, r, title, bx, tab_w, i, active)
        val () = touch_doc(doc)
        val () = seen_int(sc)
        val rest2 = draw_tabrow_impl_m(recfuel - 1, f, r, rest, next_x, active, iadd(i, 1))
      in
        TCons(doc, path, title, sc, rest2)
      end
  ) else draw_tabrow_impl_exh(f, r, ts, x, active, i)

fun draw_tabrow_impl(f: !Font, r: !Rend, ts: Tabs, x: int, active: int, i: int): Tabs = draw_tabrow_impl_m(airlock_nat(MAX_REC_FUEL), f, r, ts, x, active, i)

implement draw_tabrow(f, r, ts, x, active, i) = draw_tabrow_impl(f, r, ts, x, active, i)

extern fun tab_hit_test_impl_exh(f: !Font, r: !Rend, ts: !Tabs, x: int, click_x: int, i: int, out_ti: &int >> _, out_close: &bool >> _): void = "mac#anth_die_void"

fun tab_hit_test_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, ts: !Tabs, x: int, click_x: int, i: int, out_ti: &int >> _, out_close: &bool >> _): void =
  if recfuel > 0 then (
    case+ ts of
    | TNil() => ()
    | TCons(_, _, title, _, rest) => let
        val tlen = buf_len(title)
        val tw = if igt(tlen, 0) then font_width_buf(f, r, title, tlen) else 0
        val tab_w = imin(200, imax(100, iadd(tw, 36)))
        val close_x = isub(iadd(x, tab_w), 24)
      in
        if ige(click_x, x) andalso ilt(click_x, iadd(x, tab_w)) then (
          out_ti := i;
          out_close := ige(click_x, close_x)
        ) else (
          tab_hit_test_impl_m(recfuel - 1, f, r, rest, iadd(x, iadd(tab_w, 4)), click_x, iadd(i, 1), out_ti, out_close)
        )
      end
  ) else tab_hit_test_impl_exh(f, r, ts, x, click_x, i, out_ti, out_close)

fun tab_hit_test_impl(f: !Font, r: !Rend, ts: !Tabs, x: int, click_x: int, i: int, out_ti: &int >> _, out_close: &bool >> _): void = tab_hit_test_impl_m(airlock_nat(MAX_REC_FUEL), f, r, ts, x, click_x, i, out_ti, out_close)

implement tab_hit_test(f, r, ts, start_x, click_x, out_ti, out_close) =
  tab_hit_test_impl(f, r, ts, start_x, click_x, 0, out_ti, out_close)

fun seal_cs(c: &Cache >> _, scratch: &Buf >> _): void = let
  val saved = c
  val () = c := saved
in
  seen_buf(scratch)
end

extern fun draw_focus_impl_exh(f: !Font, r: !Rend, ts: Tabs, idx: int, ox: int, oy: int, pw: int, ph: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, viewmode: ViewMode): Tabs = "mac#anth_die_box"

fun draw_focus_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, ts: Tabs, idx: int, ox: int, oy: int, pw: int, ph: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, viewmode: ViewMode): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => let
        val () = seal_cs(c, scratch)
      in
        TNil()
      end
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(i, idx) then draw_doc(f, r, doc, ox, oy, pw, ph, sc, lh, vault, c, scratch, viewmode) else seal_cs(c, scratch)
        val rest2 = draw_focus_impl_m(recfuel - 1, f, r, rest, idx, ox, oy, pw, ph, lh, vault, c, scratch, iadd(i, 1), viewmode)
      in
        TCons(doc, path, title, sc, rest2)
      end
  ) else draw_focus_impl_exh(f, r, ts, idx, ox, oy, pw, ph, lh, vault, c, scratch, i, viewmode)

fun draw_focus_impl(f: !Font, r: !Rend, ts: Tabs, idx: int, ox: int, oy: int, pw: int, ph: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, viewmode: ViewMode): Tabs = draw_focus_impl_m(airlock_nat(MAX_REC_FUEL), f, r, ts, idx, ox, oy, pw, ph, lh, vault, c, scratch, i, viewmode)

implement draw_right(f, r, ts, split, idx, ox, oy, pw, ph, lh, vault, c, scratch, viewmode) =
  if is_on(split) then draw_focus(f, r, ts, idx, ox, oy, pw, ph, lh, vault, c, scratch, 0, viewmode)
  else let
    val () = seal_cs(c, scratch)
  in
    ts
  end

implement draw_focus(f, r, ts, idx, ox, oy, pw, ph, lh, vault, c, scratch, i, viewmode) = draw_focus_impl(f, r, ts, idx, ox, oy, pw, ph, lh, vault, c, scratch, i, viewmode)

extern fun node_covering_impl_exh(d: !Doc, y: int, oy: int, scroll: int, i: int, best: int): int = "mac#anth_die_int"

fun node_covering_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, y: int, oy: int, scroll: int, i: int, best: int): int =
  if recfuel > 0 then (
    if ige(i, doc_nnodes(d)) then best
    else let
      val sy = isub(iadd(oy, doc_node_y(d, i)), scroll)
      val h = doc_node_height(d, i)
      val best2 = if igt(h, 0) andalso ige(y, sy) andalso ilt(y, iadd(sy, h)) then i else best
    in
      node_covering_impl_m(recfuel - 1, d, y, oy, scroll, iadd(i, 1), best2)
    end
  ) else node_covering_impl_exh(d, y, oy, scroll, i, best)

fun node_covering_impl(d: !Doc, y: int, oy: int, scroll: int, i: int, best: int): int = node_covering_impl_m(airlock_nat(MAX_REC_FUEL), d, y, oy, scroll, i, best)

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


fun click_char_width(f: !Font, r: !Rend, d: !Doc, i0: int, clen: int, scratch: &Buf >> _): int = let
  val scap = buf_cap(scratch)
  val n = doc_slice_buf(d, i0, iadd(i0, clen), scratch, scap)
in
  imax(font_width_buf(f, r, scratch, n), 1)
end

extern fun click_walk_exh(f: !Font, r: !Rend, d: !Doc, i0: int, len: int, pen: int, x: int, scratch: &Buf >> _): int = "mac#anth_die_int"

fun click_walk_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, i0: int, len: int, pen: int, x: int, scratch: &Buf >> _): int =
  if recfuel > 0 then (
    if ilt(i0, len) andalso ine(doc_byte(d, i0), 10) andalso ilt(pen, x) then let
      val clen = utf8_char_sz(d, i0, len)
      val cw = click_char_width(f, r, d, i0, clen, scratch)
    in
      if pen + cw / 2 >= x then i0
      else click_walk_m(recfuel - 1, f, r, d, iadd(i0, clen), len, iadd(pen, cw), x, scratch)
    end else i0
  ) else click_walk_exh(f, r, d, i0, len, pen, x, scratch)

fun click_place(f: !Font, r: !Rend, d: !Doc, x: int, ls: int, colx: int, scratch: &Buf >> _, keep: Toggle): void = let
  val i0 = click_walk_m(airlock_nat(MAX_REC_FUEL), f, r, d, ls, doc_len(d), colx, x, scratch)
in
  if is_on(keep) then doc_set_caret_extend(d, i0) else doc_set_caret_move(d, i0)
end

extern fun line_y_bsearch_exh(d: !Doc, docy: int, lo: int, hi: int, best: int): int = "mac#anth_die_int"

fun line_y_bsearch_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, docy: int, lo: int, hi: int, best: int): int =
  if recfuel > 0 then (
    if igt(lo, hi) then best
    else let
      val mid = iadd(lo, idiv(isub(hi, lo), 2))
      val ly = doc_line_y(d, mid)
    in
      if ile(ly, docy) then line_y_bsearch_m(recfuel - 1, d, docy, iadd(mid, 1), hi, mid)
      else line_y_bsearch_m(recfuel - 1, d, docy, lo, isub(mid, 1), best)
    end
  ) else line_y_bsearch_exh(d, docy, lo, hi, best)

fun line_y_bsearch(d: !Doc, docy: int, lo: int, hi: int, best: int): int = line_y_bsearch_m(airlock_nat(MAX_REC_FUEL), d, docy, lo, hi, best)

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

fun click_doc(f: !Font, r: !Rend, d: !Doc, x: int, y: int, ox: int, pw: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _, keep: Toggle, hitk: &NodeKind >> _, hiti: &int >> _): void = let
  val ni = node_covering_impl(d, y, oy, scroll, 0, ~1)
  val hk = if ige(ni, 0) then doc_node_kind(d, ni) else KNone
  val () = hitk := hk
  val () = hiti := ni
  val docy = iadd(isub(y, oy), scroll)
  val line0 = line_at_y_fast(d, docy, lh)
  val ls = doc_line_start(d, imax(0, line0))
  val colx = column_x(ox, pw)
  val () = seen_int(lh)
in
  if ige(ni, 0) andalso (is_kind(hk, KImage) orelse is_kind(hk, KEmbed)) then doc_set_caret_move(d, doc_node_start(d, ni))
  else click_place(f, r, d, x, ls, colx, scratch, keep)
end

fun click_if(f: !Font, r: !Rend, doc: !Doc, x: int, y: int, ox: int, pw: int, sc: int, lh: int, scratch: &Buf >> _, keep: Toggle, hitk: &NodeKind >> _, hiti: &int >> _, go: Toggle): void =
  if is_on(go) then click_doc(f, r, doc, x, y, ox, pw, 36, sc, lh, scratch, keep, hitk, hiti) else touchb(scratch)

fun click_stop(rest: Tabs, scratch: &Buf >> _): Tabs = let
  val () = touchb(scratch)
in
  rest
end

extern fun tabs_click_impl_exh(f: !Font, r: !Rend, ts: Tabs, idx: int, x: int, y: int, ox: int, pw: int, scroll_hint: int, lh: int, scratch: &Buf >> _, keep: Toggle, hitk: &NodeKind >> _, hiti: &int >> _, i: int): Tabs = "mac#anth_die_box"

fun tabs_click_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, ts: Tabs, idx: int, x: int, y: int, ox: int, pw: int, scroll_hint: int, lh: int, scratch: &Buf >> _, keep: Toggle, hitk: &NodeKind >> _, hiti: &int >> _, i: int): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = click_if(f, r, doc, x, y, ox, pw, sc, lh, scratch, keep, hitk, hiti, toggle_of(ieq(i, idx)))
      in
        if ieq(i, idx) then TCons(doc, path, title, sc, click_stop(rest, scratch)) else TCons(doc, path, title, sc, tabs_click_impl_m(recfuel - 1, f, r, rest, idx, x, y, ox, pw, scroll_hint, lh, scratch, keep, hitk, hiti, iadd(i, 1)))
      end
  ) else tabs_click_impl_exh(f, r, ts, idx, x, y, ox, pw, scroll_hint, lh, scratch, keep, hitk, hiti, i)

fun tabs_click_impl(f: !Font, r: !Rend, ts: Tabs, idx: int, x: int, y: int, ox: int, pw: int, scroll_hint: int, lh: int, scratch: &Buf >> _, keep: Toggle, hitk: &NodeKind >> _, hiti: &int >> _, i: int): Tabs = tabs_click_impl_m(airlock_nat(MAX_REC_FUEL), f, r, ts, idx, x, y, ox, pw, scroll_hint, lh, scratch, keep, hitk, hiti, i)

implement tabs_click(f, r, ts, idx, x, y, ox, pw, scroll_hint, lh, scratch, keep, hitk, hiti, i) = tabs_click_impl(f, r, ts, idx, x, y, ox, pw, scroll_hint, lh, scratch, keep, hitk, hiti, i)

implement draw_nodes(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, i, py, pa, viewmode) = let
  var px: int = column_x(ox, pw)
  var pl: int = ~1
in
  draw_nodes_impl(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, i, py, pa, px, pl, viewmode)
end
