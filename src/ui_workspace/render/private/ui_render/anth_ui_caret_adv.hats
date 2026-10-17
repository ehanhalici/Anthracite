extern fun anth_ui_caret_adv(f: !Font, r: !Rend, line: ptr, line_len: int, off: int): int = "mac#anth_ui_caret_adv"
extern fun anth_ui_click_off(f: !Font, r: !Rend, line: ptr, line_len: int, target_x: int): int = "mac#anth_ui_click_off"
extern fun anth_ui_sel_span(f: !Font, r: !Rend, line: ptr, line_len: int, sa: int, sb: int, at_eol: int, out_sx: &int >> _, out_sw: &int >> _): void = "mac#anth_ui_sel_span"
staload "ui_workspace/text/ui_text_engine.sats"
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
  val le = if igt(le0, ls) andalso ieq(doc_byte(d, isub(le0, 1)), CHAR_LF) then isub(le0, 1) else le0
in
  row_base_pos(f, r, d, ls, le, colx, scratch)
end

extern fun cache_free_fuel_exhausted(c: Cache): void = "mac#anth_die_void"

fun cache_free_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), c: Cache): void =
  if recursion_fuel_available(recfuel) then (
    case+ c of
    | ~CNil() => ()
    | ~CCons(p, t, _, _, rest) => let
        val () = buf_free(p)
        val () = rend_tex_free(t)
      in
        cache_free_with_fuel(recfuel - 1, rest)
      end
    | ~CEmbed(p, _, doc, _, _, rest) => let
        val () = buf_free(p)
        val () = doc_free(doc)
      in
        cache_free_with_fuel(recfuel - 1, rest)
      end
  ) else cache_free_fuel_exhausted(c)

implement cache_free(c) = cache_free_with_fuel(airlock_nat(MAX_REC_FUEL), c)

extern fun cache_lookup_fuel_exhausted(c: Cache, path: !Buf, tex: &uint >> _, w: &int >> _, h: &int >> _, hit: &Toggle >> _): Cache = "mac#anth_die_box"

fun cache_accept(p: Buf, t: uint, iw: int, ih: int, rest: Cache, tex: &uint >> _, w: &int >> _, h: &int >> _, hit: &Toggle >> _): Cache = let
  val () = tex := t
  val () = w := iw
  val () = h := ih
  val () = hit := On
in
  CCons(p, t, iw, ih, rest)
end

fun cache_lookup_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), c: Cache, path: !Buf, tex: &uint >> _, w: &int >> _, h: &int >> _, hit: &Toggle >> _): Cache =
  if recursion_fuel_available(recfuel) then (
    case+ c of
    | ~CNil() => let
        val () = hit := Off
      in
        CNil()
      end
    | ~CCons(p, t, iw, ih, rest) =>
        if buffer_equal_from(p, path, 0) then cache_accept(p, t, iw, ih, rest, tex, w, h, hit)
        else let
          val rest2 = cache_lookup_with_fuel(recfuel - 1, rest, path, tex, w, h, hit)
        in
          CCons(p, t, iw, ih, rest2)
        end
    | ~CEmbed(p, mt, doc, cw, lh, rest) => let
        val rest2 = cache_lookup_with_fuel(recfuel - 1, rest, path, tex, w, h, hit)
      in
        CEmbed(p, mt, doc, cw, lh, rest2)
      end
  ) else cache_lookup_fuel_exhausted(c, path, tex, w, h, hit)

fun cache_lookup(c: Cache, path: !Buf, tex: &uint >> _, w: &int >> _, h: &int >> _, hit: &Toggle >> _): Cache = cache_lookup_with_fuel(airlock_nat(MAX_REC_FUEL), c, path, tex, w, h, hit)

fun cache_put(c: Cache, path: Buf, tex: uint, w: int, h: int): Cache =
  CCons(path, tex, w, h, c)

#define MAX_EMBED_CACHE_ENTRIES 48

fun restore_texture_entry(p: Buf,t: uint,w: int,h: int,result: @(Option_vt(Doc),Cache)): @(Option_vt(Doc),Cache) = let
  val @(document,rest)=result
in @(document,CCons(p,t,w,h,rest)) end

