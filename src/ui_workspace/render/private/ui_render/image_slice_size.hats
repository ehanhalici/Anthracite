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

datatype EmbedScope = EmbedWhole | EmbedAnchored

fun embed_scope(d: !Doc, i: int): EmbedScope =
  if ige(doc_find_child(d,i,KWikiBlock),0) orelse ige(doc_find_child(d,i,KWikiHeading),0) then EmbedAnchored else EmbedWhole

fun embed_child_width(parent_colw: int): int = imax(1, isub(parent_colw, UI_GUTTER_WIDTH))

fun embed_text_width(f: !Font,r: !Rend,parent: int): int =
  if font_text_active(f) then imax(1,isub(parent,iadd(editor_colx(f,r,0,parent),16)))
  else embed_child_width(parent)

fun embed_box_width(ox: int, pw: int, box_x: int): int =
  imax(1, imin(column_w(pw), isub(iadd(ox, pw), box_x)))

fun embedded_target(d: !Doc,scope: EmbedScope,anchor: !Buf): AnchorTarget = case+ scope of
  | EmbedWhole() => @{found=true,start=0,finish=doc_len(d),marker=0}
  | EmbedAnchored() => doc_resolve_anchor(d,anchor)
fun embedded_target_height(d: !Doc,target: AnchorTarget,lh: int): int =
  if not(target.found) then lh else let
    val first=doc_line_of(d,target.start)
    val last=doc_line_of(d,imax(target.start,isub(target.finish,1)))
  in imax(lh,isub(iadd(doc_line_y(d,last),doc_line_step(d,last)),doc_line_y(d,first))) end
fun embedded_content_height(d: !Doc, scope: EmbedScope, anchor: !Buf, lh: int, full_height: int): int = let
  val target=embedded_target(d,scope,anchor)
in embedded_target_height(d,target,lh) end
fun prepare_embedded_view(f: !Font,doc: !Doc,cache: &Cache >> _,r: !Rend,vault: !Buf,
  path: !Buf,lh: int,width: int,scope: EmbedScope,anchor: !Buf): int = let
  val target=embedded_target(doc,scope,anchor)
  val ()=doc_set_view_range(doc,target.start,target.finish)
  val restored: bool=if font_text_active(f) then cache_view_restore(f,doc,cache,path,width) else false
  val allowed: bool=if restored then true else work_allow(cache)
in if allowed then let
    val previous=work_scope(cache)
    var scope: EmbedWorkScope=previous
    val ()=scope.document := doc_identity(doc)
    val ()=scope.anchorLine := doc_line_of(doc,target.start)
    val ()=scope.scroll := previous.childDelta
    val ()=scope.band := EmbedWorkVisible()
    val ()=work_set_scope(cache,scope)
    val height=prepare_document_layout(f,doc,cache,r,vault,lh,width,ViewRead)
    val ()=work_set_scope(cache,previous)
  in height end else ~1 end

fun measure_loaded_embed(f: !Font,c: &Cache >> _,r: !Rend,vault: !Buf,shown: !Buf,
  anchor: !Buf,scope: EmbedScope,level: int,lh: int,colw: int,stamp: EmbedSourceStamp): int = let
  val (child,loaded)=obtain_embed_doc(c,shown,buf_cstr(shown),stamp,level)
in if loaded then let
    val height=prepare_embedded_view(f,child,c,r,vault,shown,lh,embed_text_width(f,r,colw),scope,anchor)
    val content=if ilt(height,0) then ~1 else iadd(imax(lh,embedded_content_height(child,scope,anchor,lh,height)),EMBED_FRAME_PADDING_PIXELS)
    val ()=save_embed_cache(c,shown,stamp,child,colw,lh)
  in content end else let val ()=doc_free(child) in iadd(lh,EMBED_FRAME_PADDING_PIXELS) end end

fun measure_embedded_height(f: !Font,c: &Cache >> _,r: !Rend,vault: !Buf,shown: !Buf,
  anchor: !Buf,scope: EmbedScope,level: int,lh: int,colw: int): int =
  if igt(level,MAX_EMBED_DEPTH) then iadd(lh,8) else let
    val mtime=embedded_source_stamp(buf_cstr(shown))
  in if not(mtime.file.exists) then iadd(lh,EMBED_FRAME_PADDING_PIXELS)
    else if not(work_has_document(airlock_nat(MAX_REC_FUEL),c,shown,mtime)) andalso not(work_allow(c)) then ~1
    else measure_loaded_embed(f,c,r,vault,shown,anchor,scope,level,lh,colw,mtime) end

fun embedded_height(f: !Font,d: !Doc, i: int, c: &Cache >> _, r: !Rend, vault: !Buf, shown: !Buf, lh: int, colw: int): int = let
  var anchor = buf_make(EMBEDDED_HEIGHT_ANCHOR_INITIAL_BYTES)
  val () = take_anchor(d, i, anchor)
  val scope = embed_scope(d, i)
  val level = iadd(doc_embed_level(d), 1)
  val height = measure_embedded_height(f,c,r,vault,shown,anchor,scope,level,lh,colw)
  val () = buf_free(anchor)
in
  height
end

fun resolve_embed_height(f: !Font, d: !Doc, i: int, c: &Cache >> _, r: !Rend, vault: !Buf, shown: !Buf, lh: int, width: int): int = let
in embedded_height(f,d,i,c,r,vault,shown,lh,width) end

fun bind_embed_height(f: !Font, d: !Doc, i: int, c: &Cache >> _, r: !Rend, vault: !Buf, shown: !Buf, lh: int, colw: int): void = let
  val width = isub(colw, imul(doc_node_depth(d, i), 20))
  val dh = resolve_embed_height(f, d, i, c, r, vault, shown, lh, width)
  val old_h = doc_node_height(d, i)
  val () = if ige(dh,0) andalso ine(old_h, dh) then doc_bump_ver(d) else ()
in
  if ige(dh,0) then (doc_set(d,i,NF_HEIGHT,dh); doc_set(d,i,NF_AUX,dh)) else ()
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
