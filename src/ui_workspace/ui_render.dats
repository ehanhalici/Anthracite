#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "os/diag.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/font.sats"
staload "data_ast/doc.sats"
staload "data_ast/ast.sats"
staload "data_image/image.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_tab.sats"
staload "ui_workspace/ui_render.sats"
staload "ui_workspace/embedded_doc.sats"
staload "ui_workspace/embed_fsm.sats"
staload "ui_workspace/ui_widgets.sats"
staload "data_ast/doc_visual.sats"
staload "ui_workspace/visual_layout.sats"
staload "ui_workspace/visual_paint.sats"
staload "ui_workspace/visual_query.sats"
staload "data_font/font_text.sats"
staload "data_font/font_document_metrics.sats"
staload "ui_workspace/visual_decor.sats"

macdef UI_GUTTER_WIDTH = 44
macdef UI_WRAP_CELL_WIDTH = 9
macdef MAX_EMBED_DEPTH = 8

%{#
#include "data_font/arabic.cats"
%}

extern fun anth_ui_caret_adv(f: !Font, r: !Rend, line: ptr, line_len: int, off: int): int = "mac#anth_ui_caret_adv"
extern fun anth_ui_click_off(f: !Font, r: !Rend, line: ptr, line_len: int, target_x: int): int = "mac#anth_ui_click_off"
extern fun anth_ui_sel_span(f: !Font, r: !Rend, line: ptr, line_len: int, sa: int, sb: int, at_eol: int, out_sx: &int >> _, out_sw: &int >> _): void = "mac#anth_ui_sel_span"
staload "ui_workspace/ui_text_engine.sats"
extern fun anth_draw_wrap_arrow(f: !Font, r: !Rend, x: int, y: int, c: uint): void = "mac#anth_draw_wrap_arrow"
extern fun anth_resolve_vault_path(vault: string, rel: string): string = "mac#anth_resolve_vault_path"
extern fun anth_check_media_folder(vault: string, sub: string, rel: string): string = "mac#anth_check_media_folder"

fun iand(a: int, n: int): int = anth_iand(a, n)

fun row_base_pos(f: !Font, r: !Rend, d: !Doc, rst: int, ren: int, colx: int, scratch: &Buf >> _): int = let
  val scap = buf_cap(scratch)
  val rlen = if igt(ren, rst) then doc_slice_buf(d, rst, ren, scratch, scap) else 0
  val is_rtl = if igt(rlen, 0) then ui_text_line_direction_code(f, scratch, rlen) else 0
  val wc = doc_get_wrap(d)
  val max_w = if wc > 0 then imul(wc, UI_WRAP_CELL_WIDTH) else 720
  val tw = if igt(rlen, 0) then font_width_buf(f, r, scratch, rlen) else 0
in
  if igt(is_rtl, 0) then iadd(colx, imax(0, isub(max_w, tw))) else colx
end

fun line_base_pos(f: !Font, r: !Rend, d: !Doc, li: int, colx: int, scratch: &Buf >> _): int = let
  val ls = doc_line_start(d, li)
  val le0 = if ilt(iadd(li, 1), doc_nlines(d)) then doc_line_start(d, iadd(li, 1)) else doc_len(d)
  val le = if igt(le0, ls) andalso ieq(doc_byte(d, isub(le0, 1)), 10) then isub(le0, 1) else le0
in
  row_base_pos(f, r, d, ls, le, colx, scratch)
end

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
    | ~CEmbed(p, mt, doc, cw, lh, rest) => let
        val () = buf_free(p)
        val () = doc_free(doc)
        val () = seen_int(mt)
        val () = seen_int(cw)
        val () = seen_int(lh)
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
    | ~CEmbed(p, mt, doc, cw, lh, rest) => let
        val rest2 = cache_lookup_m(recfuel - 1, rest, path, tex, w, h, hit)
      in
        CEmbed(p, mt, doc, cw, lh, rest2)
      end
  ) else cache_lookup_exh(c, path, tex, w, h, hit)

fun cache_lookup(c: Cache, path: !Buf, tex: &uint >> _, w: &int >> _, h: &int >> _, hit: &Toggle >> _): Cache = cache_lookup_m(airlock_nat(MAX_REC_FUEL), c, path, tex, w, h, hit)

fun cache_put(c: Cache, path: Buf, tex: uint, w: int, h: int): Cache =
  CCons(path, tex, w, h, c)

#define MAX_EMBED_CACHE_ENTRIES 48

fun cache_take_embed_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), c: Cache, path: !Buf, cur_mt: int
): @(Option_vt(Doc), Cache) =
  if recfuel > 0 then (
    case+ c of
    | ~CNil() => @(None_vt(), CNil())
    | ~CCons(p, t, iw, ih, rest) => let
        val @(opt, rest2) = cache_take_embed_m(recfuel - 1, rest, path, cur_mt)
      in
        @(opt, CCons(p, t, iw, ih, rest2))
      end
    | ~CEmbed(p, mt, doc, cw, lh, rest) =>
        if beq(p, path, 0) then
          if ieq(mt, cur_mt) then let
            val () = (buf_free(p); seen_int(cw); seen_int(lh))
          in
            @(Some_vt(doc), rest)
          end else let
            val () = (buf_free(p); doc_free(doc); seen_int(cw); seen_int(lh))
          in
            cache_take_embed_m(recfuel - 1, rest, path, cur_mt)
          end
        else let
          val @(opt, rest2) = cache_take_embed_m(recfuel - 1, rest, path, cur_mt)
        in
          @(opt, CEmbed(p, mt, doc, cw, lh, rest2))
        end
  ) else @(None_vt(), c)

fun cache_take_embed(c: Cache, path: !Buf, cur_mt: int): @(Option_vt(Doc), Cache) =
  cache_take_embed_m(airlock_nat(MAX_REC_FUEL), c, path, cur_mt)

fun count_embeds_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), c: !Cache, acc: int): int =
  if recfuel > 0 then (
    case+ c of
    | CNil() => acc
    | CCons(_, _, _, _, rest) => count_embeds_m(recfuel - 1, rest, acc)
    | CEmbed(_, _, _, _, _, rest) => count_embeds_m(recfuel - 1, rest, iadd(acc, 1))
  ) else acc

fun trim_embeds_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), c: Cache, keep: int, cur: &int >> _): Cache =
  if recfuel > 0 then (
    case+ c of
    | ~CNil() => CNil()
    | ~CCons(p, t, iw, ih, rest) => let
        val rest2 = trim_embeds_m(recfuel - 1, rest, keep, cur)
      in
        CCons(p, t, iw, ih, rest2)
      end
    | ~CEmbed(p, mt, doc, cw, lh, rest) => let
        val idx = cur
        val () = cur := iadd(cur, 1)
      in
        if ilt(idx, keep) then let
          val rest2 = trim_embeds_m(recfuel - 1, rest, keep, cur)
        in
          CEmbed(p, mt, doc, cw, lh, rest2)
        end else let
          val () = (buf_free(p); doc_free(doc); seen_int(mt); seen_int(cw); seen_int(lh))
        in
          trim_embeds_m(recfuel - 1, rest, keep, cur)
        end
      end
  ) else c

fun cache_put_embed(c: Cache, path: Buf, mt: int, doc: Doc, cw: int, lh: int): Cache = let
  val n = count_embeds_m(airlock_nat(MAX_REC_FUEL), c, 0)
in
  if ige(n, MAX_EMBED_CACHE_ENTRIES) then let
    var cur: int = 0
    val c2 = trim_embeds_m(airlock_nat(MAX_REC_FUEL), c, isub(MAX_EMBED_CACHE_ENTRIES, 1), cur)
  in
    CEmbed(path, mt, doc, cw, lh, c2)
  end else
    CEmbed(path, mt, doc, cw, lh, c)
end

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

fun doc_buf_push_slice_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, st: int, en: int, i: int, dst: &Buf >> _): void =
  if recfuel > 0 then (
    if ilt(i, en) then let
      val () = buf_push(dst, doc_byte(d, i))
    in
      doc_buf_push_slice_m(recfuel - 1, d, st, en, iadd(i, 1), dst)
    end else ()
  ) else ()

implement take_path(d, i, dst) = let
  val () = bclear(dst)
  val kd = doc_find_child(d, i, KLinkDest)
  val kw = (if ilt(kd, 0) then doc_find_child(d, i, KWikiTarget) else ~1)
  val target = (if ige(kd, 0) then kd else kw)
in
  if ige(target, 0) then let
    val cs = doc_node_start(d, target)
    val ce = doc_node_end(d, target)
  in
    doc_buf_push_slice_m(airlock_nat(MAX_REC_FUEL), d, cs, ce, cs, dst)
  end else let
    val a0 = doc_node_start(d, i)
    val b0 = doc_node_end(d, i)
  in
    take_path_m(airlock_nat(MAX_REC_FUEL), d, ScanSeek(), a0, b0, dst)
  end
end

implement take_anchor(d, i, dst) = let
  val () = bclear(dst)
  val kb = doc_find_child(d, i, KWikiBlock)
  val kh = (if ilt(kb, 0) then doc_find_child(d, i, KWikiHeading) else ~1)
  val target = (if ige(kb, 0) then kb else kh)
in
  if ige(target, 0) then let
    val cs0 = doc_node_start(d, target)
    val ce = doc_node_end(d, target)
    val cs = (if ilt(cs0, ce) andalso ieq(doc_byte(d, cs0), 35) then iadd(cs0, 1) else cs0)
  in
    doc_buf_push_slice_m(airlock_nat(MAX_REC_FUEL), d, cs, ce, cs, dst)
  end else ()
end

implement resolve_path(vault, rel, dst) = let
  val () = bclear(dst)
  val s = anth_resolve_vault_path(cstr(vault), cstr(rel))
  val () = bstr(dst, s)
in
end

implement with_md(path, dst) = let
  val () = bclear(dst)
  val () = bcat(dst, path, 0, buf_len(path))
in
  bstr_if(dst, toggle_of(not(ends(path, ".md") orelse is_image_path(path))), ".md")
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


fun skip_spaces_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: int, en: int): int =
  if recfuel > 0 then (
    if ilt(p, en) then let
      val c = doc_byte(d, p)
    in
      if ieq(c, 32) orelse ieq(c, 9) then skip_spaces_m(recfuel - 1, d, iadd(p, 1), en)
      else p
    end else en
  ) else en

fun skip_spaces(d: !Doc, p: int, en: int): int =
  skip_spaces_m(airlock_nat(MAX_REC_FUEL), d, p, en)

fun parse_digits_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: int, en: int, acc: int): @(int, int) =
  if recfuel > 0 then (
    if ilt(p, en) then let
      val c = doc_byte(d, p)
    in
      if ige(c, 48) andalso ile(c, 57) then
        parse_digits_m(recfuel - 1, d, iadd(p, 1), en, iadd(imul(acc, 10), isub(c, 48)))
      else @(p, acc)
    end else @(en, acc)
  ) else @(p, acc)

fun parse_digits(d: !Doc, p: int, en: int): @(int, int) =
  parse_digits_m(airlock_nat(MAX_REC_FUEL), d, p, en, 0)

fun parse_image_dim(d: !Doc, p1: int, en: int, w: int): @(int, int) = let
  val p2 = skip_spaces(d, p1, en)
in
  if ilt(p2, en) then let
    val c = doc_byte(d, p2)
  in
    if ieq(c, 120) orelse ieq(c, 88) then let
      val p3 = skip_spaces(d, iadd(p2, 1), en)
      val @(p4, h) = parse_digits(d, p3, en)
      val p5 = skip_spaces(d, p4, en)
    in
      if ieq(p5, en) andalso igt(h, 0) then @(w, h)
      else @(w, 0)
    end else @(0, 0)
  end else if ieq(p2, en) then @(w, 0)
  else @(0, 0)
end

fun parse_image_size_str(d: !Doc, st: int, en: int): @(int, int) = let
  val p0 = skip_spaces(d, st, en)