fun cache_take_embed_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), c: Cache, path: !Buf, cur_mt: EmbedSourceStamp
): @(Option_vt(Doc), Cache) =
  if recursion_fuel_available(recfuel) then (
    case+ c of
    | ~CNil() => @(None_vt(), CNil())
    | ~CCons(p, t, iw, ih, rest) =>
        restore_texture_entry(p,t,iw,ih,cache_take_embed_with_fuel(recfuel - 1,rest,path,cur_mt))
    | ~CEmbed(p, mt, doc, cw, lh, rest) =>
        if buffer_equal_from(p, path, 0) then
          if embedded_source_equal(mt,cur_mt) then (buf_free(p); @(Some_vt(doc), rest))
          else let
            val () = (buf_free(p); doc_free(doc))
          in
            cache_take_embed_with_fuel(recfuel - 1, rest, path, cur_mt)
          end
        else let
          val @(opt, rest2) = cache_take_embed_with_fuel(recfuel - 1, rest, path, cur_mt)
        in
          @(opt, CEmbed(p, mt, doc, cw, lh, rest2))
        end
  ) else @(None_vt(), c)

fun cache_take_embed(c: Cache, path: !Buf, cur_mt: EmbedSourceStamp): @(Option_vt(Doc), Cache) =
  cache_take_embed_with_fuel(airlock_nat(MAX_REC_FUEL), c, path, cur_mt)

fun count_embeds_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), c: !Cache, acc: int): int =
  if recursion_fuel_available(recfuel) then (
    case+ c of
    | CNil() => acc
    | CCons(_, _, _, _, rest) => count_embeds_with_fuel(recfuel - 1, rest, acc)
    | CEmbed(_, _, _, _, _, rest) => count_embeds_with_fuel(recfuel - 1, rest, iadd(acc, 1))
  ) else acc

fun trim_embeds_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), c: Cache, keep: int, cur: &int >> _): Cache =
  if recursion_fuel_available(recfuel) then (
    case+ c of
    | ~CNil() => CNil()
    | ~CCons(p, t, iw, ih, rest) =>
        CCons(p,t,iw,ih,trim_embeds_with_fuel(recfuel - 1,rest,keep,cur))
    | ~CEmbed(p, mt, doc, cw, lh, rest) => let
        val idx = cur
        val () = cur := iadd(cur, 1)
      in
        if ilt(idx, keep) then
          CEmbed(p, mt, doc, cw, lh, trim_embeds_with_fuel(recfuel - 1, rest, keep, cur))
        else let
          val () = (buf_free(p); doc_free(doc))
        in
          trim_embeds_with_fuel(recfuel - 1, rest, keep, cur)
        end
      end
  ) else c

fun cache_put_embed(c: Cache, path: Buf, mt: EmbedSourceStamp, doc: Doc, cw: int, lh: int): Cache = let
  val n = count_embeds_with_fuel(airlock_nat(MAX_REC_FUEL), c, 0)
in
  if ige(n, MAX_EMBED_CACHE_ENTRIES) then let
    var cur: int = 0
    val c2 = trim_embeds_with_fuel(airlock_nat(MAX_REC_FUEL), c, isub(MAX_EMBED_CACHE_ENTRIES, 1), cur)
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
  if is_scan(mode, ScanSeek) andalso ilt(iadd(i0, 1), b0) andalso ieq(doc_byte(d, i0), CHAR_LBRACKET) andalso ieq(doc_byte(d, iadd(i0, 1)), CHAR_LBRACKET) then
    @(ScanCopy(), iadd(i0, 2))
  else if is_scan(mode, ScanSeek) andalso ieq(doc_byte(d, i0), CHAR_LPAREN) then
    @(ScanCopy(), iadd(i0, 1))
  else if is_scan(mode, ScanCopy) andalso (ieq(doc_byte(d, i0), CHAR_PIPE) orelse ieq(doc_byte(d, i0), CHAR_HASH) orelse ieq(doc_byte(d, i0), CHAR_RBRACKET) orelse ieq(doc_byte(d, i0), CHAR_RPAREN)) then
    @(ScanDone(), b0)
  else let
    val () = if is_scan(mode, ScanCopy) then buf_push(dst, doc_byte(d, i0)) else ()
  in
    @(mode, iadd(i0, 1))
  end

extern fun take_path_fuel_exhausted(d: !Doc, mode: PathScan, i0: int, b0: int, dst: &Buf >> _): void = "mac#anth_die_void"

fun take_path_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, mode: PathScan, i0: int, b0: int, dst: &Buf >> _): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(i0, b0) then let
      val nxt = take_advance(d, mode, i0, b0, dst)
    in
      take_path_with_fuel(recfuel - 1, d, nxt.0, nxt.1, b0, dst)
    end else ()
  ) else take_path_fuel_exhausted(d, mode, i0, b0, dst)
