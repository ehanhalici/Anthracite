fun heading_top_pad(k: NodeKind): int =
  if is_kind(k, KH1) then 14
  else if is_kind(k, KH2) then 10
  else if is_kind(k, KH3) then 8
  else if is_kind(k, KH4) then 6
  else if is_kind(k, KH5) then 4
  else 0

fun draw_heading_text(f: !Font, r: !Rend, d: !Doc, a: int, b: int, k: NodeKind, colx: int, yy: int, scratch: &Buf >> _): void = let
  var snum: int = 1
  var sden: int = 1
  val () = heading_scale(k, snum, sden)
  val st0 = skip_hash_with_fuel(airlock_nat(MAX_REC_FUEL), d, a, b)
  val st = skip_gap_with_fuel(airlock_nat(MAX_REC_FUEL), d, st0, b)
  val en_h = trim_tail_with_fuel(airlock_nat(MAX_REC_FUEL), d, b, st)
  val scap = buf_cap(scratch)
  val n = if igt(en_h, st) then doc_slice_buf(d, st, en_h, scratch, scap) else 0
  val pad_y = iadd(yy, heading_top_pad(k))
  val is_rtl = if igt(n, 0) then ui_text_line_direction_code(f, scratch, n) else 0
  val wc = doc_get_wrap(d)
  val max_w = if wc > 0 then imul(wc, UI_WRAP_CELL_WIDTH) else 720
  val raw_w = if igt(n, 0) then font_width_buf(f, r, scratch, n) else 0
  val tw = if igt(sden, 0) then idiv(imul(raw_w, snum), sden) else raw_w
  val hx = if igt(is_rtl, 0) then iadd(colx, imax(0, isub(max_w, tw))) else colx
in
  seen_int(if igt(n, 0) then font_draw_scaled_buf(f, r, hx, pad_y, scratch, n, col_heading(), snum, sden) else 0)
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
  val () = pen_line := pen_pack(line, 0)
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


fun draw_image_quad(r: !Rend, c: &Cache >> _, shown: !Buf, pw: int, colx: int, y: int, h: int, req_w: int, req_h: int): void = let
  var iw: int = 0
  var ih: int = 0
  val tex = ensure_tex(c, shown, r, iw, ih)
  val dw = calc_image_dw(iw, req_w, column_w(pw))
  val dh = (if igt(h, 0) then h else calc_image_dh(ih, iw, req_h, dw))
  val () = if ine(texture_is_valid(tex), 0) then rend_quad(r, tex, ShadeRgba, colx, y, dw, dh, 0.0, 0.0, 1.0, 1.0, col_white())
           else let
             val () = rend_rect(r, colx, y, 160, imin(dh, 48), col_side())
             val () = ui_draw_border(r, colx, y, 160, imin(dh, 48), 1, col_line())
           in
           end
in
end

fun draw_node_image(r: !Rend, d: !Doc, i: int, pw: int, colx: int, y: int, h: int,
                    vault: !Buf, c: &Cache >> _,
                    pen_x: &int >> _, pen_line: &int >> _): void = let
  val () = pen_line := ~1
  val () = pen_x := colx
  var rel = buf_make(DRAW_NODE_IMAGE_REL_INITIAL_BYTES)
  var full = buf_make(DRAW_NODE_IMAGE_FULL_INITIAL_BYTES)
  var shown = buf_make(DRAW_NODE_IMAGE_SHOWN_INITIAL_BYTES)
  val () = resolve_media_path(d, i, vault, rel, full, shown)
  val @(req_w, req_h) = image_requested_size(d, i)
  val () = draw_image_quad(r, c, shown, pw, colx, y, h, req_w, req_h)
  val () = buf_free(rel)
  val () = buf_free(full)
  val () = buf_free(shown)
in
end

fun draw_missing_embed(f: !Font, r: !Rend, x: int, y: int): void = let
  val () = rend_rect(r, x, y, 160, 24, col_side())
  val () = ui_draw_border(r, x, y, 160, 24, 1, col_line())
in
  draw_s(f, r, iadd(x, 8), iadd(y, 4), "[Icerik bulunamadi]", col_muted())
end

extern fun first_vis_node(d: !Doc,scroll: int): int
extern fun draw_embed_selection(f: !Font,r: !Rend,cache: !Cache,parent: !Doc,node: int,child: !Doc,
  colx: int,oy: int,scroll: int,lh: int,ph: int,scratch: &Buf >> _): void
fun draw_embed_contents(f: !Font,r: !Rend,child: !Doc,target: AnchorTarget,x: int,y: int,width: int,height: int,
  viewport_y: int,viewport_h: int,lh: int,vault: !Buf,c: &Cache >> _,scratch: &Buf >> _): void = let
  val top=imax(y,viewport_y) val bottom=imin(iadd(y,height),iadd(viewport_y,viewport_h))
  val scroll=iadd(doc_line_y(child,doc_line_of(child,target.start)),isub(top,y))
  val colx=editor_colx(f,r,x,width) var previous_y: int=top var previous_offset: int=target.start