in
  if ilt(p0, en) then let
    val c0 = doc_byte(d, p0)
  in
    if ieq(c0, 120) orelse ieq(c0, 88) then let
      val p1 = skip_spaces(d, iadd(p0, 1), en)
      val @(p2, h) = parse_digits(d, p1, en)
      val p3 = skip_spaces(d, p2, en)
    in
      if ieq(p3, en) andalso igt(h, 0) then @(0, h) else @(0, 0)
    end else let
      val @(p1, w) = parse_digits(d, p0, en)
    in
      if igt(w, 0) then parse_image_dim(d, p1, en, w) else @(0, 0)
    end
  end else @(0, 0)
end

fun find_last_pipe_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: int, st: int): int =
  if recfuel > 0 then (
    if ige(p, st) then (
      if ieq(doc_byte(d, p), 124) then p
      else find_last_pipe_m(recfuel - 1, d, isub(p, 1), st)
    ) else ~1
  ) else ~1

fun image_slice_size(d: !Doc, st: int, en: int): @(int, int) = let
  val pipe = find_last_pipe_m(airlock_nat(MAX_REC_FUEL), d, isub(en, 1), st)
  val parse_st = if ige(pipe, st) then iadd(pipe, 1) else st
in
  parse_image_size_str(d, parse_st, en)
end

fun trim_brackets(d: !Doc, st: int, en: int): int =
  if ige(isub(en, st), 2) andalso ieq(doc_byte(d, isub(en, 1)), 93) andalso ieq(doc_byte(d, isub(en, 2)), 93) then
    isub(en, 2)
  else if igt(en, st) andalso (ieq(doc_byte(d, isub(en, 1)), 93) orelse ieq(doc_byte(d, isub(en, 1)), 41)) then
    isub(en, 1)
  else en

fun image_node_size_fallback(d: !Doc, i: int): @(int, int) = let
  val nst = doc_node_start(d, i)
  val nen = trim_brackets(d, nst, doc_node_end(d, i))
  val pipe = find_last_pipe_m(airlock_nat(MAX_REC_FUEL), d, isub(nen, 1), nst)
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
  if igt(buf_len(anchor), 0) andalso ieq(buf_get(anchor, 0), 94) then 1 else 0

extern fun block_id_match_exh(d: !Doc, anchor: !Buf, p: int, a: int): bool = "mac#anth_die_bool"

fun block_id_match_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, anchor: !Buf, p: int, a: int): bool =
  if recfuel > 0 then (
    if ige(a, buf_len(anchor)) then true
    else if ige(p, doc_len(d)) then false
    else if ieq(doc_byte(d, p), buf_get(anchor, a)) then block_id_match_m(recfuel - 1, d, anchor, iadd(p, 1), iadd(a, 1))
    else false
  ) else block_id_match_exh(d, anchor, p, a)

extern fun block_marker_find_exh(d: !Doc, anchor: !Buf, p: int): int = "mac#anth_die_int"

fun block_marker_boundary(d: !Doc, anchor: !Buf, p: int): bool = let
  val before = if igt(p, 0) then doc_byte(d, isub(p, 1)) else 10
  val before_ok = ieq(before, 10) orelse ieq(before, 32) orelse ieq(before, 9)
  val after = iadd(p, iadd(isub(buf_len(anchor), embed_anchor_offset(anchor)), 1))
  val after_byte = if ilt(after, doc_len(d)) then doc_byte(d, after) else 10
  val after_ok = ieq(after_byte, 10) orelse ieq(after_byte, 32) orelse ieq(after_byte, 9)
in
  before_ok andalso after_ok
end

fun block_marker_find_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, anchor: !Buf, p: int): int =
  if recfuel > 0 then (
    if ige(p, doc_len(d)) then ~1
    else if ieq(doc_byte(d, p), 94) andalso block_marker_boundary(d, anchor, p) andalso block_id_match_m(airlock_nat(MAX_REC_FUEL), d, anchor, iadd(p, 1), embed_anchor_offset(anchor)) then p
    else block_marker_find_m(recfuel - 1, d, anchor, iadd(p, 1))
  ) else block_marker_find_exh(d, anchor, p)

fun embed_block_line(d: !Doc, scope: EmbedScope, anchor: !Buf): int =
  case+ scope of
  | EmbedWhole() => ~1
  | EmbedBlock() => let
      val marker = block_marker_find_m(airlock_nat(MAX_REC_FUEL), d, anchor, 0)
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
    val height = prep_doc(f,child, c, r, vault, lh, embed_text_width(f,r,colw), ViewRead)
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
  var anchor = buf_make(8)
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
  val s = anth_check_media_folder(cstr(vault), sub, cstr(rel))
in
  if igt(c_strlen(s), 0) then let
    val () = bclear(shown)
    val () = bstr(shown, s)
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
  val ok = fs_exists(cstr(shown))
in
  if ieq(ok, 0) andalso igt(buf_len(rel), 0) then let
    val rok = fs_exists(cstr(rel))
  in
    if ieq(rok, 1) then take_path(d, i, shown)
    else try_media_folders(vault, rel, shown)
  end else ()
end

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
    var rel = buf_make(8)
    var full = buf_make(8)
    var shown = buf_make(8)
    val () = resolve_media_path(d, i, vault, rel, full, shown)
    val () = bind_one_kind(f,d, i, k, c, r, vault, lh, colw, shown)
    val () = buf_free(rel)
    val () = buf_free(full)
  in
    buf_free(shown)
  end else if is_kind(k, KMathb) then let
    var dummy = buf_make(1)
    val () = bind_one_kind(f,d, i, k, c, r, vault, lh, colw, dummy)
  in
    buf_free(dummy)
  end else ()
end

extern fun bind_media_exh(f: !Font,d: !Doc, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int, i: int): void = "mac#anth_die_void"

fun bind_media_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font,d: !Doc, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int, i: int): void =
  if recfuel > 0 then (
    if ige(i, doc_nnodes(d)) then ()
    else let
      val () = bind_one(f,d, i, c, r, vault, lh, colw)
    in
      bind_media_m(recfuel - 1, f,d, c, r, vault, lh, colw, iadd(i, 1))
    end
  ) else bind_media_exh(f,d, c, r, vault, lh, colw, i)

fun bind_media(f: !Font,d: !Doc, c: &Cache >> _, r: !Rend, vault: !Buf, lh: int, colw: int, i: int): void = bind_media_m(airlock_nat(MAX_REC_FUEL), f,d, c, r, vault, lh, colw, i)

implement prep_doc(f,d, c, r, vault, lh, colw, viewmode) = let
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
  val line0 = doc_line_of(d, a)
  val x0 = line_base_pos(f, r, d, line0, x, scratch)
  val pre_w = draw_bytes_prefix_width(f, r, d, a, scratch)
in
  draw_bytes_m(airlock_nat(MAX_REC_FUEL), f, r, d, a, b, x0, iadd(x0, pre_w), oy, scroll, c, scratch)
end

extern fun buf_find_nl_exh(b: !Buf, n: int, i: int): int = "mac#anth_die_int"

fun buf_find_nl_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), b: !Buf, n: int, i: int
): int =
  if recfuel > 0 then (
    if ige(i, n) then n
    else if ieq(buf_get(b, i), 10) then i
    else buf_find_nl_m(recfuel - 1, b, n, iadd(i, 1))
  ) else buf_find_nl_exh(b, n, i)

extern fun paint_file_exh(f: !Font, r: !Rend, b: !Buf, n: int, nlines: int, x: int, lh: int, c: uint, i0: int, line: int, y0: int): void = "mac#anth_die_void"

fun paint_file_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, b: !Buf, n: int, nlines: int,
  x: int, lh: int, c: uint, i0: int, line: int, y0: int
): void =
  if recfuel > 0 then (
    if ige(i0, n) orelse ige(line, nlines) then ()
    else let
      val eol = buf_find_nl_m(airlock_nat(MAX_REC_FUEL), b, n, i0)
      val len = isub(eol, i0)
      val () = if igt(len, 0) then let
        val _ = font_draw_at(f, r, x, y0, b, i0, len, c)
      in () end else ()
      val next_i0 = if ilt(eol, n) andalso ieq(buf_get(b, eol), 10) then iadd(eol, 1) else eol
    in
      paint_file_m(recfuel - 1, f, r, b, n, nlines, x, lh, c, next_i0, iadd(line, 1), iadd(y0, lh))
    end
  ) else paint_file_exh(f, r, b, n, nlines, x, lh, c, i0, line, y0)

fun paint_file(f: !Font, r: !Rend, b: !Buf, n: int, nlines: int, x: int, lh: int, c: uint, i0: int, line: int, x0: int, y0: int): void = let
  val () = seen_int(line)
  val () = seen_int(x0)
in
  paint_file_m(airlock_nat(MAX_REC_FUEL), f, r, b, n, nlines, x, lh, c, i0, 0, y0)
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
  val () = seen_int(lh)
in
  if ile(n, 1) then 0
  else line_at_y(d, docy, 0, 0)
end

extern fun plain_rows_exh(f: !Font, r: !Rend, d: !Doc, st: int, en: int, colx: int, yy: int, safe_lh: int, wc: int, row: int, rows: int, scratch: &Buf >> _): void = "mac#anth_die_void"

fun plain_row_step(f: !Font, r: !Rend, d: !Doc, st: int, en: int, colx: int, yy: int, safe_lh: int, wc: int, row: int, rows: int, scratch: &Buf >> _): void = let
  val rst = (if wc > 0 then doc_advance_cps(d, st, en, imul(row, wc)) else st) : int
  val ren = (if wc > 0 then doc_advance_cps(d, rst, en, wc) else en) : int
  val base_x = row_base_pos(f, r, d, rst, ren, colx, scratch)
  val scap = buf_cap(scratch)
  val n = if igt(ren, rst) then doc_slice_buf(d, rst, ren, scratch, scap) else 0
  val row_y = iadd(yy, imul(row, safe_lh))
  val is_rtl = if igt(n, 0) then ui_text_line_direction_code(f, scratch, n) else 0
  val tw = if igt(n, 0) then font_width_buf(f, r, scratch, n) else 0
  val () = if igt(n, 0) then seen_int(font_draw_buf(f, r, base_x, row_y, scratch, n, col_text())) else ()
  val ax = if igt(is_rtl, 0) then imax(colx, isub(base_x, 12)) else iadd(base_x, tw)
in
  if ilt(iadd(row, 1), rows) then anth_draw_wrap_arrow(f, r, ax, row_y, col_muted()) else ()
end

fun plain_rows_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, st: int, en: int,
  colx: int, yy: int, safe_lh: int, wc: int, row: int, rows: int, scratch: &Buf >> _
): void =
  if recfuel > 0 then (
    if ilt(row, rows) then let
      val () = plain_row_step(f, r, d, st, en, colx, yy, safe_lh, wc, row, rows, scratch)
    in
      plain_rows_m(recfuel - 1, f, r, d, st, en, colx, yy, safe_lh, wc, iadd(row, 1), rows, scratch)
    end else ()
  ) else plain_rows_exh(f, r, d, st, en, colx, yy, safe_lh, wc, row, rows, scratch)

fun visual_measure_w(
  d: !Doc, i0: int, p: int, f: !Font, r: !Rend, scratch: &Buf >> _
): int = let
  val scap = buf_cap(scratch)
  val n = doc_slice_buf(d, i0, p, scratch, scap)
in
  if igt(n, 0) then font_width_buf(f, r, scratch, n) else 0
end

fun visual_fit_step(
  d: !Doc, i0: int, lo: int, hi: int, max_w: int,
  f: !Font, r: !Rend, scratch: &Buf >> _
): int = let
  val count = doc_codepoints(d, lo, hi)
  val half = idiv(count, 2)
in
  if ile(half, 0) then
    (if igt(visual_measure_w(d, i0, hi, f, r, scratch), max_w) then
      (if ieq(lo, i0) then doc_advance_cps(d, i0, hi, 1) else lo)
    else hi)
  else let
    val mid = doc_advance_cps(d, lo, hi, half)
    val w = visual_measure_w(d, i0, mid, f, r, scratch)
  in
    if igt(w, max_w) then ~mid else mid
  end
