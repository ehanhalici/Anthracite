extern fun doc_seek_anchor_fuel_exhausted(d: !Doc, n: int, a: !Buf, al: int, i: int): int = "mac#anth_die_int"

fun doc_seek_anchor_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, n: int, a: !Buf, al: int, i: int
): int =
  if recursion_fuel_available(recfuel) then (
    if igt(iadd(i, al), n) then ~1
    else if doc_seek_sub_at_with_fuel(airlock_nat(MAX_REC_FUEL), d, n, a, al, i, 0) then i
    else doc_seek_anchor_with_fuel(recfuel - 1, d, n, a, al, iadd(i, 1))
  ) else doc_seek_anchor_fuel_exhausted(d, n, a, al, i)

fun doc_jump_anchor(d: !Doc, anchor: &Buf >> _, cur_sc: int): int = let
  val alen = buf_len(anchor)
in
  if igt(alen, 0) then let
    val pos = doc_seek_anchor_with_fuel(airlock_nat(MAX_REC_FUEL), d, doc_len(d), anchor, alen, 0)
  in
    if ige(pos, 0) then let
      val () = doc_set_caret_move(d, pos)
      val line = doc_line_of(d, pos)
      val () = doc_set_flash(d, line, mono_ns() + 1000000000L)
      val ly = doc_line_y(d, line)
    in
      imax(0, isub(ly, 350))
    end else cur_sc
  end else cur_sc
end


fun take_anchor_if(doc: !Doc, w: int, anchor: &Buf >> _, go: Toggle): void =
  if is_on(go) then take_anchor(doc, w, anchor) else buffer_preserve(anchor)

fun take_if(doc: !Doc, w: int, rel: &Buf >> _, go: Toggle): void =
  if is_on(go) then take_path(doc, w, rel) else buffer_preserve(rel)

fun doc_jump_if(d: !Doc, anchor: &Buf >> _, cur_sc: int, go: Toggle): int =
  if is_on(go) then doc_jump_anchor(d, anchor, cur_sc)
  else let
    val () = buffer_preserve(anchor)
  in
    cur_sc
  end

extern fun tabs_jump_anchor_fuel_exhausted(ts: Tabs, idx: int, anchor: &Buf >> _): Tabs = "mac#anth_die_box"

fun tabs_jump_anchor_with_fuel {recfuel:nat} .<recfuel, 1>. (
  recfuel: int(recfuel), ts: Tabs, idx: int, anchor: &Buf >> _
): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => let
        val () = buffer_preserve(anchor)
      in
        TNil()
      end
    | ~TCons(doc, path, title, sc, rest) =>
        tabs_jump_anchor_cons(recfuel, doc, path, title, sc, rest, idx, anchor)
  ) else let
    val () = buffer_preserve(anchor)
  in
    tabs_jump_anchor_fuel_exhausted(ts, idx, anchor)
  end
and tabs_jump_anchor_cons {recfuel:nat} .<recfuel, 0>. (
  recfuel: int(recfuel), doc: Doc, path: Buf, title: Buf, sc: int, rest: Tabs, idx: int, anchor: &Buf >> _
): Tabs = let
  val nsc = doc_jump_if(doc, anchor, sc, toggle_of(ieq(idx, 0)))
in
  if ieq(idx, 0) then let
    val () = buffer_preserve(anchor)
  in
    TCons(doc, path, title, nsc, rest)
  end else if recursion_fuel_available(recfuel) then
    TCons(doc, path, title, sc, tabs_jump_anchor_with_fuel(recfuel - 1, rest, isub(idx, 1), anchor))
  else let
    val () = buffer_preserve(anchor)
  in
    tabs_jump_anchor_fuel_exhausted(TCons(doc, path, title, sc, rest), idx, anchor)
  end
end

fun tabs_jump_anchor(ts: Tabs, idx: int, anchor: &Buf >> _): Tabs =
  tabs_jump_anchor_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, anchor)

fun jump_tab_anchor_if(ts: Tabs, anchor: &Buf >> _, go: Toggle): Tabs =
  if is_on(go) then tabs_jump_anchor(ts, isub(tabs_len(ts), 1), anchor)
  else let
    val () = buffer_preserve(anchor)
  in
    ts
  end

fun wiki_target_prep(doc: !Doc, vault: !Buf, w: int, anchor: &Buf >> _, shown: &Buf >> _): int = let
  var rel = buf_make(WIKI_TARGET_PREP_REL_INITIAL_BYTES)
  var full = buf_make(WIKI_TARGET_PREP_FULL_INITIAL_BYTES)
  val has_w = toggle_of(ige(w, 0))
  val () = take_if(doc, w, rel, has_w)
  val () = take_anchor_if(doc, w, anchor, has_w)
  val rlen = buf_len(rel)
  val () = resolve_path(vault, rel, full)
  val () = with_md(full, shown)
  val () = buf_free(rel)
  val () = buf_free(full)
in
  rlen
end

