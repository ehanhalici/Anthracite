fun selftest_fm_check(): int = let
  val d2 = doc_open()
  val () = put_str(d2, "---\ntitle: x\n---\n")
  val fm = has_kind(d2, KFm, 0)
  val () = doc_free(d2)
in
  fm
end

fun selftest_print_kinds_1(d: !Doc, gap_ok: Toggle): int = let
  val h = has_kind(d, KH1, 0)
  val li = has_kind(d, KLi, 0)
  val task = has_kind(d, KTask, 0)
  val code = has_kind(d, KCode, 0)
  val () = println! ("gap=", toggle_int(gap_ok), " h=", h, " li=", li, " task=", task, " code=", code)
in
  (if is_on(gap_ok) andalso ieq(h, 1) andalso ieq(li, 1) andalso ieq(task, 1) andalso ieq(code, 1) then 1 else 0)
end

fun selftest_print_kinds_2(d: !Doc): int = let
  val table = has_kind(d, KTable, 0)
  val quote = has_kind(d, KQuote, 0)
  val wiki = has_kind(d, KWiki, 0)
  val img = has_kind(d, KImage, 0)
  val tag = has_kind(d, KTag, 0)
  val () = println! ("table=", table, " quote=", quote, " wiki=", wiki, " img=", img, " tag=", tag)
in
  (if ieq(table, 1) andalso ieq(quote, 1) andalso ieq(wiki, 1) andalso ieq(img, 1) andalso ieq(tag, 1) then 1 else 0)
end

fun selftest_print_kinds_3(d: !Doc, fm: int): int = let
  val high = has_kind(d, KHigh, 0)
  val math = has_kind(d, KMath, 0)
  val mathb = has_kind(d, KMathb, 0)
  val fndef = has_kind(d, KFndef, 0)
  val () = println! ("high=", high, " math=", math, " mathb=", mathb, " fn=", fndef, " fm=", fm)
in
  (if ieq(high, 1) andalso ieq(math, 1) andalso ieq(mathb, 1) andalso ieq(fndef, 1) andalso ieq(fm, 1) then 1 else 0)
end

fun selftest_markdown_part(d: !Doc): int = let
  val gap_ok = selftest_gap_check(d)
  val () = selftest_fill_markdown(d)
  val fm = selftest_fm_check()
  val k1 = selftest_print_kinds_1(d, toggle_of(ieq(gap_ok, 1)))
  val k2 = selftest_print_kinds_2(d)
  val k3 = selftest_print_kinds_3(d, fm)
in
  (if ieq(k1, 1) andalso ieq(k2, 1) andalso ieq(k3, 1) then 1 else 0)
end

fun selftest_fill_d3(d3: !Doc): void = let
  val () = fill_paras(d3, 0)
  val mid = idiv(doc_len(d3), 2)
  val () = doc_set_caret_move(d3, mid)
  val () = put_str(d3, "Z")
in
end

fun selftest_fold_flag(d: !Doc, hi: int): int =
  (if ilt(hi, 0) then 0 else (if ieq(doc_get(d, hi, 4), 1) andalso ieq(doc_get(d, iadd(hi, 1), 5), 0) then 1 else 0))

fun selftest_tagline_check(): int = let
  val d4 = doc_open()
  val () = put_str(d4, "#etiket/alt\n")
  val tl = (if ieq(has_kind(d4, KTag, 0), 1) andalso ilt(doc_nnodes(d4), 8) then 1 else 0) : int
  val () = doc_free(d4)
in
  tl
end

fun selftest_column_check(): int =
  (if ieq(column_w(1000), 850) andalso ieq(column_w(800), 800) andalso ieq(column_w(400), 400) andalso ieq(column_x(0, 1000), 75) then 1 else 0)

fun selftest_layout_part(d: !Doc): int = let
  val d3 = doc_open()
  val () = selftest_fill_d3(d3)
  val sp = doc_span(d3)
  val inc = (if ilt(sp, 80) andalso igt(doc_len(d3), 500) then 1 else 0) : int
  val () = doc_free(d3)
  val y0 = doc_layout(d, 18)
  val hi = first_heading(d, 0)
  val () = doc_toggle(d, hi)
  val y1 = doc_layout(d, 18)
  val folded = selftest_fold_flag(d, hi)
  val tagline = selftest_tagline_check()
  val col = selftest_column_check()
  val () = println! ("span=", sp, " inc=", inc, " fold=", folded, " y0=", y0, " y=", y1, " col=", col, " tl=", tagline)
in
  (if ieq(inc, 1) andalso ieq(folded, 1) andalso ieq(col, 1) andalso ieq(tagline, 1) then 1 else 0)
end

fun selftest_nav_check(): int = let
  val d_nav = doc_open()
  val () = put_str(d_nav, "hello world anthracite\n")
  val () = doc_doc_end_move(d_nav)
  val end_c = doc_caret(d_nav)
  val () = doc_word_left_move(d_nav)
  val w_left1 = doc_caret(d_nav)
  val () = doc_word_left_move(d_nav)
  val w_left2 = doc_caret(d_nav)
  val () = doc_doc_start_move(d_nav)
  val start_c = doc_caret(d_nav)
  val () = doc_word_right_move(d_nav)
  val w_right1 = doc_caret(d_nav)
  val () = doc_del_word_right(d_nav)
  val del_len = doc_len(d_nav)
  val () = doc_free(d_nav)