end

fun visual_fit_prefix_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i0: int, lo: int, hi: int,
  max_w: int, f: !Font, r: !Rend, scratch: &Buf >> _
): int =
  if recfuel > 0 then let
    val res = visual_fit_step(d, i0, lo, hi, max_w, f, r, scratch)
  in
    if ilt(res, 0) then
      visual_fit_prefix_m(recfuel - 1, d, i0, lo, ~res, max_w, f, r, scratch)
    else if ieq(res, lo) orelse ieq(res, hi) then res
    else
      visual_fit_prefix_m(recfuel - 1, d, i0, res, hi, max_w, f, r, scratch)
  end else (if ieq(lo, i0) then doc_advance_cps(d, i0, hi, 1) else lo)

fun plain_px_end(f: !Font, r: !Rend, d: !Doc, st: int, en: int, max_w: int, scratch: &Buf >> _): int = let
  val width = visual_measure_w(d, st, en, f, r, scratch)
in
  if igt(width, max_w) then visual_fit_prefix_m(airlock_nat(MAX_REC_FUEL), d, st, st, en, max_w, f, r, scratch) else en
end

extern fun plain_px_count_exh(f: !Font, r: !Rend, d: !Doc, st: int, en: int, max_w: int, scratch: &Buf >> _): int = "mac#anth_die_int"

fun plain_px_count_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, st: int, en: int, max_w: int, scratch: &Buf >> _
): int =
  if recfuel > 0 then
    if ige(st, en) then 0 else let
      val next = plain_px_end(f, r, d, st, en, max_w, scratch)
    in
      iadd(1, plain_px_count_m(recfuel - 1, f, r, d, next, en, max_w, scratch))
    end
  else plain_px_count_exh(f, r, d, st, en, max_w, scratch)

extern fun plain_px_draw_exh(f: !Font, r: !Rend, d: !Doc, st: int, en: int, colx: int, yy: int, lh: int, max_w: int, row: int, scratch: &Buf >> _): void = "mac#anth_die_void"

fun plain_px_draw_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, st: int, en: int,
  colx: int, yy: int, lh: int, max_w: int, row: int, scratch: &Buf >> _
): void =
  if recfuel > 0 then
    if ige(st, en) then () else let
      val next = plain_px_end(f, r, d, st, en, max_w, scratch)
      val base_x = row_base_pos(f, r, d, st, next, colx, scratch)
      val scap = buf_cap(scratch)
      val n = doc_slice_buf(d, st, next, scratch, scap)
      val tw = if igt(n, 0) then font_width_buf(f, r, scratch, n) else 0
      val row_y = iadd(yy, imul(row, lh))
      val is_rtl = if igt(n, 0) then ui_text_line_direction_code(f, scratch, n) else 0
      val ax = if igt(is_rtl, 0) then imax(colx, isub(base_x, 12)) else iadd(base_x, tw)
      val () = if igt(n, 0) then seen_int(font_draw_buf(f, r, base_x, row_y, scratch, n, col_text())) else ()
      val () = if ilt(next, en) then anth_draw_wrap_arrow(f, r, ax, row_y, col_muted()) else ()
    in
      plain_px_draw_m(recfuel - 1, f, r, d, next, en, colx, yy, lh, max_w, iadd(row, 1), scratch)
    end
  else plain_px_draw_exh(f, r, d, st, en, colx, yy, lh, max_w, row, scratch)

fun draw_plain_line(f: !Font, r: !Rend, d: !Doc, li: int, nlines: int, colx: int, oy: int, safe_lh: int, scroll: int, scratch: &Buf >> _): void = let
  val step = doc_line_step(d, li)
in
  if step <= 0 then ()
  else let
    val st = doc_line_start(d, li)
    val en0 = if ilt(iadd(li, 1), nlines) then doc_line_start(d, iadd(li, 1)) else doc_len(d)
    val en = if igt(en0, st) andalso ieq(doc_byte(d, isub(en0, 1)), 10) then isub(en0, 1) else en0
    val cols = doc_codepoints(d, st, en)
    val wc = doc_get_wrap(d)
    val yy = isub(iadd(oy, doc_line_y(d, li)), scroll)
    val rows = (if wc > 0 andalso igt(cols, wc) then idiv(iadd(cols, isub(wc, 1)), wc) else 1) : int
  in
    if rows <= 1 then let
      val scap = buf_cap(scratch)
      val max_draw = imin(isub(en, st), scap)
      val n = if igt(max_draw, 0) then doc_slice_buf(d, st, iadd(st, max_draw), scratch, scap) else 0
      val base_x = row_base_pos(f, r, d, st, en, colx, scratch)
    in
      if igt(n, 0) then seen_int(font_draw_buf(f, r, base_x, yy, scratch, n, col_text())) else ()
    end else
      plain_rows_m(airlock_nat(MAX_REC_FUEL), f, r, d, st, en, colx, yy, safe_lh, wc, 0, rows, scratch)
  end
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
  val li_start = imax(0, isub(line_at_y_fast(d, scroll, safe_lh), 1))
  val li_end = imin(nlines, iadd(line_at_y_fast(d, iadd(scroll, ph), safe_lh), 2))
  val () = seen_int(pw)
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

implement font_arrow_w(f, r) = let
  val s = "v"
  val w = font_width(f, r, c_str_ptr(s), 1)
in
  if igt(w, 0) then w else 8
end

implement arrow_pos_x(f, r, colx) = let
  val aw = font_arrow_w(f, r)
  val pad = imax(4, idiv(font_line_h(f), 4))
in
  isub(colx, iadd(aw, pad))
end

implement gutter_num_end_x(f, r, colx) = let
  val arr_x = arrow_pos_x(f, r, colx)
  val gap = imax(6, idiv(font_arrow_w(f, r), 2))
in
  isub(arr_x, gap)
end

implement editor_colx(f, r, ox, pw) = let
  val aw = font_arrow_w(f, r)
  val pad = imax(4, idiv(font_line_h(f), 4))
  val gap = imax(6, idiv(aw, 2))
  val min_gw = iadd(imul(aw, 5), iadd(gap, iadd(aw, pad)))
  val gw = imax(UI_GUTTER_WIDTH, min_gw)
in
  imax(iadd(ox, iadd(gw, 16)), column_x(ox, pw))
end

fun draw_arrow(f: !Font, r: !Rend, d: !Doc, i: int, k: NodeKind, colx: int, y: int): void =
  if doc_is_foldable(d, i) then let
    val folded = doc_node_collapsed(d, i)
    val arr = if is_on(folded) then ">" else "v"
    val acol = if is_on(folded) then col_accent() else col_muted()
    val ax = arrow_pos_x(f, r, colx)
    val () = draw_s(f, r, ax, y, arr, acol)
  in
  end else ()


fun pen_unpack_line(pl: int): int =
  if pl < 0 then ~1 else idiv(pl, 256)

fun pen_unpack_row(pl: int): int =
  if pl < 0 then 0 else imod(pl, 256)

fun pen_pack(line: int, row: int): int =
  if line < 0 then ~1 else iadd(imul(line, 256), imin(255, row))

fun pen_inc_row(pl: int): int =
  if pl < 0 then 0 else iadd(pl, 1)

fun scan_word_end_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: int, en: int): int =
  if recfuel > 0 then (
    if ige(p, en) then en
    else if ieq(doc_byte(d, p), 32) then iadd(p, 1)
    else scan_word_end_m(recfuel - 1, d, iadd(p, 1), en)
  ) else en

fun visual_chunk_long(f: !Font, r: !Rend, d: !Doc, i0: int, w_end: int, max_w: int, scratch: &Buf >> _): int = let
  val width = visual_measure_w(d, i0, w_end, f, r, scratch)
in
  if igt(width, max_w) then
    visual_fit_prefix_m(airlock_nat(MAX_REC_FUEL), d, i0, i0, w_end, max_w, f, r, scratch)
  else w_end
end

fun visual_chunk_end(f: !Font, r: !Rend, d: !Doc, i0: int, j: int, scratch: &Buf >> _): int = let
  val w_end = scan_word_end_m(airlock_nat(MAX_REC_FUEL), d, i0, j)
  val wc = doc_get_wrap(d)
  val safe_wc = if igt(wc, 0) then wc else 80
  val max_w = imul(safe_wc, UI_WRAP_CELL_WIDTH)
in
  visual_chunk_long(f, r, d, i0, w_end, max_w, scratch)
end

fun visual_should_wrap(f: !Font, r: !Rend, d: !Doc, i0: int, kend: int, colx: int, pen_x: int, scratch: &Buf >> _): bool = let
  val scap = buf_cap(scratch)
  val n = doc_slice_buf(d, i0, kend, scratch, scap)
  val tw = if igt(n, 0) then font_width_buf(f, r, scratch, n) else 0
  val wc = doc_get_wrap(d)
  val max_w = if wc > 0 then imul(wc, UI_WRAP_CELL_WIDTH) else 720
  val max_x = iadd(colx, max_w)
in
  igt(pen_x, colx) andalso igt(iadd(pen_x, tw), max_x)
end

fun view_run_adv(f: !Font, r: !Rend, d: !Doc, i0: int, j: int, colx: int, oy: int, scroll: int, lh: int, ph: int, c: uint, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): int = let
  val scap = buf_cap(scratch)
  val cur_line = doc_line_of(d, i0)
  val pl_line = pen_unpack_line(pen_line)
  val () = if ine(cur_line, pl_line) then let
    val bx = line_base_pos(f, r, d, cur_line, colx, scratch)
  in
    pen_line := pen_pack(cur_line, 0); pen_x := bx
  end else ()
  val row = pen_unpack_row(pen_line)
  val yy = isub(iadd(oy, iadd(doc_line_y(d, cur_line), imul(row, lh))), scroll)
  val n = doc_slice_buf(d, i0, j, scratch, scap)
in
  if igt(n, 0) then (
    if ilt(iadd(yy, lh), oy) orelse igt(yy, iadd(oy, ph)) then
      font_width_buf(f, r, scratch, n)
    else
      font_draw_buf(f, r, pen_x, yy, scratch, n, c)
  ) else 0
end

fun view_newline_adv(f: !Font, r: !Rend, d: !Doc, i0: int, colx: int, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val cur_line = doc_line_of(d, i0)
  val next_line = iadd(cur_line, 1)
  val bx = (if ilt(next_line, doc_nlines(d)) then line_base_pos(f, r, d, next_line, colx, scratch) else colx)
  val () = pen_x := bx
  val () = pen_line := pen_pack(next_line, 0)
in
end

fun view_slice_step(
  f: !Font, r: !Rend, d: !Doc, i0: int, kend: int, j: int,
  colx: int, oy: int, scroll: int, lh: int, ph: int, c: uint,
  scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _
): int = let
  val wrap = visual_should_wrap(f, r, d, i0, kend, colx, pen_x, scratch)
  val () = if wrap then let
    val cur_line = doc_line_of(d, i0)
    val bx = line_base_pos(f, r, d, cur_line, colx, scratch)
  in
    pen_x := bx; pen_line := pen_inc_row(pen_line)
  end else ()
  val adv = view_run_adv(f, r, d, i0, kend, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line)
  val () = pen_x := iadd(pen_x, adv)
  val is_mid = ilt(kend, j) andalso ine(doc_byte(d, isub(kend, 1)), 32)
in
  if is_mid then let
    val cur_line = doc_line_of(d, i0)
    val row = pen_unpack_row(pen_line)
    val yy = isub(iadd(oy, iadd(doc_line_y(d, cur_line), imul(row, lh))), scroll)
    val () = anth_draw_wrap_arrow(f, r, pen_x, yy, col_muted())
    val bx = line_base_pos(f, r, d, cur_line, colx, scratch)
    val () = pen_x := bx
    val () = pen_line := pen_inc_row(pen_line)
  in adv end else adv
end

extern fun view_slice_exh(f: !Font, r: !Rend, d: !Doc, i0: int, b: int, colx: int, oy: int, scroll: int, lh: int, ph: int, c: uint, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _, total: int): int = "mac#anth_die_int"

fun view_slice_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, i0: int, b: int,
  colx: int, oy: int, scroll: int, lh: int, ph: int, c: uint,
  scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _, total: int
): int =
  if recfuel > 0 then (
    if ilt(i0, b) then
      if ieq(doc_byte(d, i0), 10) then let
        val () = view_newline_adv(f, r, d, i0, colx, scratch, pen_x, pen_line)
      in
        view_slice_m(recfuel - 1, f, r, d, iadd(i0, 1), b, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line, total)
      end else let
        val j = text_run_end(d, i0, b)
        val kend = visual_chunk_end(f, r, d, i0, j, scratch)
        val adv = view_slice_step(f, r, d, i0, kend, j, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line)
      in
        view_slice_m(recfuel - 1, f, r, d, kend, b, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line, iadd(total, adv))
      end
    else total
  ) else view_slice_exh(f, r, d, i0, b, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line, total)