in if ile(bottom,top) then () else if not(target.found) then draw_missing_embed(f,r,x,y)
  else if igt(doc_nnodes(child),0) then
    draw_nodes(f,r,child,x,top,width,isub(bottom,top),scroll,lh,vault,c,scratch,first_vis_node(child,scroll),previous_y,previous_offset,ViewRead)
  else draw_plain_doc(f,r,child,colx,top,width,isub(bottom,top),scroll,lh,scratch)
end

fun draw_embedded_doc(f: !Font, r: !Rend, parent: !Doc,node: int,child: !Doc,path: !Buf,anchor: !Buf, scope: EmbedScope, child_colw: int, x: int, y: int, w: int, h: int,
                      viewport_x: int, viewport_y: int, viewport_w: int, viewport_h: int,
                      lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _): void = let
  val colx = editor_colx(f, r, x, child_colw)
  val width=if font_text_active(f) then imax(1,isub(iadd(x,w),iadd(colx,16))) else child_colw
  val height=prepare_embedded_view(f,child,c,r,vault,path,lh,width,scope,anchor)
  val target=embedded_target(child,scope,anchor)
  val content_height=embedded_target_height(child,target,lh)
  val content_y = iadd(y, 4)
  val content_h = imax(lh, isub(h, 8))
  val () = rend_rect(r, x, y, w, h, col_side())
  val () = ui_draw_border(r, x, y, w, h, 1, col_line())
  val () = rend_clip_push(r, x, content_y, w, content_h)
  val ()=draw_embed_selection(f,r,c,parent,node,child,colx,content_y,doc_line_y(child,doc_line_of(child,target.start)),lh,content_h,scratch)
  val ()=draw_embed_contents(f,r,child,target,x,content_y,child_colw,imin(content_h,content_height),viewport_y,viewport_h,lh,vault,c,scratch)
  val () = rend_clip_pop(r)
in
  ()
end

fun draw_embedded_path(parent: !Doc,node: int,shown: !Buf, anchor: !Buf, scope: EmbedScope, level: int, child_colw: int, f: !Font, r: !Rend, x: int, y: int, w: int, h: int,
                       vx: int, vy: int, vw: int, vh: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _): void =
  if igt(level, MAX_EMBED_DEPTH) then draw_missing_embed(f, r, x, y)
  else let
    val p_str = buf_cstr(shown)
    val mt = embedded_source_stamp(p_str)
  in
    if not(mt.file.exists) then draw_missing_embed(f, r, x, y)
    else let
      val @(child, is_loaded) = obtain_embed_doc(c, shown, p_str, mt, level)
    in
      if is_loaded then let
        val () = draw_embedded_doc(f,r,parent,node,child,shown,anchor,scope,child_colw,x,y,w,h,vx,vy,vw,vh,lh,vault,c,scratch)
        val () = save_embed_cache(c, shown, mt, child, child_colw, lh)
      in
        ()
      end else (doc_free(child); draw_missing_embed(f, r, x, y))
    end
  end

fun resolve_embed_paths(d: !Doc,i: int,vault: !Buf): @(Buf,Buf,Buf,Buf) = let
  var shown: Buf=buf_make(DRAW_NODE_EMBED_SHOWN_INITIAL_BYTES)
  var rel: Buf=buf_make(DRAW_NODE_EMBED_REL_INITIAL_BYTES)
  var full: Buf=buf_make(DRAW_NODE_EMBED_FULL_INITIAL_BYTES)
  var anchor: Buf=buf_make(DRAW_NODE_EMBED_ANCHOR_INITIAL_BYTES)
  val ()=take_path(d,i,rel)
  val ()=take_anchor(d,i,anchor)
  val ()=resolve_path(vault,rel,full)
  val ()=with_md(full,shown)
in @(shown,rel,full,anchor) end

fun release_embed_paths(shown: Buf,rel: Buf,full: Buf,anchor: Buf): void = let
  val ()=buf_free(rel)
  val ()=buf_free(full)
  val ()=buf_free(shown)
in buf_free(anchor) end

fun draw_node_embed(f: !Font, r: !Rend, d: !Doc, i: int, ox: int, oy: int, pw: int, ph: int, scroll: int,
                    colx: int, y: int, h: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _,
                    pen_x: &int >> _, pen_line: &int >> _): void = let
  val () = pen_line := ~1
  val () = pen_x := colx
  val dp = doc_node_depth(d, i)
  val box_x = if igt(dp, 0) then iadd(colx, imul(dp, 20)) else colx
  val box_y = isub(y, 4)
  val box_h = imax(iadd(lh, 8), h)
  val @(shown,rel,full,anchor)=resolve_embed_paths(d,i,vault)
  val level = iadd(doc_embed_level(d), 1)
  val scope = embed_scope(d, i)
  val box_w = if font_text_active(f) then imax(1,isub(doc_visual_width(d),imul(dp,20)))
    else embed_box_width(ox,pw,box_x)
  val child_colw = if font_text_active(f) then box_w else embed_child_width(column_w(pw))
  val () = draw_embedded_path(d,i,shown,anchor,scope,level,child_colw,f,r,box_x,box_y,box_w,box_h,ox,oy,pw,ph,lh,vault,c,scratch)
  val ()=release_embed_paths(shown,rel,full,anchor)
in
end
