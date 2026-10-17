fun on_up_drop(s: &App_record >> _, f: !Font, r: !Rend, w: int, x: int, y: int): void =
  case+ s.drag of
  | DragNone() => ()
  | DragSplit() => save_app_session(s)
  | DragFile() => if ige(s.sel, 0) then on_up_move_file(s, y) else ()
  | DragTab() => on_up_drag_tab(s, w, x, y)
  | DragEditor() => on_up_editor(s, x, y)

fun on_up_clamp_active(s: &App_record >> _): void = let
  val n = tabs_len(s.tabs)
  val () = if ige(s.active, n) then s.active := imax(0, isub(n, 1)) else ()
  val () = if ilt(s.active, 0) then s.active := 0 else ()
in
end

fun on_up(a: !App, f: !Font, r: !Rend, ev: &event, w: int): void =
  case+ a of
  | @APP(s) => let
      val x = ev_x(ev)
      val y = ev_y(ev)
      val () = on_up_drop(s, f, r, w, x, y)
      val () = s.drag := DragNone
      val () = s.dragi := ~1
      val () = s.downx := ~1
      val () = s.downy := ~1
      val () = app_fsm_step(s, ActEndSplitDrag())
      val () = on_up_clamp_active(s)
    in
      fold@(a)
    end

fun scroll_tree(s: &App_record >> _, delta: int, h: int): void = let
  val visible_rows = imax(1, idiv(imax(0, isub(h, 72)), UI_TREE_ROW_HEIGHT))
  val max_scroll = imax(0, isub(tree_visible_count(s), visible_rows))
in
  s.treescroll := imax(0, imin(max_scroll, iadd(s.treescroll, delta)))
end

fun scroll_search(s: &App_record >> _, delta: int, h: int): void = let
  val total=search_visible_count(s.hmeta,s.ixq)
  val max_scroll = imax(0, isub(total, s.search_layout.rows))
  val () = seen_int(h)
in
  s.hscroll := imax(0, imin(max_scroll, iadd(s.hscroll, delta)))
end

fun scroll_document(s: &App_record >> _, delta: int): void = let
  val idx = pane_of(s.focus, s.active, s.righti)
  val ts = s.tabs
  val () = s.tabs := TNil()
  val ph = s.tabs
  val () = s.tabs := tabs_scroll(ts, idx, delta, 100000)
in
  tabs_free(ph)
end

fun on_wheel(a: !App, ev: &event, w: int, h: int): void =
  case+ a of
  | @APP(s) => let
      val upward = is_btn(button_of(ev_button(ev)), BtnWheelUp)
      val on_tree = is_side_files(s.side) andalso ilt(ev_x(ev), s.sidew)
        andalso ige(ev_y(ev), UI_TOPBAR_HEIGHT)
      val on_search = is_side_search(s.side) andalso ilt(ev_x(ev), s.sidew)
        andalso ige(ev_y(ev), UI_TOPBAR_HEIGHT)
      val () = if on_search then scroll_search(s, if upward then ~3 else 3, h)
        else if on_tree then scroll_tree(s, if upward then ~3 else 3, h)
        else scroll_document(s, if upward then ~48 else 48)
      val () = seen_int(w)
    in
      fold@(a)
    end

fun on_sel_paste(s: &App_record >> _, p: !Plat, ev: &event): void = let
  val cap = buf_cap(s.scratch)
  val n = plat_read_buf(p, ev, s.scratch, cap)
  val idx = pane_of(s.focus, s.active, s.righti)
  val ts = s.tabs
  val () = s.tabs := TNil()
  val ph = s.tabs
  val ts2 = tabs_ins_buf(ts, idx, s.scratch, n)
  val () = tabs_sync_vfs(ts2, idx)
  val () = s.tabs := ts2
  val () = tabs_free(ph)
  val () = s.paste := Off
in
end

fun on_sel(a: !App, p: !Plat, ev: &event): void =
  case+ a of
  | @APP(s) => let
      val k = event_of(ev_kind(ev))
      val nclip = buf_len(s.clip)
      val () = if is_ev(k, EvSelReq) then plat_reply_buf(p, ev, s.clip, nclip)
        else if is_ev(k, EvSelNotify) andalso is_on(s.paste) then on_sel_paste(s, p, ev)
        else ()
    in
      fold@(a)
    end