fun draw_view_slice(f: !Font, r: !Rend, d: !Doc, a: int, b: int, colx: int, oy: int, scroll: int, lh: int, ph: int, c: uint, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): int =
 if doc_visual_active(d) then visual_draw_slice(f,r,d,a,b,colx,oy,scroll,lh,ph,c,scratch) else let
  val scap = buf_cap(scratch)
  val slen = if igt(b, a) then doc_slice_buf(d, a, b, scratch, scap) else 0
  val single = ieq(doc_line_of(d, a), doc_line_of(d, imax(a, isub(b, 1))))
  val is_rtl = if single andalso igt(slen, 0) then ui_text_line_direction_code(f, scratch, slen) else 0
in
  if igt(is_rtl, 0) then let
    val cur_line = doc_line_of(d, a)
    val wc = doc_get_wrap(d)
    val max_w = imul(wc, UI_WRAP_CELL_WIDTH)
    val text_width = font_width_buf(f, r, scratch, slen)
    val rows = plain_px_count_m(airlock_nat(MAX_REC_FUEL), f, r, d, a, b, max_w, scratch)
    val base_yy = isub(iadd(oy, doc_line_y(d, cur_line)), scroll)
    val () = plain_px_draw_m(airlock_nat(MAX_REC_FUEL), f, r, d, a, b, colx, base_yy, lh, max_w, 0, scratch)
    val last_bx = iadd(colx, max_w)
    val () = pen_line := pen_pack(cur_line, rows)
    val () = pen_x := last_bx
  in
    text_width
  end else
    view_slice_m(airlock_nat(MAX_REC_FUEL), f, r, d, a, b, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line, 0)
end

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
  val st0 = skip_hash_m(airlock_nat(MAX_REC_FUEL), d, a, b)
  val st = skip_gap_m(airlock_nat(MAX_REC_FUEL), d, st0, b)
  val en_h = trim_tail_m(airlock_nat(MAX_REC_FUEL), d, b, st)
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
  val () = if ine(uok(tex), 0) then rend_quad(r, tex, ShadeRgba, colx, y, dw, dh, 0.0, 0.0, 1.0, 1.0, col_white())
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
  var rel = buf_make(8)
  var full = buf_make(8)
  var shown = buf_make(8)
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

fun draw_embedded_doc(f: !Font, r: !Rend, child: !Doc, anchor: !Buf, scope: EmbedScope, child_colw: int, x: int, y: int, w: int, h: int,
                      viewport_x: int, viewport_y: int, viewport_w: int, viewport_h: int,
                      lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _): void = let
  val colx = editor_colx(f, r, x, child_colw)
  val width=if font_text_active(f) then imax(1,isub(iadd(x,w),iadd(colx,16))) else child_colw
  val height = prep_doc(f,child, c, r, vault, lh, width, ViewRead)
  val line = embed_block_line(child, scope, anchor)
  val line_scroll = if ige(line, 0) then doc_line_y(child, line) else 0
  val content_height = if ige(line, 0) then imax(lh, doc_line_step(child, line)) else height
  val content_y = iadd(y, 4)
  val content_h = imax(lh, isub(h, 8))
  var py: int = y
  var pa: int = 0
  val () = rend_rect(r, x, y, w, h, col_side())
  val () = ui_draw_border(r, x, y, w, h, 1, col_line())
  val () = rend_scissor(r, x, content_y, w, content_h)
  val () = if igt(doc_nnodes(child), 0) then
    draw_nodes(f, r, child, x, content_y, child_colw, imin(content_h, content_height), line_scroll, lh, vault, c, scratch, 0, py, pa, ViewRead)
  else draw_plain_doc(f, r, child, colx, content_y, child_colw, imin(content_h, content_height), line_scroll, lh, scratch)
  val () = rend_scissor(r, viewport_x, viewport_y, viewport_w, viewport_h)
in
  ()
end

fun obtain_embed_doc(c: &Cache >> _, shown: !Buf, p_str: string, mt: int, level: int): @(Doc, bool) = let
  val @(opt_child, c2) = cache_take_embed(c, shown, mt)
  val () = c := c2
in
  case+ opt_child of
  | ~Some_vt(d) => @(d, true)
  | ~None_vt() => let
      val d = doc_open()
      val ok = embedded_doc_load(d, p_str, level)
    in
      @(d, ok)
    end
end

fun save_embed_cache(c: &Cache >> _, shown: !Buf, mt: int, child: Doc, cw: int, lh: int): void = let
  var p_copy = buf_make(buf_len(shown))
  val () = bcat(p_copy, shown, 0, buf_len(shown))
in
  c := cache_put_embed(c, p_copy, mt, child, cw, lh)
end

fun draw_embedded_path(shown: !Buf, anchor: !Buf, scope: EmbedScope, level: int, child_colw: int, f: !Font, r: !Rend, x: int, y: int, w: int, h: int,
                       vx: int, vy: int, vw: int, vh: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _): void =
  if igt(level, MAX_EMBED_DEPTH) then draw_missing_embed(f, r, x, y)
  else let
    val p_str = buf_cstr(shown)
    val mt = fs_mtime(p_str)
  in
    if ieq(mt, 0) then draw_missing_embed(f, r, x, y)
    else let
      val @(child, is_loaded) = obtain_embed_doc(c, shown, p_str, mt, level)
    in
      if is_loaded then let
        val () = draw_embedded_doc(f, r, child, anchor, scope, child_colw, x, y, w, h, vx, vy, vw, vh, lh, vault, c, scratch)
        val () = save_embed_cache(c, shown, mt, child, child_colw, lh)
      in
        ()
      end else let
        val () = doc_free(child)
      in
        draw_missing_embed(f, r, x, y)
      end
    end
  end

fun draw_node_embed(f: !Font, r: !Rend, d: !Doc, i: int, ox: int, oy: int, pw: int, ph: int, scroll: int,
                    colx: int, y: int, h: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _,
                    pen_x: &int >> _, pen_line: &int >> _): void = let
  val () = pen_line := ~1
  val () = pen_x := colx
  val dp = doc_node_depth(d, i)
  val box_x = if igt(dp, 0) then iadd(colx, imul(dp, 20)) else colx
  val box_y = isub(y, 4)
  val box_h = imax(iadd(lh, 8), h)
  var shown = buf_make(8)
  var rel = buf_make(8)
  var full = buf_make(8)
  var anchor = buf_make(8)
  val () = take_path(d, i, rel)
  val () = take_anchor(d, i, anchor)
  val () = resolve_path(vault, rel, full)
  val () = with_md(full, shown)
  val level = iadd(doc_embed_level(d), 1)
  val scope = embed_scope(d, i)
  val box_w = embed_box_width(ox, pw, box_x)
  val child_colw = if font_text_active(f) then box_w else embed_child_width(column_w(pw))
  val () = draw_embedded_path(shown, anchor, scope, level, child_colw, f, r, box_x, box_y, box_w, box_h, ox, oy, pw, ph, lh, vault, c, scratch)
  val () = buf_free(rel)
  val () = buf_free(full)
  val () = buf_free(shown)
  val () = buf_free(anchor)
in
end

fun is_latex_alpha(b: int): bool =
  (ige(b, 65) andalso ile(b, 90)) orelse (ige(b, 97) andalso ile(b, 122))

fun is_math_space(b: int): bool = ieq(b, 32) orelse ieq(b, 9)

fun math_sym_greek_lo1(cmd: string): string =
  if ieq(c_strcmp(cmd, "alpha"), 0) then "α"
  else if ieq(c_strcmp(cmd, "beta"), 0) then "β"
  else if ieq(c_strcmp(cmd, "gamma"), 0) then "γ"
  else if ieq(c_strcmp(cmd, "delta"), 0) then "δ"
  else if ieq(c_strcmp(cmd, "epsilon"), 0) then "ε"
  else if ieq(c_strcmp(cmd, "zeta"), 0) then "ζ"
  else if ieq(c_strcmp(cmd, "eta"), 0) then "η"
  else if ieq(c_strcmp(cmd, "theta"), 0) then "θ"
  else if ieq(c_strcmp(cmd, "iota"), 0) then "ι"
  else if ieq(c_strcmp(cmd, "kappa"), 0) then "κ"
  else if ieq(c_strcmp(cmd, "lambda"), 0) then "λ"
  else if ieq(c_strcmp(cmd, "mu"), 0) then "μ"
  else ""

fun math_sym_greek_lo2(cmd: string): string =
  if ieq(c_strcmp(cmd, "nu"), 0) then "ν"
  else if ieq(c_strcmp(cmd, "xi"), 0) then "ξ"
  else if ieq(c_strcmp(cmd, "pi"), 0) then "π"
  else if ieq(c_strcmp(cmd, "rho"), 0) then "ρ"
  else if ieq(c_strcmp(cmd, "sigma"), 0) then "σ"
  else if ieq(c_strcmp(cmd, "tau"), 0) then "τ"
  else if ieq(c_strcmp(cmd, "upsilon"), 0) then "υ"
  else if ieq(c_strcmp(cmd, "phi"), 0) then "φ"
  else if ieq(c_strcmp(cmd, "chi"), 0) then "χ"
  else if ieq(c_strcmp(cmd, "psi"), 0) then "ψ"
  else if ieq(c_strcmp(cmd, "omega"), 0) then "ω"
  else ""

fun math_sym_greek_up(cmd: string): string =
  if ieq(c_strcmp(cmd, "Gamma"), 0) then "Γ"
  else if ieq(c_strcmp(cmd, "Delta"), 0) then "Δ"
  else if ieq(c_strcmp(cmd, "Theta"), 0) then "Θ"
  else if ieq(c_strcmp(cmd, "Lambda"), 0) then "Λ"
  else if ieq(c_strcmp(cmd, "Xi"), 0) then "Ξ"
  else if ieq(c_strcmp(cmd, "Pi"), 0) then "Π"
  else if ieq(c_strcmp(cmd, "Sigma"), 0) then "Σ"
  else if ieq(c_strcmp(cmd, "Phi"), 0) then "Φ"
  else if ieq(c_strcmp(cmd, "Psi"), 0) then "Ψ"
  else if ieq(c_strcmp(cmd, "Omega"), 0) then "Ω"
  else ""

fun math_sym_ops(cmd: string): string =
  if ieq(c_strcmp(cmd, "sum"), 0) then "∑"
  else if ieq(c_strcmp(cmd, "prod"), 0) then "∏"
  else if ieq(c_strcmp(cmd, "int"), 0) then "∫"
  else if ieq(c_strcmp(cmd, "sqrt"), 0) then "√"
  else if ieq(c_strcmp(cmd, "infty"), 0) then "∞"
  else if ieq(c_strcmp(cmd, "pm"), 0) then "±"
  else if ieq(c_strcmp(cmd, "mp"), 0) then "∓"
  else if ieq(c_strcmp(cmd, "times"), 0) then "×"
  else if ieq(c_strcmp(cmd, "div"), 0) then "÷"
  else if ieq(c_strcmp(cmd, "cdot"), 0) then "·"
  else if ieq(c_strcmp(cmd, "approx"), 0) then "≈"
  else if ieq(c_strcmp(cmd, "neq"), 0) orelse ieq(c_strcmp(cmd, "ne"), 0) then "≠"
  else if ieq(c_strcmp(cmd, "leq"), 0) orelse ieq(c_strcmp(cmd, "le"), 0) then "≤"
  else if ieq(c_strcmp(cmd, "geq"), 0) orelse ieq(c_strcmp(cmd, "ge"), 0) then "≥"
  else if ieq(c_strcmp(cmd, "over"), 0) then " / "
  else if ieq(c_strcmp(cmd, "bar"), 0) then "¯"
  else ""

