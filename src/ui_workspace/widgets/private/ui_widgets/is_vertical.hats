implement is_vertical(a) = case+ a of
  | Vertical() => true
  | Horizontal() => false

macdef SHADOW_ALPHA_OUTER = 15
macdef SHADOW_ALPHA_MID = 30
macdef SHADOW_ALPHA_INNER = 50


macdef SCROLLBAR_MIN_THUMB = 18

macdef PANE_HEADER_HEIGHT = 28

macdef LOADING_MODAL_WIDTH = 380
macdef LOADING_MODAL_HEIGHT = 140
macdef LOADING_TRACK_HEIGHT = 8
macdef LOADING_MARGIN = 20
macdef LOADING_TRACK_Y_OFFSET = 54
macdef LOADING_STATUS_Y_OFFSET = 76



implement ui_draw_border(r, x, y, w, h, th, col) =
  if ile(th, 0) orelse ile(w, 0) orelse ile(h, 0) then ()
  else let
    val () = rend_rect(r, x, y, w, th, col)
    val () = rend_rect(r, x, iadd(y, isub(h, th)), w, th, col)
    val side_h = isub(h, imul(th, 2))
    val () = if igt(side_h, 0) then rend_rect(r, x, iadd(y, th), th, side_h, col) else ()
    val () = if igt(side_h, 0) then rend_rect(r, iadd(x, isub(w, th)), iadd(y, th), th, side_h, col) else ()
  in
  end

implement ui_draw_shadow(r, x, y, w, h, rad) = let
  val () = rend_rect(r, isub(x, 2), iadd(y, 2), iadd(w, 4), iadd(h, 4), col_rgba(0, 0, 0, SHADOW_ALPHA_OUTER))
  val () = rend_rect(r, isub(x, 1), iadd(y, 2), iadd(w, 2), iadd(h, 2), col_rgba(0, 0, 0, SHADOW_ALPHA_MID))
  val () = rend_rect(r, x, iadd(y, 2), w, h, col_rgba(0, 0, 0, SHADOW_ALPHA_INNER))
in
end

extern fun arrow_right_fuel_exhausted(r: !Rend, x: int, y: int, sz: int, col: uint, i: int, steps: int): void = "mac#anth_die_void"

fun arrow_right_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), r: !Rend, x: int, y: int, sz: int, col: uint, i: int, steps: int): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, steps) then let
      val h = isub(sz, imul(i, 2))
      val () = if igt(h, 0) then rend_rect(r, iadd(x, i), iadd(y, i), 1, h, col) else ()
    in
      arrow_right_with_fuel(recfuel - 1, r, x, y, sz, col, iadd(i, 1), steps)
    end else ()
  ) else arrow_right_fuel_exhausted(r, x, y, sz, col, i, steps)

fun draw_arrow_right(r: !Rend, x: int, y: int, sz: int, col: uint): void =
  arrow_right_with_fuel(airlock_nat(MAX_REC_FUEL), r, x, y, sz, col, 0, idiv(sz, 2))

extern fun arrow_down_fuel_exhausted(r: !Rend, x: int, y: int, sz: int, col: uint, i: int, steps: int): void = "mac#anth_die_void"

fun arrow_down_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), r: !Rend, x: int, y: int, sz: int, col: uint, i: int, steps: int): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, steps) then let
      val w = isub(sz, imul(i, 2))
      val () = if igt(w, 0) then rend_rect(r, iadd(x, i), iadd(y, i), w, 1, col) else ()
    in
      arrow_down_with_fuel(recfuel - 1, r, x, y, sz, col, iadd(i, 1), steps)
    end else ()
  ) else arrow_down_fuel_exhausted(r, x, y, sz, col, i, steps)

fun draw_arrow_down(r: !Rend, x: int, y: int, sz: int, col: uint): void =
  arrow_down_with_fuel(airlock_nat(MAX_REC_FUEL), r, x, y, sz, col, 0, idiv(sz, 2))

extern fun arrow_left_fuel_exhausted(r: !Rend, x: int, y: int, sz: int, col: uint, i: int, steps: int): void = "mac#anth_die_void"

fun arrow_left_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), r: !Rend, x: int, y: int, sz: int, col: uint, i: int, steps: int): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, steps) then let
      val h = isub(sz, imul(i, 2))
      val () = if igt(h, 0) then rend_rect(r, isub(iadd(x, sz), i), iadd(y, i), 1, h, col) else ()
    in
      arrow_left_with_fuel(recfuel - 1, r, x, y, sz, col, iadd(i, 1), steps)
    end else ()
  ) else arrow_left_fuel_exhausted(r, x, y, sz, col, i, steps)

fun draw_arrow_left(r: !Rend, x: int, y: int, sz: int, col: uint): void =
  arrow_left_with_fuel(airlock_nat(MAX_REC_FUEL), r, x, y, sz, col, 0, idiv(sz, 2))

extern fun arrow_up_fuel_exhausted(r: !Rend, x: int, y: int, sz: int, col: uint, i: int, steps: int): void = "mac#anth_die_void"

fun arrow_up_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), r: !Rend, x: int, y: int, sz: int, col: uint, i: int, steps: int): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, steps) then let
      val w = isub(sz, imul(i, 2))
      val () = if igt(w, 0) then rend_rect(r, iadd(x, i), isub(iadd(y, sz), i), w, 1, col) else ()
    in
      arrow_up_with_fuel(recfuel - 1, r, x, y, sz, col, iadd(i, 1), steps)
    end else ()
  ) else arrow_up_fuel_exhausted(r, x, y, sz, col, i, steps)

