fun image_slice_size(d: !Doc, st: int, en: int): @(int, int) = let
  val pipe = find_last_pipe_with_fuel(airlock_nat(MAX_REC_FUEL), d, isub(en, 1), st)
  val parse_st = if ige(pipe, st) then iadd(pipe, 1) else st
in
  parse_image_size_str(d, parse_st, en)
end

fun trim_brackets(d: !Doc, st: int, en: int): int =
  if ige(isub(en, st), 2) andalso ieq(doc_byte(d, isub(en, 1)), CHAR_RBRACKET) andalso ieq(doc_byte(d, isub(en, 2)), CHAR_RBRACKET) then
    isub(en, 2)
  else if igt(en, st) andalso (ieq(doc_byte(d, isub(en, 1)), CHAR_RBRACKET) orelse ieq(doc_byte(d, isub(en, 1)), CHAR_RPAREN)) then
    isub(en, 1)
  else en

fun image_node_size_fallback(d: !Doc, i: int): @(int, int) = let
  val nst = doc_node_start(d, i)
  val nen = trim_brackets(d, nst, doc_node_end(d, i))
  val pipe = find_last_pipe_with_fuel(airlock_nat(MAX_REC_FUEL), d, isub(nen, 1), nst)
in
  if ige(pipe, nst) then image_slice_size(d, iadd(pipe, 1), nen) else @(0, 0)
end

fun image_requested_size(d: !Doc, i: int): @(int, int) = let
  val ka = doc_find_child(d, i, KWikiAlias)
in
  if ige(ka, 0) then
    image_slice_size(d, doc_node_start(d, ka), doc_node_end(d, ka))
  else let
    val kt = doc_find_child(d, i, KText)
  in
    if ige(kt, 0) then
      image_slice_size(d, doc_node_start(d, kt), doc_node_end(d, kt))
    else image_node_size_fallback(d, i)
  end
end

fun calc_image_dw(iw: int, req_w: int, max_w: int): int = let
  val base_w = (if igt(req_w, 0) then req_w else (if ile(iw, 0) then 32 else iw))
in
  imin(max_w, imax(base_w, 16))
end

fun calc_image_dh(ih: int, iw: int, req_h: int, dw: int): int =
  if igt(req_h, 0) then req_h
  else if ile(iw, 0) then 32
  else imax(9, idiv(imul(ih, dw), iw))

fun bind_image_height(d: !Doc, i: int, c: &Cache >> _, r: !Rend, shown: !Buf, colw: int): void = let
  var iw: int = 0
  var ih: int = 0
  val () = seen_uint(ensure_tex(c, shown, r, iw, ih))
  val @(req_w, req_h) = image_requested_size(d, i)
  val dw = calc_image_dw(iw, req_w, colw)
  val dh = calc_image_dh(ih, iw, req_h, dw)
  val old_h = doc_node_height(d, i)
  val () = if ine(old_h, dh) then doc_bump_ver(d) else ()
in
  doc_set(d, i, NF_HEIGHT, dh);
  doc_set(d, i, NF_AUX, dh)
end

datatype EmbedScope = EmbedWhole | EmbedBlock

fun embed_scope(d: !Doc, i: int): EmbedScope =
  if ige(doc_find_child(d, i, KWikiBlock), 0) then EmbedBlock else EmbedWhole

fun embed_child_width(parent_colw: int): int = imax(1, isub(parent_colw, UI_GUTTER_WIDTH))

fun embed_text_width(f: !Font,r: !Rend,parent: int): int =
  if font_text_active(f) then imax(1,isub(parent,editor_colx(f,r,0,iadd(parent,16))))
  else embed_child_width(parent)

fun embed_box_width(ox: int, pw: int, box_x: int): int =
  imax(1, imin(column_w(pw), isub(iadd(ox, pw), box_x)))

fun embed_anchor_offset(anchor: !Buf): int =
  if igt(buf_len(anchor), 0) andalso ieq(buf_get(anchor, 0), CHAR_CARET) then 1 else 0

extern fun block_id_match_fuel_exhausted(d: !Doc, anchor: !Buf, p: int, a: int): bool = "mac#anth_die_bool"

fun block_id_match_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, anchor: !Buf, p: int, a: int): bool =
  if recfuel > 0 then (
    if ige(a, buf_len(anchor)) then true
    else if ige(p, doc_len(d)) then false
    else if ieq(doc_byte(d, p), buf_get(anchor, a)) then block_id_match_with_fuel(recfuel - 1, d, anchor, iadd(p, 1), iadd(a, 1))
    else false
  ) else block_id_match_fuel_exhausted(d, anchor, p, a)

extern fun block_marker_find_fuel_exhausted(d: !Doc, anchor: !Buf, p: int): int = "mac#anth_die_int"

fun block_marker_boundary(d: !Doc, anchor: !Buf, p: int): bool = let
  val before = if igt(p, 0) then doc_byte(d, isub(p, 1)) else 10
  val before_ok = ieq(before, 10) orelse ieq(before, 32) orelse ieq(before, 9)
  val after = iadd(p, iadd(isub(buf_len(anchor), embed_anchor_offset(anchor)), 1))
  val after_byte = if ilt(after, doc_len(d)) then doc_byte(d, after) else 10
  val after_ok = ieq(after_byte, 10) orelse ieq(after_byte, 32) orelse ieq(after_byte, 9)