fun math_sym_rel(cmd: string): string =
  if ieq(c_strcmp(cmd, "to"), 0) orelse ieq(c_strcmp(cmd, "rightarrow"), 0) then "→"
  else if ieq(c_strcmp(cmd, "leftarrow"), 0) then "←"
  else if ieq(c_strcmp(cmd, "Rightarrow"), 0) then "⇒"
  else if ieq(c_strcmp(cmd, "Leftarrow"), 0) then "⇐"
  else if ieq(c_strcmp(cmd, "iff"), 0) orelse ieq(c_strcmp(cmd, "Leftrightarrow"), 0) then "⇔"
  else if ieq(c_strcmp(cmd, "in"), 0) then "∈"
  else if ieq(c_strcmp(cmd, "notin"), 0) then "∉"
  else if ieq(c_strcmp(cmd, "partial"), 0) then "∂"
  else if ieq(c_strcmp(cmd, "nabla"), 0) then "∇"
  else if ieq(c_strcmp(cmd, "forall"), 0) then "∀"
  else if ieq(c_strcmp(cmd, "exists"), 0) then "∃"
  else if ieq(c_strcmp(cmd, "quad"), 0) then "  "
  else if ieq(c_strcmp(cmd, "qquad"), 0) then "    "
  else ""

fun math_cmd_lookup(cmd: string): string = let
  val s1 = math_sym_greek_lo1(cmd)
in
  if igt(c_strlen(s1), 0) then s1
  else let
    val s2 = math_sym_greek_lo2(cmd)
  in
    if igt(c_strlen(s2), 0) then s2
    else let
      val s3 = math_sym_greek_up(cmd)
    in
      if igt(c_strlen(s3), 0) then s3
      else let
        val s4 = math_sym_ops(cmd)
      in
        if igt(c_strlen(s4), 0) then s4 else math_sym_rel(cmd)
      end
    end
  end
end

fun math_char_to_sup(c: int): string =
  if ieq(c, 48) then "⁰" else if ieq(c, 49) then "¹"
  else if ieq(c, 50) then "²" else if ieq(c, 51) then "³"
  else if ieq(c, 52) then "⁴" else if ieq(c, 53) then "⁵"
  else if ieq(c, 54) then "⁶" else if ieq(c, 55) then "⁷"
  else if ieq(c, 56) then "⁸" else if ieq(c, 57) then "⁹"
  else if ieq(c, 43) then "⁺" else if ieq(c, 45) then "⁻"
  else if ieq(c, 61) then "⁼" else if ieq(c, 40) then "⁽"
  else if ieq(c, 41) then "⁾" else if ieq(c, 110) then "ⁿ"
  else if ieq(c, 105) then "ⁱ" else if ieq(c, 120) then "ˣ"
  else ""

fun math_char_to_sub(c: int): string =
  if ieq(c, 48) then "₀" else if ieq(c, 49) then "₁"
  else if ieq(c, 50) then "₂" else if ieq(c, 51) then "₃"
  else if ieq(c, 52) then "₄" else if ieq(c, 53) then "₅"
  else if ieq(c, 54) then "₆" else if ieq(c, 55) then "₇"
  else if ieq(c, 56) then "₈" else if ieq(c, 57) then "₉"
  else if ieq(c, 43) then "₊" else if ieq(c, 45) then "₋"
  else if ieq(c, 61) then "₌" else if ieq(c, 105) then "ᵢ"
  else if ieq(c, 106) then "ⱼ" else if ieq(c, 107) then "ₖ"
  else if ieq(c, 110) then "ₙ" else if ieq(c, 109) then "ₘ"
  else ""

fun scan_alpha_end_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int
): int =
  if recfuel > 0 then (
    if ige(p, en) then p
    else if is_latex_alpha(doc_byte(d, p)) then scan_alpha_end_m(recfuel - 1, d, iadd(p, 1), en)
    else p
  ) else p

fun scan_alpha_end(d: !Doc, p: int, en: int): int =
  scan_alpha_end_m(airlock_nat(MAX_REC_FUEL), d, p, en)

fun math_skip_sp_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int
): int =
  if recfuel > 0 then (
    if ige(p, en) then p
    else if is_math_space(doc_byte(d, p)) then math_skip_sp_m(recfuel - 1, d, iadd(p, 1), en)
    else p
  ) else p

fun math_skip_sp(d: !Doc, p: int, en: int): int =
  math_skip_sp_m(airlock_nat(MAX_REC_FUEL), d, p, en)

fun find_brace_close_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, depth: int
): int =
  if recfuel > 0 then (
    if ige(p, en) then en
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, 123) then find_brace_close_m(recfuel - 1, d, iadd(p, 1), en, iadd(depth, 1))
      else if ieq(b, 125) then (
        if ile(depth, 1) then p
        else find_brace_close_m(recfuel - 1, d, iadd(p, 1), en, isub(depth, 1))
      ) else find_brace_close_m(recfuel - 1, d, iadd(p, 1), en, depth)
    end
  ) else en

fun find_brace_close(d: !Doc, p: int, en: int): int =
  find_brace_close_m(airlock_nat(MAX_REC_FUEL), d, p, en, 1)

fun convert_sup_run_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, out: &Buf >> _
): void =
  if recfuel > 0 then (
    if ige(p, en) then ()
    else let
      val b = doc_byte(d, p)
      val s = math_char_to_sup(b)
      val () = if igt(c_strlen(s), 0) then bstr(out, s) else (bstr(out, "^"); buf_push(out, b))
    in
      convert_sup_run_m(recfuel - 1, d, iadd(p, 1), en, out)
    end
  ) else ()

fun convert_sup(d: !Doc, p: int, en: int, out: &Buf >> _): int =
  if ige(p, en) then p
  else if ieq(doc_byte(d, p), 123) then let
    val close = find_brace_close(d, iadd(p, 1), en)
    val () = convert_sup_run_m(airlock_nat(MAX_REC_FUEL), d, iadd(p, 1), close, out)
  in
    if ilt(close, en) then iadd(close, 1) else close
  end else let
    val b = doc_byte(d, p)
    val s = math_char_to_sup(b)
    val () = if igt(c_strlen(s), 0) then bstr(out, s) else (bstr(out, "^"); buf_push(out, b))
  in
    iadd(p, 1)
  end

fun convert_sub_run_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, out: &Buf >> _
): void =
  if recfuel > 0 then (
    if ige(p, en) then ()
    else let
      val b = doc_byte(d, p)
      val s = math_char_to_sub(b)
      val () = if igt(c_strlen(s), 0) then bstr(out, s) else (bstr(out, "_"); buf_push(out, b))
    in
      convert_sub_run_m(recfuel - 1, d, iadd(p, 1), en, out)
    end
  ) else ()

fun convert_sub(d: !Doc, p: int, en: int, out: &Buf >> _): int =
  if ige(p, en) then p
  else if ieq(doc_byte(d, p), 123) then let
    val close = find_brace_close(d, iadd(p, 1), en)
    val () = convert_sub_run_m(airlock_nat(MAX_REC_FUEL), d, iadd(p, 1), close, out)
  in
    if ilt(close, en) then iadd(close, 1) else close
  end else let
    val b = doc_byte(d, p)
    val s = math_char_to_sub(b)
    val () = if igt(c_strlen(s), 0) then bstr(out, s) else (bstr(out, "_"); buf_push(out, b))
  in
    iadd(p, 1)
  end

extern fun math_latex_to_buf(d: !Doc, st: int, en: int, out: &Buf >> _): void

fun convert_frac(d: !Doc, p: int, en: int, out: &Buf >> _): int = let
  val p0 = math_skip_sp(d, p, en)
in
  if ilt(p0, en) andalso ieq(doc_byte(d, p0), 123) then let
    val c1 = find_brace_close(d, iadd(p0, 1), en)
    val p1 = math_skip_sp(d, (if ilt(c1, en) then iadd(c1, 1) else c1), en)
  in
    if ilt(p1, en) andalso ieq(doc_byte(d, p1), 123) then let
      val c2 = find_brace_close(d, iadd(p1, 1), en)
      val () = bstr(out, "(")
      val () = math_latex_to_buf(d, iadd(p0, 1), c1, out)
      val () = bstr(out, ") / (")
      val () = math_latex_to_buf(d, iadd(p1, 1), c2, out)
      val () = bstr(out, ")")
    in
      if ilt(c2, en) then iadd(c2, 1) else c2
    end else p0
  end else p0
end

fun convert_sqrt(d: !Doc, p: int, en: int, out: &Buf >> _): int = let
  val () = bstr(out, "√")
  val p0 = math_skip_sp(d, p, en)
in
  if ilt(p0, en) andalso ieq(doc_byte(d, p0), 123) then let
    val c = find_brace_close(d, iadd(p0, 1), en)
    val () = bstr(out, "(")
    val () = math_latex_to_buf(d, iadd(p0, 1), c, out)
    val () = bstr(out, ")")
  in
    if ilt(c, en) then iadd(c, 1) else c
  end else p0
end

fun convert_named_cmd(d: !Doc, cmd_end: int, cbuf: !Buf, en: int, out: &Buf >> _): int =
  if ieq(c_strcmp(cstr(cbuf), "frac"), 0) then convert_frac(d, cmd_end, en, out)
  else if ieq(c_strcmp(cstr(cbuf), "sqrt"), 0) then convert_sqrt(d, cmd_end, en, out)
  else let
    val sym = math_cmd_lookup(cstr(cbuf))
    val () = if igt(c_strlen(sym), 0) then bstr(out, sym) else bstr(out, cstr(cbuf))
  in
    cmd_end
  end

fun convert_cmd(d: !Doc, p: int, en: int, out: &Buf >> _): int = let
  val cmd_end = scan_alpha_end(d, p, en)
in
  if igt(cmd_end, p) then let
    var cbuf = buf_make(32)
    val clen = doc_slice_buf(d, p, cmd_end, cbuf, 31)
    val () = buf_set_len(cbuf, clen)
    val next_p = convert_named_cmd(d, cmd_end, cbuf, en, out)
    val () = buf_free(cbuf)
  in
    next_p
  end else if ilt(p, en) then let
    val b = doc_byte(d, p)
    val () = if ieq(b, 44) then bstr(out, " ") else buf_push(out, b)
  in
    iadd(p, 1)
  end else p
end

fun math_latex_to_buf_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, out: &Buf >> _
): void =
  if recfuel > 0 then (
    if ige(p, en) then ()
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, 92) then
        math_latex_to_buf_m(recfuel - 1, d, convert_cmd(d, iadd(p, 1), en, out), en, out)
      else if ieq(b, 94) then
        math_latex_to_buf_m(recfuel - 1, d, convert_sup(d, iadd(p, 1), en, out), en, out)
      else if ieq(b, 95) then
        math_latex_to_buf_m(recfuel - 1, d, convert_sub(d, iadd(p, 1), en, out), en, out)
      else if ieq(b, 123) orelse ieq(b, 125) then
        math_latex_to_buf_m(recfuel - 1, d, iadd(p, 1), en, out)
      else (buf_push(out, b); math_latex_to_buf_m(recfuel - 1, d, iadd(p, 1), en, out))
    end
  ) else ()

implement math_latex_to_buf(d, st, en, out) =
  math_latex_to_buf_m(airlock_nat(MAX_REC_FUEL), d, st, en, out)

