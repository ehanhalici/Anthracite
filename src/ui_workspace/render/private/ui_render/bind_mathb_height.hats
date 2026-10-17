fun bind_mathb_height(d: !Doc, i: int, lh: int): void = let
  val dh = doc_math_block_height(lh)
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

fun media_in_view(d: !Doc,i: int): bool = let val range=doc_view_range(d)
in ilt(doc_node_start(d,i),range.finish) andalso igt(doc_node_end(d,i),range.start) end
fun bind_one(f: !Font,d: !Doc, i: int, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int): void =
  if not(media_in_view(d,i)) then () else let
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

fun media_index_append(index: &Buf >> _,node: int): void = let
  val length=buf_len(index) val ()=buf_ensure(index,iadd(length,WORD32_BYTES))
  val ()=buf_set32(index,idiv(length,WORD32_BYTES),node)
in buf_set_len(index,iadd(length,WORD32_BYTES)) end
fun media_index_fill{n:nat} .<n>. (left: int(n),d: !Doc,index: &Buf >> _,i: int): void =
  if left = 0 then () else let val k=doc_node_kind(d,i)
    val ()=if is_kind(k,KImage) orelse is_kind(k,KEmbed) orelse is_kind(k,KMathb) then media_index_append(index,i) else ()
  in media_index_fill(left-1,d,index,iadd(i,1)) end
fun media_index_prepare(d: !Doc,index: &Buf >> _): void =
  if ige(buf_len(index),WORD32_BYTES) andalso ieq(buf_get32(index,0),doc_parse_generation(d)) then () else let
    val ()=performance_note(PERF_MEDIA_INDEX_BUILDS,1)
    val ()=buf_ensure(index,WORD32_BYTES) val ()=buf_set_len(index,WORD32_BYTES)
    val ()=media_index_fill(airlock_nat(doc_nnodes(d)),d,index,0)
  in buf_set32(index,0,doc_parse_generation(d)) end
fun bind_media_index{n:nat} .<n>. (left: int(n),f: !Font,d: !Doc,c: &Cache >> _,r: !Rend,
  vault: !Buf,lh: int,colw: int,index: !Buf,i: int): void =
  if left = 0 then () else let
    val node=buf_get32(index,i) val previous=work_scope(c)
    val ()=if work_in_band(d,node,c) andalso not(is_on(doc_node_hidden(d,node))) then let
      val ()=work_focus(d,node,c)
    in bind_one(f,d,node,c,r,vault,lh,colw) end else ()
    val ()=work_set_scope(c,previous)
  in bind_media_index(left-1,f,d,c,r,vault,lh,colw,index,iadd(i,1)) end
fun bind_media(f: !Font,d: !Doc,c: &Cache >> _,r: !Rend,vault: !Buf,lh: int,colw: int,i: int): void = let
  var index=doc_media_take(d) val ()=media_index_prepare(d,index)
  val ()=bind_media_index(airlock_nat(isub(idiv(buf_len(index),WORD32_BYTES),1)),f,d,c,r,vault,lh,colw,index,1)
  val ()=buf_set32(index,0,doc_parse_generation(d))
in doc_media_put(d,index) end

fun prepare_layout_geometry(f: !Font,r: !Rend,d: !Doc,lh: int,colw: int,viewmode: ViewMode): int = let
  val ()=visual_layout_prepare(f,r,d,colw,viewmode)
  val is_read = (if is_view_read(viewmode) then 1 else 0)
  val height=doc_layout_mode(d,lh,is_read,colw)
in height
end
fun seed_media_index{n:nat} .<n>. (left: int(n),d: !Doc,index: !Buf,i: int,lh: int): void =
  if left = 0 then () else let
    val node=buf_get32(index,i) val k=doc_node_kind(d,node)
    val estimate=if is_kind(k,KEmbed) then iadd(imul(lh,EMBED_ESTIMATED_LINES),EMBED_FRAME_PADDING_PIXELS)
      else if is_kind(k,KMathb) then doc_math_block_height(lh) else imul(lh,EMBED_ESTIMATED_LINES)
    val ()=if media_in_view(d,node) andalso not(is_on(doc_node_hidden(d,node))) andalso ile(doc_node_height(d,node),0) then
      (doc_set(d,node,NF_HEIGHT,estimate);doc_set(d,node,NF_AUX,estimate);doc_bump_ver(d)) else ()
  in seed_media_index(left-1,d,index,iadd(i,1),lh) end