in
  before_ok andalso after_ok
end

fun block_marker_find_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, anchor: !Buf, p: int): int =
  if recfuel > 0 then (
    if ige(p, doc_len(d)) then ~1
    else if ieq(doc_byte(d, p), CHAR_CARET) andalso block_marker_boundary(d, anchor, p) andalso block_id_match_with_fuel(airlock_nat(MAX_REC_FUEL), d, anchor, iadd(p, 1), embed_anchor_offset(anchor)) then p
    else block_marker_find_with_fuel(recfuel - 1, d, anchor, iadd(p, 1))
  ) else block_marker_find_fuel_exhausted(d, anchor, p)

fun embed_block_line(d: !Doc, scope: EmbedScope, anchor: !Buf): int =
  case+ scope of
  | EmbedWhole() => ~1
  | EmbedBlock() => let
      val marker = block_marker_find_with_fuel(airlock_nat(MAX_REC_FUEL), d, anchor, 0)
    in
      if ige(marker, 0) then doc_line_of(d, marker) else ~1
    end

fun embedded_content_height(d: !Doc, scope: EmbedScope, anchor: !Buf, lh: int, full_height: int): int = let
  val line = embed_block_line(d, scope, anchor)
in
  if ilt(line, 0) then full_height
  else imax(lh, doc_line_step(d, line))
end

fun measure_embedded_height(f: !Font,child: Doc, c: &Cache >> _, r: !Rend, vault: !Buf, shown: !Buf, anchor: !Buf, scope: EmbedScope, level: int, lh: int, colw: int): int = let
in
  if igt(level, MAX_EMBED_DEPTH) then let
    val () = doc_free(child)
  in
    iadd(lh, 8)
  end
  else if embedded_doc_load(child, buf_cstr(shown), level) then let
    val height = prepare_document_layout(f,child, c, r, vault, lh, embed_text_width(f,r,colw), ViewRead)
    val content_height = embedded_content_height(child, scope, anchor, lh, height)
    val () = doc_free(child)
  in
    iadd(imax(lh, content_height), 8)
  end else let
    val () = doc_free(child)
  in
    lh
  end
end

fun embedded_height(f: !Font,d: !Doc, i: int, c: &Cache >> _, r: !Rend, vault: !Buf, shown: !Buf, lh: int, colw: int): int = let
  var anchor = buf_make(EMBEDDED_HEIGHT_ANCHOR_INITIAL_BYTES)
  val () = take_anchor(d, i, anchor)
  val scope = embed_scope(d, i)
  val level = iadd(doc_embed_level(d), 1)
  val height = measure_embedded_height(f,doc_open(), c, r, vault, shown, anchor, scope, level, lh, colw)
  val () = buf_free(anchor)
in
  height
end

fun resolve_embed_height(f: !Font, d: !Doc, i: int, c: &Cache >> _, r: !Rend, vault: !Buf, shown: !Buf, lh: int, width: int): int = let
  val p_str = buf_cstr(shown)
  var ch: int = 0
  val st = embed_fsm_query(p_str, width, lh, ch)
in
  if ieq(st, EMBED_STATE_CACHED) then ch
  else if ieq(st, EMBED_STATE_FAILED) then iadd(lh, 8)
  else let
    val h = embedded_height(f, d, i, c, r, vault, shown, lh, width)
    val () = if igt(h, 0) then embed_fsm_store(p_str, width, lh, h) else embed_fsm_fail(p_str, width, lh)
  in
    h
  end
end

fun bind_embed_height(f: !Font, d: !Doc, i: int, c: &Cache >> _, r: !Rend, vault: !Buf, shown: !Buf, lh: int, colw: int): void = let
  val width = isub(colw, imul(doc_node_depth(d, i), 20))
  val dh = resolve_embed_height(f, d, i, c, r, vault, shown, lh, width)
  val old_h = doc_node_height(d, i)
  val () = if ine(old_h, dh) then doc_bump_ver(d) else ()
in
  doc_set(d, i, NF_HEIGHT, dh);
  doc_set(d, i, NF_AUX, dh)
end

fun try_media_folder(vault: !Buf, sub: string, rel: !Buf, shown: &Buf >> _): bool = let
  val s = anth_check_media_folder(buffer_c_string(vault), sub, buffer_c_string(rel))
in
  if igt(c_strlen(s), 0) then let
    val () = buffer_clear(shown)
    val () = buffer_append_string(shown, s)
  in
    true
  end else false
end

fun try_media_folders(vault: !Buf, rel: !Buf, shown: &Buf >> _): void =
  if try_media_folder(vault, "attachments/", rel, shown) then ()
  else if try_media_folder(vault, "assets/", rel, shown) then ()
  else if try_media_folder(vault, "images/", rel, shown) then ()
  else ()

fun resolve_media_path(d: !Doc, i: int, vault: !Buf, rel: &Buf >> _, full: &Buf >> _, shown: &Buf >> _): void = let
  val () = take_path(d, i, rel)
  val () = resolve_path(vault, rel, full)
  val () = with_md(full, shown)
  val ok = fs_exists(buffer_c_string(shown))
in
  if ieq(ok, 0) andalso igt(buf_len(rel), 0) then let
    val rok = fs_exists(buffer_c_string(rel))
  in
    if ieq(rok, 1) then take_path(d, i, shown)
    else try_media_folders(vault, rel, shown)
  end else ()
end