fun draw_arrow_up(r: !Rend, x: int, y: int, sz: int, col: uint): void =
  arrow_up_with_fuel(airlock_nat(MAX_REC_FUEL), r, x, y, sz, col, 0, idiv(sz, 2))

fun draw_check(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val h2 = idiv(sz, 2)
  val () = rend_rect(r, iadd(x, 1), iadd(y, h2), 2, idiv(sz, 3), col)
  val () = rend_rect(r, iadd(x, 3), iadd(y, iadd(h2, 2)), 2, idiv(sz, 3), col)
  val () = rend_rect(r, iadd(x, 5), iadd(y, idiv(sz, 3)), 2, h2, col)
  val () = rend_rect(r, iadd(x, 7), iadd(y, idiv(sz, 5)), 2, h2, col)
in
end

extern fun close_icon_fuel_exhausted(r: !Rend, x: int, y: int, sz: int, col: uint, i: int): void = "mac#anth_die_void"

fun close_icon_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), r: !Rend, x: int, y: int, sz: int, col: uint, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, sz) then let
      val () = rend_rect(r, iadd(x, i), iadd(y, i), 1, 1, col)
      val () = rend_rect(r, iadd(x, isub(sz, i)), iadd(y, i), 1, 1, col)
    in
      close_icon_with_fuel(recfuel - 1, r, x, y, sz, col, iadd(i, 1))
    end else ()
  ) else close_icon_fuel_exhausted(r, x, y, sz, col, i)

fun draw_close_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void =
  close_icon_with_fuel(airlock_nat(MAX_REC_FUEL), r, x, y, sz, col, 0)

fun draw_folder_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val tab_w = idiv(sz, 2)
  val () = rend_rect(r, x, y, tab_w, 2, col)
  val () = rend_rect(r, x, iadd(y, 2), sz, isub(sz, 2), col)
  val () = rend_rect(r, iadd(x, 2), iadd(y, 4), isub(sz, 4), isub(sz, 6), col_bg())
in
end

fun draw_file_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val () = rend_rect(r, iadd(x, 1), y, isub(sz, 2), sz, col)
  val () = rend_rect(r, iadd(x, 3), iadd(y, 3), isub(sz, 6), 1, col_bg())
  val () = rend_rect(r, iadd(x, 3), iadd(y, 6), isub(sz, 6), 1, col_bg())
  val () = rend_rect(r, iadd(x, 3), iadd(y, 9), isub(sz, 6), 1, col_bg())
in
end

fun draw_search_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val ring = isub(sz, 3)
  val () = ui_draw_border(r, x, y, ring, ring, 1, col)
  val () = rend_rect(r, iadd(x, isub(ring, 1)), iadd(y, isub(ring, 1)), 4, 2, col)
in
end

fun draw_settings_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val () = rend_rect(r, x, iadd(y, 2), sz, 1, col)
  val () = rend_rect(r, iadd(x, 3), iadd(y, 1), 2, 3, col)
  val () = rend_rect(r, x, iadd(y, 6), sz, 1, col)
  val () = rend_rect(r, iadd(x, isub(sz, 4)), iadd(y, 5), 2, 3, col)
  val () = rend_rect(r, x, iadd(y, 10), sz, 1, col)
  val () = rend_rect(r, iadd(x, 2), iadd(y, 9), 2, 3, col)
in
end

fun draw_plus_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val mid = idiv(sz, 2)
  val () = rend_rect(r, iadd(x, mid), y, 1, sz, col)
  val () = rend_rect(r, x, iadd(y, mid), sz, 1, col)
in
end

fun draw_split_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val () = ui_draw_border(r, x, y, sz, sz, 1, col)
  val () = rend_rect(r, iadd(x, idiv(sz, 2)), y, 1, sz, col)
in
end

implement ui_draw_icon(f, r, icon, x, y, sz, col) =
  if ieq(icon, UI_ICON_RIGHT_ARROW) then draw_arrow_right(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_DOWN_ARROW) then draw_arrow_down(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_LEFT_ARROW) then draw_arrow_left(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_UP_ARROW) then draw_arrow_up(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_CHECK) then draw_check(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_CHECK_EMPTY) then ui_draw_border(r, x, y, sz, sz, 1, col)
  else if ieq(icon, UI_ICON_CLOSE) then draw_close_icon(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_FOLDER) then draw_folder_icon(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_FILE) then draw_file_icon(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_SEARCH) then draw_search_icon(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_SETTINGS) then draw_settings_icon(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_PLUS) then draw_plus_icon(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_SPLIT) then draw_split_icon(r, x, y, sz, col)
  else ()

implement ui_divider(r, x, y, len, is_vert) =
  if is_vertical(is_vert) then rend_rect(r, x, y, 1, len, col_line())
  else rend_rect(r, x, y, len, 1, col_line())

implement ui_badge(f, r, x, y, s, bg_col, text_col) = let
  val n = c_strlen(s)
  val tw = font_width(f, r, c_str_ptr(s), n)
  val bw = iadd(tw, 12)
  val bh = isub(font_line_h(f), 2)
  val () = rend_rect(r, x, y, bw, bh, bg_col)
  val () = ui_draw_border(r, x, y, bw, bh, 1, col_line())
  val () = draw_s(f, r, iadd(x, 6), iadd(y, 1), s, text_col)
in
end