fun is_external_prefix(b: !Buf): bool = let
  val n = buf_len(b)
in
  if n >= 7 andalso ieq(buf_get(b, 0), 104) andalso ieq(buf_get(b, 1), 116)
            andalso ieq(buf_get(b, 2), 116) andalso ieq(buf_get(b, 3), 112) then true
  else if n >= 4 andalso ieq(buf_get(b, 0), 119) andalso ieq(buf_get(b, 1), 119)
                 andalso ieq(buf_get(b, 2), 119) andalso ieq(buf_get(b, 3), CHAR_DOT) then true
  else if n >= 7 andalso ieq(buf_get(b, 0), 109) andalso ieq(buf_get(b, 1), CHAR_LOWER_A)
                 andalso ieq(buf_get(b, 2), 105) andalso ieq(buf_get(b, 3), 108) then true
  else if n >= 6 andalso ieq(buf_get(b, 0), 102) andalso ieq(buf_get(b, 1), 116)
                 andalso ieq(buf_get(b, 2), 112) andalso ieq(buf_get(b, 3), CHAR_COLON) then true
  else false
end

extern fun find_link_fuel_exhausted(doc: !Doc, caret: int, k: int): int = "mac#anth_die_int"

fun find_link_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), doc: !Doc, caret: int, k: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(k, doc_nnodes(doc)) then ~1
    else if ile(doc_node_start(doc, k), caret) andalso
            ilt(caret, doc_node_end(doc, k)) andalso
            is_kind(doc_node_kind(doc, k), KLink) then k
    else find_link_with_fuel(recfuel - 1, doc, caret, iadd(k, 1))
  ) else find_link_fuel_exhausted(doc, caret, k)

fun find_link(doc: !Doc, caret: int, k: int): int =
  find_link_with_fuel(airlock_nat(MAX_REC_FUEL), doc, caret, k)

fun open_url_if(url: !Buf, go: bool): void =
  if go then fs_open_url(buffer_c_string(url)) else ()

fun handle_link_click(doc: !Doc, lnk: int, vault: !Buf, anchor: &Buf >> _, shown: &Buf >> _): int = let
  var url = buf_make(HANDLE_LINK_CLICK_URL_INITIAL_BYTES)
  val () = take_path(doc, lnk, url)
  val is_ext = is_external_prefix(url)
  val () = open_url_if(url, is_ext)
  val () = buf_free(url)
in
  if is_ext then ~2 else wiki_target_prep(doc, vault, lnk, anchor, shown)
end

fun tabs_wiki_prep_here(doc: !Doc, vault: !Buf, anchor: &Buf >> _, shown: &Buf >> _): int = let
  val caret = doc_caret(doc)
  val lnk = find_link(doc, caret, 0)
in
  if ige(lnk, 0) then handle_link_click(doc, lnk, vault, anchor, shown)
  else let
    val w = find_wiki(doc, caret, 0)
  in
    if ilt(w, 0) then ~1 else wiki_target_prep(doc, vault, w, anchor, shown)
  end
end

extern fun tabs_wiki_prep_fuel_exhausted(ts: !Tabs, idx: int, vault: !Buf, anchor: &Buf >> _, shown: &Buf >> _): int = "mac#anth_die_int"

fun tabs_wiki_prep_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), ts: !Tabs, idx: int, vault: !Buf, anchor: &Buf >> _, shown: &Buf >> _
): int =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | TNil() => ~1
    | TCons(doc, path, title, sc, rest) =>
        if ieq(idx, 0) then tabs_wiki_prep_here(doc, vault, anchor, shown)
        else tabs_wiki_prep_with_fuel(recfuel - 1, rest, isub(idx, 1), vault, anchor, shown)
  ) else tabs_wiki_prep_fuel_exhausted(ts, idx, vault, anchor, shown)

fun tabs_wiki_prep(ts: !Tabs, idx: int, vault: !Buf, anchor: &Buf >> _, shown: &Buf >> _): int =
  tabs_wiki_prep_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, vault, anchor, shown)

fun tabs_jump_anchor_if(ts: Tabs, idx: int, anchor: &Buf >> _, alen: int): Tabs =
  if igt(alen, 0) then tabs_jump_anchor(ts, idx, anchor)
  else let
    val () = buffer_preserve(anchor)
  in
    ts
  end

fun wiki_open_existing(ts: Tabs, existing: int, anchor: &Buf >> _, alen: int, target_act: &int >> _): Tabs = let
  val ts2 = tabs_jump_anchor_if(ts, existing, anchor, alen)
  val () = target_act := existing
in
  ts2
end

fun wiki_open_new(ts: Tabs, anchor: &Buf >> _, shown: Buf, alen: int, target_act: &int >> _): Tabs = let
  val ts2 = tabs_open(ts, shown)
  val new_idx = isub(tabs_len(ts2), 1)
  val ts3 = tabs_jump_anchor_if(ts2, new_idx, anchor, alen)
  val () = target_act := new_idx
in
  ts3
end
