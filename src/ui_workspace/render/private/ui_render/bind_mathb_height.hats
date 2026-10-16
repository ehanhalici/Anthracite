fun bind_mathb_height(d: !Doc, i: int, lh: int): void = let
  val dh = iadd(lh, 12)
  val old_h = doc_node_height(d, i)
  val () = if ine(old_h, dh) then doc_bump_ver(d) else ()
in
  doc_set(d, i, NF_HEIGHT, dh);
  doc_set(d, i, NF_AUX, dh)
end

fun bind_one_kind(f: !Font,d: !Doc, i: int, k: NodeKind, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int, shown: !Buf): void =
  if is_kind(k, KImage) then bind_image_height(d, i, c, r, shown, colw)
  else if is_kind(k, KEmbed) then bind_embed_height(f,d, i, c, r, vault, shown, lh, colw)
  else if is_kind(k, KMathb) then bind_mathb_height(d, i, lh)
  else ()

fun bind_one(f: !Font,d: !Doc, i: int, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int): void = let
  val k = doc_node_kind(d, i)
in
  if is_kind(k, KImage) orelse is_kind(k, KEmbed) then let
    var rel = buf_make(BIND_ONE_REL_INITIAL_BYTES)
    var full = buf_make(BIND_ONE_FULL_INITIAL_BYTES)
    var shown = buf_make(BIND_ONE_SHOWN_INITIAL_BYTES)
    val () = resolve_media_path(d, i, vault, rel, full, shown)
    val () = bind_one_kind(f,d, i, k, c, r, vault, lh, colw, shown)
    val () = buf_free(rel)
    val () = buf_free(full)
  in
    buf_free(shown)
  end else if is_kind(k, KMathb) then let
    var dummy = buf_make(BIND_ONE_DUMMY_INITIAL_BYTES)
    val () = bind_one_kind(f,d, i, k, c, r, vault, lh, colw, dummy)
  in
    buf_free(dummy)
  end else ()
end

extern fun bind_media_fuel_exhausted(f: !Font,d: !Doc, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int, i: int): void = "mac#anth_die_void"

fun bind_media_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font,d: !Doc, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, doc_nnodes(d)) then ()
    else let
      val () = bind_one(f,d, i, c, r, vault, lh, colw)
    in
      bind_media_with_fuel(recfuel - 1, f,d, c, r, vault, lh, colw, iadd(i, 1))
    end
  ) else bind_media_fuel_exhausted(f,d, c, r, vault, lh, colw, i)

fun bind_media(f: !Font,d: !Doc, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int, i: int): void = bind_media_with_fuel(airlock_nat(MAX_REC_FUEL), f,d, c, r, vault, lh, colw, i)

implement prepare_document_layout(f,d, c, r, vault, lh, colw, viewmode) = let
  val () = bind_media(f,d, c, r, vault, lh, colw, 0)
  val ()=visual_layout_prepare(f,r,d,colw,viewmode)
  val is_read = (if is_view_read(viewmode) then 1 else 0)
  val height=doc_layout_mode(d,lh,is_read,colw)
  val ()=doc_visual_index(d)
in height
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


extern fun text_end_fuel_exhausted(d: !Doc, j: int, b: int): int = "mac#anth_die_int"

fun text_end_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, j: int, b: int): int =
  if recfuel > 0 then (
    if ilt(j, b) andalso ine(doc_byte(d, j), CHAR_LF) then text_end_with_fuel(recfuel - 1, d, iadd(j, 1), b)
    else j
  ) else text_end_fuel_exhausted(d, j, b)

fun text_run_end(d: !Doc, i0: int, b: int): int =
  text_end_with_fuel(airlock_nat(MAX_REC_FUEL), d, i0, b)

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

extern fun draw_bytes_fuel_exhausted(f: !Font, r: !Rend, d: !Doc, i0: int, b: int, x: int, x0: int, oy: int, scroll: int, c: uint, scratch: &Buf >> _): void = "mac#anth_die_void"

fun draw_bytes_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, i0: int, b: int, x: int, x0: int, oy: int, scroll: int, c: uint, scratch: &Buf >> _): void =
  if recfuel > 0 then (
    if ilt(i0, b) then
      if ieq(doc_byte(d, i0), CHAR_LF) then draw_bytes_with_fuel(recfuel - 1, f, r, d, iadd(i0, 1), b, x, x, oy, scroll, c, scratch)
      else let
        val j = text_run_end(d, i0, b)
        val adv = draw_bytes_run(f, r, d, i0, j, x0, oy, scroll, c, scratch)
      in
        draw_bytes_with_fuel(recfuel - 1, f, r, d, j, b, x, iadd(x0, adv), oy, scroll, c, scratch)
      end
    else ()
  ) else draw_bytes_fuel_exhausted(f, r, d, i0, b, x, x0, oy, scroll, c, scratch)