fun mathb_slice_bounds(d: !Doc, i: int): @(int, int) = let
  val a = doc_node_start(d, i)
  val b = doc_node_end(d, i)
  val st = (if ilt(iadd(a, 2), b) andalso ieq(doc_byte(d, a), 36) andalso ieq(doc_byte(d, iadd(a, 1)), 36) then iadd(a, 2) else a)
  val en = (if igt(isub(b, 2), st) andalso ieq(doc_byte(d, isub(b, 1)), 36) andalso ieq(doc_byte(d, isub(b, 2)), 36) then isub(b, 2) else b)
in
  @(st, en)
end

fun draw_node_mathb(
  f: !Font, r: !Rend, d: !Doc, i: int, colx: int, y: int, lh: int, pw: int,
  pen_x: &int >> _, pen_line: &int >> _
): void = let
  val () = pen_line := ~1
  val () = pen_x := colx
  val @(st, en) = mathb_slice_bounds(d, i)
  var mb = buf_make(64)
  val () = math_latex_to_buf(d, st, en, mb)
  val mlen = buf_len(mb)
  val tw = font_width_buf(f, r, mb, mlen)
  val colw = column_w(pw)
  val bw = imin(colw, iadd(tw, 32))
  val bx = iadd(colx, imax(0, idiv(isub(colw, bw), 2)))
  val tx = iadd(bx, idiv(isub(bw, tw), 2))
  val bh = iadd(lh, 8)
  val by = isub(y, 4)
  val fl = doc_node_flags(d, i)
  val () = rend_rect(r, bx, by, bw, bh, col_side())
  val () = ui_draw_border(r, bx, by, bw, bh, 1, (if iand(fl, FL_ERROR) != 0 then col_danger() else col_line()))
  val () = seen_int(font_draw_buf(f, r, tx, iadd(by, 4), mb, mlen, col_math()))
  val () = buf_free(mb)
in
end

fun draw_leaf_effects(r: !Rend, x0: int, yy: int, tw: int, lh: int, style: int): void =
  if igt(tw, 0) then let
    val () = if iand(style, STYLE_HIGH) != 0 then rend_rect(r, x0, yy, tw, lh, col_highbg()) else ()
    val () = if iand(style, STYLE_LINK) != 0 then rend_rect(r, x0, iadd(yy, isub(lh, 2)), tw, 1, col_link()) else ()
    val () = if iand(style, STYLE_STRIKE) != 0 then rend_rect(r, x0, iadd(yy, idiv(lh, 2)), tw, 1, col_muted()) else ()
    val () = if iand(style, STYLE_ERROR) != 0 then rend_rect(r, x0, iadd(yy, isub(lh, 2)), tw, 2, col_danger()) else ()
  in
  end else ()

fun draw_math_text(
  f: !Font, r: !Rend, x0: int, yy: int, oy: int, ph: int, lh: int, mb: !Buf, mlen: int
): void =
  if ilt(iadd(yy, lh), oy) orelse igt(yy, iadd(oy, ph)) then ()
  else seen_int(font_draw_buf(f, r, x0, yy, mb, mlen, col_math()))

fun draw_leaf_math_inline(
  f: !Font, r: !Rend, d: !Doc, i: int, oy: int, ph: int, scroll: int,
  lh: int, colx: int, st: int, en: int, scratch: &Buf >> _,
  pen_x: &int >> _, pen_line: &int >> _
): void = let
  val () = seen_buf(scratch)
  var mb = buf_make(32)
  val () = math_latex_to_buf(d, st, en, mb)
  val mlen = buf_len(mb)
  val line = doc_line_of(d, st)
  val pl_line = pen_unpack_line(pen_line)
  val cur_row = (if ieq(line, pl_line) then pen_unpack_row(pen_line) else 0)
  val yy = isub(iadd(oy, iadd(doc_line_y(d, line), imul(cur_row, lh))), scroll)
  val x0 = (if ine(line, pl_line) then colx else pen_x) : int
  val tw = font_width_buf(f, r, mb, mlen)
  val () = draw_math_text(f, r, x0, yy, oy, ph, lh, mb, mlen)
  val () = pen_x := iadd(x0, tw)
  val () = pen_line := pen_pack(line, cur_row)
  val () = draw_leaf_effects(r, x0, yy, tw, lh, ast_style(d, i))
  val () = buf_free(mb)
in
end

fun leaf_color(k: NodeKind, style: int): uint =
  if is_kind(k, KMark) then col_muted()
  else if is_kind(k, KTag) then col_tag()
  else if iand(style, STYLE_LINK) != 0 then col_link()
  else if iand(style, STYLE_HIGH) != 0 then col_hightxt()
  else if iand(style, STYLE_BOLD) != 0 then col_white()
  else if iand(style, STYLE_ITALIC) != 0 then col_accent()
  else if iand(style, STYLE_STRIKE) != 0 then col_muted()
  else if iand(style, STYLE_MATH) != 0 then col_math()
  else if iand(style, STYLE_CODE) != 0 then col_code()
  else if iand(style, STYLE_HEADING) != 0 then col_heading()
  else kind_col(k)

fun draw_leaf_content(f: !Font, r: !Rend, d: !Doc, i: int, k: NodeKind,
                      oy: int, ph: int, scroll: int, lh: int, colx: int,
                      st: int, en: int, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val style = ast_style(d, i)
  val col = leaf_color(k, style)
  val line = doc_line_of(d, st)
  val pl_line = pen_unpack_line(pen_line)
  val cur_row = (if ieq(line, pl_line) then pen_unpack_row(pen_line) else 0)
  val yy = isub(iadd(oy, iadd(doc_line_y(d, line), imul(cur_row, lh))), scroll)
  val x0 = (if ine(line, pl_line) then colx else pen_x) : int
  val ()=if doc_visual_active(d) then visual_leaf_background(f,r,d,st,en,colx,oy,scroll,lh,ph,style,scratch) else ()
  val tw = draw_view_slice(f, r, d, st, en, colx, oy, scroll, lh, ph, col, scratch, pen_x, pen_line)
in
  if doc_visual_active(d) then visual_leaf_rules(f,r,d,st,en,colx,oy,scroll,lh,ph,style,scratch)
  else draw_leaf_effects(r, x0, yy, tw, lh, style)
end

fun draw_leaf_styled(f: !Font, r: !Rend, d: !Doc, i: int, k: NodeKind,
                     oy: int, ph: int, scroll: int, lh: int, colx: int,
                     scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _,
                     viewmode: ViewMode): void = let
  val flags = doc_node_flags(d, i)
  val is_read = is_view_read(viewmode)
  val skip = is_read andalso (is_kind(k, KMark) orelse is_kind(k, KLinkDest) orelse is_kind(k, KLinkTitle) orelse iand(flags, FL_READ_HIDDEN) != 0)
in
  if skip then ()
  else let
    val st0 = doc_node_start(d, i)
    val st = (if is_read andalso is_kind(k, KEscape) then iadd(st0, 1) else st0)
    val en = doc_node_end(d, i)
    val p_idx = doc_node_parent(d, i)
    val p_k = if ige(p_idx, 0) then doc_node_kind(d, p_idx) else KNone
  in
    if is_read andalso is_kind(p_k, KMath) then
      draw_leaf_math_inline(f, r, d, i, oy, ph, scroll, lh, colx, st, en, scratch, pen_x, pen_line)
    else
      draw_leaf_content(f, r, d, i, k, oy, ph, scroll, lh, colx, st, en, scratch, pen_x, pen_line)
  end
end

fun draw_container_box(r: !Rend, d: !Doc, i: int, k: NodeKind, colx: int, y: int, h: int, lh: int, pw: int): void =
  if is_kind(k, KQuote) then
    rend_rect(r, isub(colx, 8), y, 3, imax(h, lh), col_quote())
  else if is_kind(k, KCallout) then
    rend_rect(r, isub(colx, 8), y, 4, imax(h, lh), col_accent())
  else if is_kind(k, KCode) orelse is_kind(k, KMathBlock) then let
    val fl = doc_node_flags(d, i)
    val () = rend_rect(r, colx, y, column_w(pw), imax(h, lh), col_highbg())
  in
    if iand(fl, FL_ERROR) != 0 then rend_rect(r, colx, y, 3, imax(h, lh), col_danger()) else ()
  end else ()

fun draw_node_content(f: !Font, r: !Rend, d: !Doc, i: int, k: NodeKind, ox: int, oy: int, pw: int, ph: int, scroll: int,
                      lh: int, colx: int, y: int, h: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _,
                      py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: ViewMode): void =
  if is_heading(k) then
    draw_node_heading(f, r, d, i, k, oy, ph, scroll, lh, colx, y, viewmode, scratch, py, pa, pen_x, pen_line)
  else if is_kind(k, KHr) then (
    pen_line := ~1; pen_x := colx;
    rend_rect(r, colx, iadd(y, 4), column_w(pw), 2, col_line())
  )
  else if is_kind(k, KImage) then
    draw_node_image(r, d, i, pw, colx, y, h, vault, c, pen_x, pen_line)
  else if is_kind(k, KEmbed) then
    draw_node_embed(f, r, d, i, ox, oy, pw, ph, scroll, colx, y, h, lh, vault, c, scratch, pen_x, pen_line)
  else if is_kind(k, KMathb) andalso is_view_read(viewmode) then
    draw_node_mathb(f, r, d, i, colx, y, lh, pw, pen_x, pen_line)
  else if kind_is_leaf(k) then
    draw_leaf_styled(f, r, d, i, k, oy, ph, scroll, lh, colx, scratch, pen_x, pen_line, viewmode)
  else
    draw_container_box(r, d, i, k, colx, y, h, lh, pw)

fun draw_node(f: !Font, r: !Rend, d: !Doc, i: int, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: ViewMode): void = let
  val k = doc_node_kind(d, i)
  val y = isub(iadd(oy, doc_node_y(d, i)), scroll)
  val h = doc_node_height(d, i)
  val colx = editor_colx(f, r, ox, pw)
  val p_idx = doc_node_parent(d, i)
  val p_k = if ige(p_idx, 0) then doc_node_kind(d, p_idx) else KNone
  val in_read = is_view_read(viewmode)
  val skip = is_on(doc_node_hidden(d, i)) orelse (in_read andalso (is_heading(p_k) orelse is_kind(p_k, KImage) orelse is_kind(p_k, KEmbed) orelse is_kind(p_k, KMathb)))
in
  if skip then ()
  else let
    val () = draw_arrow(f, r, d, i, k, colx, y)
  in
    draw_node_content(f, r, d, i, k, ox, oy, pw, ph, scroll, lh, colx, y, h, vault, c, scratch, py, pa, pen_x, pen_line, viewmode)
  end
end

extern fun draw_nodes_impl_exh(f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: ViewMode): void = "mac#anth_die_void"

fun draw_nodes_impl_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: ViewMode): void =
  if recfuel > 0 then (
    if ige(i, doc_nnodes(d)) then ()
    else let
      val y = doc_node_y(d, i)
    in
      if igt(y, iadd(scroll, iadd(ph, 64))) then ()
      else let
        val () = draw_node(f, r, d, i, ox, oy, pw, ph, scroll, lh, vault, c, scratch, py, pa, pen_x, pen_line, viewmode)
      in
        draw_nodes_impl_m(recfuel - 1, f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, iadd(i, 1), py, pa, pen_x, pen_line, viewmode)
      end
    end
  ) else draw_nodes_impl_exh(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, i, py, pa, pen_x, pen_line, viewmode)

fun draw_nodes_impl(f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: ViewMode): void = draw_nodes_impl_m(airlock_nat(MAX_REC_FUEL), f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, i, py, pa, pen_x, pen_line, viewmode)

implement line_quote_prefix(d, ls, le) = let
  val p = skip_spaces(d, ls, le)
in
  if ilt(p, le) andalso ieq(doc_byte(d, p), 62) then let
    val next_p = (if ilt(iadd(p, 1), le) andalso ieq(doc_byte(d, iadd(p, 1)), 32) then iadd(p, 2) else iadd(p, 1))
  in
    isub(next_p, ls)
  end else 0
end