fun prepare_chrome(a: !App, f: !Font, r: !Rend): void =
  case+ a of
  | @APP(s) => let
      val () = load_font_if_needed(f, s)
      val () = ensure_chrome(f, r, s)
    in
      fold@(a)
    end

implement app_event(a, p, f, r, ev, w, h) = let
  val () = prepare_chrome(a, f, r)
  val k = event_of(ev_kind(ev))
in
  if is_ev(k, EvKey) then on_key(a, p, f,r, ev)
  else if is_ev(k, EvDown) then on_down(a, p, f, r, ev, w, h)
  else if is_ev(k, EvUp) then on_up(a, f, r, ev, w)
  else if is_ev(k, EvMotion) then on_motion(a, f, r, ev, w)
  else if is_ev(k, EvWheel) then on_wheel(a, ev, w, h)
  else if is_ev(k, EvSelReq) orelse is_ev(k, EvSelNotify) then on_sel(a, p, ev)
  else ()
end
extern fun find_img_fuel_exhausted(doc: !Doc, i: int): int = "mac#anth_die_int"

fun find_img_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), doc: !Doc, i: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(i, doc_nnodes(doc)) then ~1
    else if is_kind(doc_node_kind(doc, i), KImage) then i
    else find_img_with_fuel(recfuel - 1, doc, iadd(i, 1))
  ) else find_img_fuel_exhausted(doc, i)

fun find_img(doc: !Doc, i: int): int = find_img_with_fuel(airlock_nat(MAX_REC_FUEL), doc, i)

fun selftest_write_notes(root: string): int = let
  val f1 = selftest_fixture_path(root, "a.md")
  val f2 = selftest_fixture_path(root, "b.md")
  var body = buf_make(32)
  val () = buffer_append_string(body, "anthracite bir\n")
  val w1 = write_text(f1, body)
  val () = buffer_clear(body)
  val () = buffer_append_string(body, "anthracite iki\n")
  val w2 = write_text(f2, body)
  val () = buf_free(f1)
  val () = buf_free(f2)
  val () = buf_free(body)
in
  (if ieq(w1, 1) andalso ieq(w2, 1) then 1 else 0)
end

fun selftest_search(d1: !Buf): int = let
  var q = buf_make(16)
  val () = buffer_append_string(q, "anthracite")
  val writes_ok = selftest_write_notes(buffer_c_string(d1))
  var hits = buf_make(64)
  var hmeta = buf_make(64)
  var hn: int = 0
  val () = refresh_search(d1, q, hits, hmeta, hn)
  val search_ok = if ige(hn, 2) andalso ieq(writes_ok, 1) then 1 else 0
  val () = buf_free(q)
  val () = buf_free(hits)
  val () = buf_free(hmeta)
in
  search_ok
end

fun selftest_img_resize(r: !Rend, root: string): int = let
  val f=font_open()
  val doc = doc_open()
  val s = "![[anth-t.png|68x90]]\n"
  val () = doc_insert(doc, c_str_ptr(s), c_strlen(s))
  var cache = CNil()
  var vault = buf_make(8)
  val () = buffer_append_string(vault, root)
  val _ = prepare_document_layout(f,doc, cache, r, vault, 18, 720, ViewEdit)
  val ()=font_free(f)
  val ii = find_img(doc, 0)
  val ih = if ige(ii, 0) then doc_node_height(doc, ii) else 0
  val ok = if ieq(ih, 90) then 1 else 0
  val () = doc_free(doc)
  val () = buf_free(vault)
  val () = cache_free(cache)
in
  ok
end

fun selftest_external_link(): int = let
  val doc = doc_open()
  val s = "Check [MathJax](https://www.mathjax.org/) here\n"
  val () = doc_insert(doc, c_str_ptr(s), c_strlen(s))
  val lnk = find_link(doc, 10, 0)
  var url = buf_make(16)
  val () = take_if(doc, lnk, url, toggle_of(ige(lnk, 0)))
  val ext = is_external_prefix(url)
  val ok = if ige(lnk, 0) andalso ext then 1 else 0
  val () = buf_free(url)
  val () = doc_free(doc)
in
  ok
end

fun selftest_quote_prefix(): int = let
  val doc = doc_open()
  val s = "> [!NOTE] Not\n"
  val () = doc_insert(doc, c_str_ptr(s), c_strlen(s))
  val pfx = line_quote_prefix(doc, 0, 13)
  val ok = if ieq(pfx, 2) then 1 else 0
  val () = doc_free(doc)
in
  ok
end