fun draw_bytes(f: !Font, r: !Rend, d: !Doc, a: int, b: int, x: int, oy: int, scroll: int, c: uint, scratch: &Buf >> _): void = let
  val line0 = doc_line_of(d, a)
  val x0 = line_base_pos(f, r, d, line0, x, scratch)
  val pre_w = draw_bytes_prefix_width(f, r, d, a, scratch)
in
  draw_bytes_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, d, a, b, x0, iadd(x0, pre_w), oy, scroll, c, scratch)
end

extern fun buf_find_nl_fuel_exhausted(b: !Buf, n: int, i: int): int = "mac#anth_die_int"

fun buf_find_nl_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), b: !Buf, n: int, i: int
): int =
  if recfuel > 0 then (
    if ige(i, n) then n
    else if ieq(buf_get(b, i), CHAR_LF) then i
    else buf_find_nl_with_fuel(recfuel - 1, b, n, iadd(i, 1))
  ) else buf_find_nl_fuel_exhausted(b, n, i)

extern fun paint_file_fuel_exhausted(f: !Font, r: !Rend, b: !Buf, n: int, nlines: int, x: int, lh: int, c: uint, i0: int, line: int, y0: int): void = "mac#anth_die_void"

fun paint_file_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, b: !Buf, n: int, nlines: int,
  x: int, lh: int, c: uint, i0: int, line: int, y0: int
): void =
  if recfuel > 0 then (
    if ige(i0, n) orelse ige(line, nlines) then ()
    else let
      val eol = buf_find_nl_with_fuel(airlock_nat(MAX_REC_FUEL), b, n, i0)
      val len = isub(eol, i0)
      val () = if igt(len, 0) then let
        val _ = font_draw_at(f, r, x, y0, b, i0, len, c)
      in () end else ()
      val next_i0 = if ilt(eol, n) andalso ieq(buf_get(b, eol), CHAR_LF) then iadd(eol, 1) else eol
    in
      paint_file_with_fuel(recfuel - 1, f, r, b, n, nlines, x, lh, c, next_i0, iadd(line, 1), iadd(y0, lh))
    end
  ) else paint_file_fuel_exhausted(f, r, b, n, nlines, x, lh, c, i0, line, y0)

fun paint_file(f: !Font, r: !Rend, b: !Buf, n: int, nlines: int, x: int, lh: int, c: uint, i0: int, line: int, x0: int, y0: int): void = let
  val () = seen_int(line)
  val () = seen_int(x0)
in
  paint_file_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, b, n, nlines, x, lh, c, i0, 0, y0)
end

fun draw_file_lines(f: !Font, r: !Rend, path: !Buf, x: int, y: int, lh: int, nlines: int, c: uint): void = let
  val p = buffer_c_string(path)
  val sz = fs_size(p)
in
  if sz <= 0 orelse sz > 50000000 then ()
  else let
    val fd = fs_open_read(p)
    var b = buf_make(iadd(sz, 1))
    val n0 = read_available_file_bytes(b, fd, sz)
    val () = if fd >= 0 then fs_close(fd) else ()
    val n = if igt(n0, 0) then n0 else 0
    val () = buf_set_len(b, n)
    val () = paint_file(f, r, b, n, nlines, x, lh, c, 0, 0, x, y)
  in
    buf_free(b)
  end
end



extern fun line_y_bsearch_fuel_exhausted(d: !Doc, docy: int, lo: int, hi: int, best: int): int = "mac#anth_die_int"

fun line_y_bsearch_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, docy: int, lo: int, hi: int, best: int): int =
  if recfuel > 0 then (
    if igt(lo, hi) then best
    else let
      val mid = iadd(lo, idiv(isub(hi, lo), 2))
      val ly = doc_line_y(d, mid)
    in
      if ile(ly, docy) then line_y_bsearch_with_fuel(recfuel - 1, d, docy, iadd(mid, 1), hi, mid)
      else line_y_bsearch_with_fuel(recfuel - 1, d, docy, lo, isub(mid, 1), best)
    end
  ) else line_y_bsearch_fuel_exhausted(d, docy, lo, hi, best)