fun row_quote_prefix(d: !Doc, rst: int): int = let
  val line = doc_line_of(d, rst)
  val ls = doc_line_start(d, line)
  val le = if ilt(iadd(line, 1), doc_nlines(d)) then doc_line_start(d, iadd(line, 1)) else doc_len(d)
in
  if ieq(rst, ls) then line_quote_prefix(d, ls, le) else 0
end

fun caret_calc_adv(f: !Font, r: !Rend, d: !Doc, rst: int, ren: int, caret: int, scratch: &Buf >> _): int = let
  val scap = buf_cap(scratch)
  val rlen = doc_slice_buf(d, rst, ren, scratch, scap)
  val c_off = imax(0, isub(caret, rst))
in
  anth_ui_caret_adv(f, r, buf_ptr(scratch), rlen, c_off)
end

fun caret_calc_pos(d: !Doc, caret: int, row: &int >> _): @(int, int, int) = let
  val line = doc_line_of(d, caret)
  val ls = doc_line_start(d, line)
  val le = if ilt(iadd(line, 1), doc_nlines(d)) then doc_line_start(d, iadd(line, 1)) else doc_len(d)
  val wc = doc_get_wrap(d)
  val off_cps = doc_codepoints(d, ls, caret)
  val rw = (if wc > 0 then idiv(off_cps, wc) else 0) : int
  val () = row := rw
  val rst = (if wc > 0 then doc_advance_cps(d, ls, le, imul(rw, wc)) else ls) : int
  val ren = (if wc > 0 then doc_advance_cps(d, rst, le, wc) else le) : int
  val p_rst = iadd(rst, row_quote_prefix(d, rst))
in
  @(line, p_rst, imax(p_rst, ren))
end

fun caret_xy(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _, x: &int >> _, y: &int >> _): void =
 if doc_visual_active(d) then let val point=visual_caret_point(f,d,colx,oy,scroll,lh,scratch)
   val ()=x := point.x in y := point.y end else let
  val caret = doc_caret(d)
  var row: int = 0
  val @(line, p_rst, p_ren) = caret_calc_pos(d, caret, row)
  val base_x = row_base_pos(f, r, d, p_rst, p_ren, colx, scratch)
  val scap = buf_cap(scratch)
  val rlen = doc_slice_buf(d, p_rst, p_ren, scratch, scap)
  val adv = anth_ui_caret_adv(f, r, buf_ptr(scratch), rlen, isub(caret, p_rst))
  val yy = isub(iadd(oy, iadd(doc_line_y(d, line), imul(row, lh))), scroll)
  val () = x := iadd(base_x, adv)
  val () = seen_int(lh)
in
  y := yy
end

fun draw_sel_rect(r: !Rend, wa: int, wb: int, colx: int, sy: int, lh: int): void = let
  val xmin = imin(wa, wb)
  val xmax = imax(wa, wb)
  val sx = iadd(colx, xmin)
  val sw = imax(isub(xmax, xmin), 4)
in
  rend_rect(r, sx, sy, sw, lh, col_sel())
end

fun draw_sel_row(f: !Font, r: !Rend, d: !Doc, rst: int, ren: int, a: int, b: int, colx: int, sy: int, lh: int, scratch: &Buf >> _): void = let
  val pfx = row_quote_prefix(d, rst)
  val p_rst = iadd(rst, pfx)
  val p_ren = imax(p_rst, ren)
  val sa = imax(p_rst, a)
  val sb = imin(p_ren, b)
in
  if ilt(sa, sb) then let
    val base_x = row_base_pos(f, r, d, p_rst, p_ren, colx, scratch)
    val scap = buf_cap(scratch)
    val rlen = doc_slice_buf(d, p_rst, p_ren, scratch, scap)
    val at_eol = (if ige(b, p_ren) then 1 else 0) : int
    var rel_sx: int = 0
    var rel_sw: int = 0
    val () = anth_ui_sel_span(f, r, buf_ptr(scratch), rlen, isub(sa, p_rst), isub(sb, p_rst), at_eol, rel_sx, rel_sw)
    val sx = iadd(base_x, rel_sx)
    val sw = rel_sw
  in
    rend_rect(r, sx, sy, sw, lh, col_sel())
  end else ()
end

fun draw_sel_rows_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, ls: int, le: int,
  a: int, b: int, colx: int, base_sy: int, lh: int, wc: int, row: int, rows: int, scratch: &Buf >> _
): void =
  if recfuel > 0 then (
    if ige(row, rows) then ()
    else let
      val rst = (if wc > 0 then doc_advance_cps(d, ls, le, imul(row, wc)) else ls) : int
      val ren = (if wc > 0 then doc_advance_cps(d, rst, le, wc) else le) : int
      val sy = iadd(base_sy, imul(row, lh))
      val () = draw_sel_row(f, r, d, rst, ren, a, b, colx, sy, lh, scratch)
    in
      draw_sel_rows_m(recfuel - 1, f, r, d, ls, le, a, b, colx, base_sy, lh, wc, iadd(row, 1), rows, scratch)
    end
  ) else ()

fun draw_sel_line(f: !Font, r: !Rend, d: !Doc, ls: int, le: int, smin: int, smax: int, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void = let
  val a = imax(ls, smin)
  val b = imin(le, smax)
in
  if ilt(a, b) then let
    val line = doc_line_of(d, ls)
    val sy = isub(iadd(oy, doc_line_y(d, line)), scroll)
    val wc = doc_get_wrap(d)
    val cols = doc_codepoints(d, ls, le)
    val rows = (if wc > 0 andalso igt(cols, wc) then idiv(iadd(cols, isub(wc, 1)), wc) else 1) : int
  in
    if rows <= 1 then draw_sel_row(f, r, d, ls, le, a, b, colx, sy, lh, scratch)
    else draw_sel_rows_m(airlock_nat(MAX_REC_FUEL), f, r, d, ls, le, a, b, colx, sy, lh, wc, 0, rows, scratch)
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

fun draw_selection(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void =
 if doc_visual_active(d) then visual_draw_selection(f,r,d,colx,oy,scroll,lh,scratch) else let
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

fun find_first_vis_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, lo: int, hi: int, target_y: int): int =
  if recfuel > 0 then (
    if ige(lo, hi) then lo
    else let
      val mid = iadd(lo, idiv(isub(hi, lo), 2))
      val y = doc_node_y(d, mid)
      val h = doc_node_height(d, mid)
      val bottom=case+ doc_visual_node_bottom(d,mid) of | None() => iadd(y,h) | Some(value) => value
    in
      if ilt(bottom, target_y) then
        find_first_vis_m(recfuel - 1, d, iadd(mid, 1), hi, target_y)
      else
        find_first_vis_m(recfuel - 1, d, lo, mid, target_y)
    end
  ) else lo

fun rewind_line_start_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, idx: int, target_line: int): int =
  if recfuel > 0 then (
    if ile(idx, 0) then 0
    else let
      val prev = isub(idx, 1)
      val pline = doc_line_of(d, doc_node_start(d, prev))
    in
      if ieq(pline, target_line) then
        rewind_line_start_m(recfuel - 1, d, prev, target_line)
      else idx
    end
  ) else idx

fun first_vis_node(d: !Doc, scroll: int): int = let
  val n = doc_nnodes(d)
in
  if ile(n, 0) then 0
  else if ile(scroll, 0) then 0
  else let
    val raw_idx = find_first_vis_m(airlock_nat(MAX_REC_FUEL), d, 0, n, scroll)
  in
    if ige(raw_idx, n) then raw_idx
    else let
      val target_line = doc_line_of(d, doc_node_start(d, raw_idx))
    in
      rewind_line_start_m(airlock_nat(MAX_REC_FUEL), d, raw_idx, target_line)
    end
  end
end

fun draw_flash_line(r: !Rend, d: !Doc, oy: int, scroll: int, lh: int, colx: int, pw: int): void = let
  val fl = doc_get_flash(d, mono_ns())
in
  if ige(fl, 0) andalso ilt(fl, doc_nlines(d)) then let
    val fy = isub(iadd(oy, doc_line_y(d, fl)), scroll)
    val () = rend_rect(r, colx, fy, column_w(pw), lh, col_rgba(147, 51, 234, 110))
  in
  end else ()
end

fun draw_doc_content(f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, viewmode: ViewMode, colx: int, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val () = draw_flash_line(r, d, oy, scroll, lh, colx, pw)
in
  if doc_nnodes(d) > 0 then let
    val start_i = first_vis_node(d, scroll)
  in
    draw_nodes_impl(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, start_i, py, pa, pen_x, pen_line, viewmode)
  end else if doc_visual_active(d) then
    seen_int(visual_draw_slice(f,r,d,0,doc_len(d),colx,oy,scroll,lh,ph,col_text(),scratch))
  else
    draw_plain_doc(f, r, d, colx, oy, pw, ph, scroll, lh, scratch)
end

fun draw_gutter_num(f: !Font, r: !Rend, line: int, colx: int, yy: int, scratch: &Buf >> _): void = let
  val () = bclear(scratch)
  val () = b_app_int(scratch, iadd(line, 1))
  val slen = buf_len(scratch)
  val tw = font_width_buf(f, r, scratch, slen)
  val num_end = gutter_num_end_x(f, r, colx)
  val tx = isub(num_end, tw)
in
  seen_int(font_draw_buf(f, r, tx, yy, scratch, slen, col_muted()))
end

fun draw_gutter_line(f: !Font, r: !Rend, d: !Doc, line: int, colx: int, oy: int, scroll: int, ph: int, scratch: &Buf >> _): void = let
  val step = doc_line_step(d, line)
in
  if step > 0 then let
    val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
  in
    if ilt(yy, isub(oy, step)) orelse igt(yy, iadd(oy, ph)) then ()
    else draw_gutter_num(f, r, line, colx, yy, scratch)
  end else ()
end

extern fun draw_gutter_range_exh(f: !Font, r: !Rend, d: !Doc, li: int, en: int, colx: int, oy: int, scroll: int, ph: int, scratch: &Buf >> _): void = "mac#anth_die_void"

fun draw_gutter_range_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, li: int, en: int, colx: int, oy: int, scroll: int, ph: int, scratch: &Buf >> _
): void =
  if recfuel > 0 then (
    if ige(li, en) then ()
    else let
      val () = draw_gutter_line(f, r, d, li, colx, oy, scroll, ph, scratch)
    in
      draw_gutter_range_m(recfuel - 1, f, r, d, iadd(li, 1), en, colx, oy, scroll, ph, scratch)
    end
  ) else draw_gutter_range_exh(f, r, d, li, en, colx, oy, scroll, ph, scratch)

fun draw_line_gutter(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, pw: int, ph: int, scroll: int, lh: int, scratch: &Buf >> _): void = let
  val n = doc_nlines(d)
  val start_li = imax(0, isub(line_at_y_fast(d, scroll, lh), 1))
  val end_li = imin(n, iadd(line_at_y_fast(d, iadd(scroll, ph), lh), 2))
in
  draw_gutter_range_m(airlock_nat(MAX_REC_FUEL), f, r, d, start_li, end_li, colx, oy, scroll, ph, scratch)
end

implement draw_doc(f, r, d, ox, oy, pw, ph, scroll, lh0, vault, c, scratch, viewmode) = let
  val lh=if font_text_active(f) then font_document_line_height(f,lh0) else lh0
  val colx = editor_colx(f, r, ox, pw)
  val width=imax(1,imin(column_w(pw),isub(iadd(ox,pw),iadd(colx,16))))
  val colw=if font_text_active(f) then width else column_w(pw)
  val height=prep_doc(f,d,c,r,vault,lh,colw,viewmode)
  var py: int = oy
  var pa: int = 0
  var pen_x: int = colx
  var pen_line: int = ~1
  val () = rend_scissor(r, ox, oy, pw, ph)
  val () = draw_line_gutter(f, r, d, colx, oy, pw, ph, scroll, lh, scratch)
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

fun tab_pane_match(filter: int, tab_pane: !Buf, i: int): bool =
  if filter < 0 then true
  else if i < buf_len(tab_pane) then ieq(buf_get(tab_pane, i), filter)
  else ieq(0, filter)