in
  (if ieq(start_c, 0) andalso igt(end_c, 15) andalso ilt(w_left1, end_c) andalso ilt(w_left2, w_left1) andalso igt(w_right1, 0) andalso ilt(del_len, end_c) then 1 else 0)
end

fun selftest_history_part(): int = let
  val d5 = doc_open()
  val () = put_str(d5, "deneme")
  val () = put_str(d5, " bir")
  val () = doc_undo(d5)
  val undo_ok = (if ieq(doc_len(d5), 6) then 1 else 0) : int
  val () = doc_redo(d5)
  val redo_ok = (if ieq(doc_len(d5), 10) then 1 else 0) : int
  val () = doc_set_caret_move(d5, 0)
  val () = doc_set_caret_extend(d5, 6)
  val () = doc_wrap(d5, "**", 2, "**", 2)
  val wrap_ok = (if ieq(doc_byte(d5, 0), CHAR_STAR) andalso ieq(doc_byte(d5, 1), CHAR_STAR) then 1 else 0) : int
  val () = doc_free(d5)
  val nav_ok = selftest_nav_check()
  val () = println! ("undo=", undo_ok, " redo=", redo_ok, " wrap=", wrap_ok, " nav=", nav_ok)
in
  (if ieq(undo_ok, 1) andalso ieq(redo_ok, 1) andalso ieq(wrap_ok, 1) andalso ieq(nav_ok, 1) then 1 else 0)
end

fun selftest_big_part(): void = let
  val d_big = doc_open()
  val big_ok = doc_load(d_big, "build/CMakeFiles/CMakeConfigureLog.yaml")
  val big_lines = doc_nlines(d_big)
  val big_h = doc_layout(d_big, 18)
  val big_c_line = doc_line_of(d_big, isub(doc_len(d_big), 10))
  val () = doc_free(d_big)
  val big_digit = (if big_ok then 1 else 0) : int
  val () = println! ("big_load=", big_digit, " lines=", big_lines, " h=", big_h, " last_line=", big_c_line)
in
end

fun selftest_vfs_autosave_ok(svfs_ok: Toggle, p: string, vpath: string): int = let
  val in_vfs = fs_exists(vpath)
  val on_disk_yet = fs_exists(p)
in
  (if is_on(svfs_ok) andalso ieq(in_vfs, 1) andalso ieq(on_disk_yet, 0) then 1 else 0)
end

fun selftest_vfs_close_ok(d: !Doc, p: string, vpath: string): int = let
  val sphys_ok = doc_save_physical(d, p)
  val on_disk_now = fs_exists(p)
  val in_vfs_after = fs_exists(vpath)
in
  (if ieq(sphys_ok, 1) andalso ieq(on_disk_now, 1) andalso ieq(in_vfs_after, 0) then 1 else 0)
end

fun selftest_vfs_part(root: string): int = let
  val dvfs = doc_open()
  val () = put_str(dvfs, "vfs test content\n")
  val disk_path = selftest_fixture_path(root, "vfs.txt")
  val test_disk_p = buf_cstr(disk_path)
  val svfs_ok = doc_save_vfs(dvfs, test_disk_p)
  var vbuf = buf_make(512)
  val () = fs_vfs_buf(test_disk_p, vbuf, 511)
  val vpath = buf_cstr(vbuf)
  val vfs_ok1 = selftest_vfs_autosave_ok(toggle_of(ieq(svfs_ok, 1)), test_disk_p, vpath)
  val vfs_ok2 = selftest_vfs_close_ok(dvfs, test_disk_p, vpath)
  val () = seen_int(fs_unlink(test_disk_p))
  val () = buf_free(vbuf)
  val () = doc_free(dvfs)
  val () = buf_free(disk_path)
  val vfs_ok = (if ieq(vfs_ok1, 1) andalso ieq(vfs_ok2, 1) then 1 else 0) : int
  val () = println! ("vfs_autosave=", vfs_ok, " in_ram=", vfs_ok1, " close_disk=", vfs_ok2)
in
  vfs_ok
end

fun eqb(d: !Doc, i: int, b: int): int =
  (if ieq(doc_byte(d, i), b) then 1 else 0)

extern fun text_covers_fuel_exhausted(d: !Doc, i: int, n: int, p: int): int = "mac#anth_die_int"

fun text_covers_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int, n: int, p: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(i, n) then 0
    else if is_kind(doc_node_kind(d, i), KText) andalso ile(doc_node_start(d, i), p) andalso ilt(p, doc_node_end(d, i)) then 1
    else text_covers_with_fuel(recfuel - 1, d, iadd(i, 1), n, p)
  ) else text_covers_fuel_exhausted(d, i, n, p)

fun text_covers(d: !Doc, p: int): int =
  text_covers_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, doc_nnodes(d), p)

extern fun span_covered_fuel_exhausted(d: !Doc, p: int, n: int): int = "mac#anth_die_int"

fun span_covered_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: int, n: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(p, n) then 1
    else if ieq(text_covers(d, p), 0) then 0
    else span_covered_with_fuel(recfuel - 1, d, iadd(p, 1), n)
  ) else span_covered_fuel_exhausted(d, p, n)