fun seed_media(d: !Doc,lh: int): void = let
  var index=doc_media_take(d) val ()=media_index_prepare(d,index)
  val ()=seed_media_index(airlock_nat(isub(idiv(buf_len(index),WORD32_BYTES),1)),d,index,1,lh)
in doc_media_put(d,index) end
extern fun prepare_visible_exhausted(): int = "mac#anth_die_int"
fun prepare_visible{n:nat} .<n>. (fuel: int(n),f: !Font,d: !Doc,cache: &Cache >> _,r: !Rend,
  vault: !Buf,lh: int,width: int,mode: ViewMode): int =
  if not(recursion_fuel_available(fuel)) then prepare_visible_exhausted() else let
    val version=doc_layout_version(d)
    val ()=bind_media(f,d,cache,r,vault,lh,width,0)
    val height=prepare_layout_geometry(f,r,d,lh,width,mode)
  in if ieq(version,doc_layout_version(d)) then height else prepare_visible(fuel-1,f,d,cache,r,vault,lh,width,mode) end
extern fun prepare_nearby_exhausted(): int = "mac#anth_die_int"
fun prepare_nearby{n:nat} .<n>. (fuel: int(n),f: !Font,d: !Doc,cache: &Cache >> _,r: !Rend,vault: !Buf,
  lh: int,width: int,mode: ViewMode): int =
  if not(recursion_fuel_available(fuel)) then prepare_nearby_exhausted() else let
  val previous=work_scope(cache)
  val version=doc_layout_version(d)
  val visible=prepare_visible(airlock_nat(MAX_REC_FUEL),f,d,cache,r,vault,lh,width,mode)
  var overscan: EmbedWorkScope=previous val ()=overscan.band := EmbedWorkOverscan()
  val ()=work_set_scope(cache,overscan)
  val ()=bind_media(f,d,cache,r,vault,lh,width,0)
  val background=prepare_layout_geometry(f,r,d,lh,width,mode)
  val ()=work_set_scope(cache,previous)
  val height=prepare_visible(airlock_nat(MAX_REC_FUEL),f,d,cache,r,vault,lh,width,mode)
in if ieq(version,doc_layout_version(d)) orelse cache_work_pending(cache) then height
  else prepare_nearby(fuel-1,f,d,cache,r,vault,lh,width,mode) end
fun prepare_scheduled(f: !Font,d: !Doc,cache: &Cache >> _,r: !Rend,vault: !Buf,
  lh: int,width: int,mode: ViewMode): int = let
  val ()=seed_media(d,lh)
  val initial=prepare_layout_geometry(f,r,d,lh,width,mode)
in prepare_nearby(airlock_nat(MAX_REC_FUEL),f,d,cache,r,vault,lh,width,mode) end
implement prepare_document_layout(f,d,cache,r,vault,lh,width,mode) = let
  val scope=work_scope(cache)
in if scope.active andalso scope.document = doc_identity(d) then prepare_scheduled(f,d,cache,r,vault,lh,width,mode)
  else let val ()=bind_media(f,d,cache,r,vault,lh,width,0)
    in prepare_layout_geometry(f,r,d,lh,width,mode) end end

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
  if recursion_fuel_available(recfuel) then (
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
  if recursion_fuel_available(recfuel) then (
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
  if recursion_fuel_available(recfuel) then (
    if ige(i, n) then n
    else if ieq(buf_get(b, i), CHAR_LF) then i
    else buf_find_nl_with_fuel(recfuel - 1, b, n, iadd(i, 1))
  ) else buf_find_nl_fuel_exhausted(b, n, i)

extern fun paint_file_fuel_exhausted(f: !Font, r: !Rend, b: !Buf, n: int, nlines: int, x: int, lh: int, c: uint, i0: int, line: int, y0: int): void = "mac#anth_die_void"

fun paint_file_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, b: !Buf, n: int, nlines: int,
  x: int, lh: int, c: uint, i0: int, line: int, y0: int
): void =
  if recursion_fuel_available(recfuel) then (
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
  if recursion_fuel_available(recfuel) then (
    if igt(lo, hi) then best
    else let
      val mid = iadd(lo, idiv(isub(hi, lo), 2))
      val ly = doc_line_y(d, mid)
    in
      if ile(ly, docy) then line_y_bsearch_with_fuel(recfuel - 1, d, docy, iadd(mid, 1), hi, mid)
      else line_y_bsearch_with_fuel(recfuel - 1, d, docy, lo, isub(mid, 1), best)
    end
  ) else line_y_bsearch_fuel_exhausted(d, docy, lo, hi, best)