extern fun draw_tabrow_impl_exh(f: !Font, r: !Rend, ts: Tabs, x: int, active: int, i: int): Tabs = "mac#anth_die_box"

fun draw_tabrow_pane_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, ts: Tabs, x: int, active: int, i: int,
  filter: int, tab_pane: !Buf
): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val match = tab_pane_match(filter, tab_pane, i)
        val tab_w = (if match then tab_item_width(f, r, title) else 0)
        val bx = x
        val next_x = (if match then iadd(bx, iadd(tab_w, 4)) else bx)
        val () = if match then draw_tab_frame(f, r, title, bx, tab_w, i, active) else ()
        val () = touch_doc(doc)
        val () = seen_int(sc)
        val rest2 = draw_tabrow_pane_m(recfuel - 1, f, r, rest, next_x, active, iadd(i, 1), filter, tab_pane)
      in
        TCons(doc, path, title, sc, rest2)
      end
  ) else draw_tabrow_impl_exh(f, r, ts, x, active, i)

implement draw_tabrow_pane(f, r, ts, x, active, i, filter, tab_pane) =
  draw_tabrow_pane_m(airlock_nat(MAX_REC_FUEL), f, r, ts, x, active, i, filter, tab_pane)

implement draw_tabrow(f, r, ts, x, active, i) = let
  var empty_b = buf_make(0)
  val res = draw_tabrow_pane(f, r, ts, x, active, i, ~1, empty_b)
  val () = buf_free(empty_b)
in
  res
end

extern fun tab_hit_test_impl_exh(f: !Font, r: !Rend, ts: !Tabs, x: int, click_x: int, i: int, out_ti: &int >> _, out_close: &bool >> _): void = "mac#anth_die_void"

fun tab_hit_step(f: !Font, r: !Rend, title: !Buf, x: int, click_x: int, i: int, out_ti: &int >> _, out_close: &bool >> _): int = let
  val tlen = buf_len(title)
  val tw = if igt(tlen, 0) then font_width_buf(f, r, title, tlen) else 0
  val tab_w = imin(200, imax(100, iadd(tw, 36)))
  val close_x = isub(iadd(x, tab_w), 24)
in
  if ige(click_x, x) andalso ilt(click_x, iadd(x, tab_w)) then (
    out_ti := i; out_close := ige(click_x, close_x); tab_w
  ) else tab_w
end

fun tab_hit_test_pane_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, ts: !Tabs, x: int, click_x: int, i: int,
  filter: int, tab_pane: !Buf, out_ti: &int >> _, out_close: &bool >> _
): void =
  if recfuel > 0 then (
    case+ ts of
    | TNil() => ()
    | TCons(_, _, title, _, rest) =>
        if tab_pane_match(filter, tab_pane, i) then let
          val tab_w = tab_hit_step(f, r, title, x, click_x, i, out_ti, out_close)
        in
          if ige(out_ti, 0) then ()
          else tab_hit_test_pane_m(recfuel - 1, f, r, rest, iadd(x, iadd(tab_w, 4)), click_x, iadd(i, 1), filter, tab_pane, out_ti, out_close)
        end else tab_hit_test_pane_m(recfuel - 1, f, r, rest, x, click_x, iadd(i, 1), filter, tab_pane, out_ti, out_close)
  ) else tab_hit_test_impl_exh(f, r, ts, x, click_x, i, out_ti, out_close)

implement tab_hit_test_pane(f, r, ts, start_x, click_x, filter, tab_pane, out_ti, out_close) =
  tab_hit_test_pane_m(airlock_nat(MAX_REC_FUEL), f, r, ts, start_x, click_x, 0, filter, tab_pane, out_ti, out_close)

implement tab_hit_test(f, r, ts, start_x, click_x, out_ti, out_close) = let
  var empty_b = buf_make(0)
  val () = tab_hit_test_pane(f, r, ts, start_x, click_x, ~1, empty_b, out_ti, out_close)
  val () = buf_free(empty_b)
in
end

implement tab_find_at_x(f, r, ts, start_x, hover_x, filter, tab_pane) = let
  var ti: int = ~1
  var close: bool = false
  val () = tab_hit_test_pane(f, r, ts, start_x, hover_x, filter, tab_pane, ti, close)
in
  ti
end

fun seal_cs(c: &Cache >> _, scratch: &Buf >> _): void = let
  val saved = c
  val () = c := saved
in
  seen_buf(scratch)
end

fun img_fit_dims(iw: int, ih: int, mw: int, mh: int, out_w: &int >> _, out_h: &int >> _): void =
  if iw <= mw andalso ih <= mh then (out_w := iw; out_h := ih)
  else let
    val fit_h = imax(1, idiv(imul(ih, mw), iw))
  in
    if fit_h <= mh then (out_w := mw; out_h := fit_h)
    else (out_h := mh; out_w := imax(1, idiv(imul(iw, mh), ih)))
  end

fun draw_image_viewer_info(
  f: !Font, r: !Rend, path: !Buf, ox: int, oy: int, pw: int, ph: int, iw: int, ih: int, scratch: &Buf >> _
): void = let
  val () = bclear(scratch)
  val () = base_name(path, scratch)
  val () = bstr(scratch, " (")
  val () = b_app_int(scratch, iw)
  val () = bstr(scratch, "x")
  val () = b_app_int(scratch, ih)
  val () = bstr(scratch, ")")
  val slen = buf_len(scratch)
  val tw = font_width_buf(f, r, scratch, slen)
  val tx = iadd(ox, idiv(isub(pw, tw), 2))
  val ty = isub(iadd(oy, ph), 28)
in
  seen_int(font_draw_buf(f, r, tx, ty, scratch, slen, col_muted()))
end

fun draw_image_viewer_tex(
  f: !Font, r: !Rend, path: !Buf, ox: int, oy: int, pw: int, ph: int,
  tex: uint, iw: int, ih: int, scratch: &Buf >> _
): void = let
  val mw = imax(32, isub(pw, 64))
  val mh = imax(32, isub(ph, 80))
  var dw: int = 0
  var dh: int = 0
  val () = img_fit_dims(iw, ih, mw, mh, dw, dh)
  val qx = iadd(ox, idiv(isub(pw, dw), 2))
  val qy = iadd(oy, idiv(isub(ph, dh), 2))
  val () = rend_quad(r, tex, ShadeRgba, qx, qy, dw, dh, 0.0, 0.0, 1.0, 1.0, col_white())
  val () = ui_draw_border(r, qx, qy, dw, dh, 1, col_line())
in
  draw_image_viewer_info(f, r, path, ox, oy, pw, ph, iw, ih, scratch)
end

fun draw_image_viewer_failed(f: !Font, r: !Rend, path: !Buf, ox: int, oy: int, pw: int, ph: int, scratch: &Buf >> _): void = let
  val p = cstr(path)
  val () = log_warn_at("src/ui_workspace/ui_render.dats", 1108, "VIEWER", "Gorsel yuklenemedi", p)
  val () = bclear(scratch)
  val () = bstr(scratch, "Gorsel yuklenemedi: ")
  val () = base_name(path, scratch)
  val slen = buf_len(scratch)
  val tw = font_width_buf(f, r, scratch, slen)
  val tx = iadd(ox, idiv(isub(pw, tw), 2))
  val ty = iadd(oy, idiv(ph, 2))
in
  seen_int(font_draw_buf(f, r, tx, ty, scratch, slen, col_muted()))
end

implement draw_image_viewer(f, r, path, ox, oy, pw, ph, c, scratch) = let
  val () = rend_rect(r, ox, oy, pw, ph, col_bg())
  var iw: int = 0
  var ih: int = 0
  val tex = ensure_tex(c, path, r, iw, ih)
in
  if ine(uok(tex), 0) andalso igt(iw, 0) andalso igt(ih, 0) then
    draw_image_viewer_tex(f, r, path, ox, oy, pw, ph, tex, iw, ih, scratch)
  else
    draw_image_viewer_failed(f, r, path, ox, oy, pw, ph, scratch)
end

fun draw_tab_content(
  f: !Font, r: !Rend, doc: !Doc, path: !Buf, ox: int, oy: int, pw: int, ph: int,
  sc: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, viewmode: ViewMode
): void =
  if is_image_path(path) then
    draw_image_viewer(f, r, path, ox, oy, pw, ph, c, scratch)
  else
    draw_doc(f, r, doc, ox, oy, pw, ph, sc, lh, vault, c, scratch, viewmode)

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
        val () = if ieq(i, idx) then draw_tab_content(f, r, doc, path, ox, oy, pw, ph, sc, lh, vault, c, scratch, viewmode) else seal_cs(c, scratch)
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
      val k = doc_node_kind(d, i)
    in
      if is_inline(k) then node_covering_impl_m(recfuel - 1, d, y, oy, scroll, iadd(i, 1), best)
      else let
        val sy = isub(iadd(oy, doc_node_y(d, i)), scroll)
        val h = doc_node_height(d, i)
        val best2 = if igt(h, 0) andalso ige(y, sy) andalso ilt(y, iadd(sy, h)) then i else best
      in
        node_covering_impl_m(recfuel - 1, d, y, oy, scroll, iadd(i, 1), best2)
      end
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

fun click_place(f: !Font, r: !Rend, d: !Doc, x: int, rst: int, ren: int, colx: int, scratch: &Buf >> _, keep: Toggle): void = let
  val pfx = row_quote_prefix(d, rst)
  val p_rst = iadd(rst, pfx)
  val p_ren = imax(p_rst, ren)
  val base_x = row_base_pos(f, r, d, p_rst, p_ren, colx, scratch)
  val scap = buf_cap(scratch)
  val llen = doc_slice_buf(d, p_rst, p_ren, scratch, scap)
  val target_x = isub(x, base_x)
  val off = anth_ui_click_off(f, r, buf_ptr(scratch), llen, target_x)
  val i0 = iadd(p_rst, off)
in
  if is_on(keep) then doc_set_caret_extend(d, i0) else doc_set_caret_move(d, i0)
end

fun click_doc(f: !Font, r: !Rend, d: !Doc, x: int, y: int, ox: int, pw: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _, keep: Toggle, hitk: &NodeKind >> _, hiti: &int >> _): void = let
  val docy = iadd(isub(y, oy), scroll)
  val line = imax(0, line_at_y_fast(d, docy, lh))
  val colx = editor_colx(f, r, ox, pw)
  val arr_min = gutter_num_end_x(f, r, colx)
  val is_arrow_col = ige(x, arr_min) andalso ilt(x, colx)
  val f_ni = (if is_arrow_col then doc_line_node_foldable(d, line) else ~1) : int
  val ni = (if ige(f_ni, 0) then f_ni else node_covering_impl(d, y, oy, scroll, 0, ~1)) : int
  val hk = (if ige(ni, 0) then doc_node_kind(d, ni) else KNone) : NodeKind
  val () = (hitk := hk; hiti := ni)
  val ls = doc_line_start(d, line)
  val le = if ilt(iadd(line, 1), doc_nlines(d)) then doc_line_start(d, iadd(line, 1)) else doc_len(d)
  val ly = doc_line_y(d, line)
  val wc = doc_get_wrap(d)
  val row = (if wc > 0 andalso igt(lh, 0) then idiv(imax(0, isub(docy, ly)), lh) else 0) : int
  val rst = (if wc > 0 then doc_advance_cps(d, ls, le, imul(row, wc)) else ls) : int
  val ren = (if wc > 0 then doc_advance_cps(d, rst, le, wc) else le) : int
in
  if ige(ni, 0) andalso (is_kind(hk, KImage) orelse is_kind(hk, KEmbed)) then doc_set_caret_move(d, doc_node_start(d, ni))
  else if doc_visual_active(d) then let
    val target=visual_click_source(f,d,x,y,colx,oy,scroll,lh,scratch)
  in if is_on(keep) then doc_set_caret_extend(d,target) else doc_set_caret_move(d,target) end
  else click_place(f, r, d, x, rst, ren, colx, scratch, keep)
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
