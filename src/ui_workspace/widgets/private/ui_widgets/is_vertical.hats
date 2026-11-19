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
  val soft = imax(8, imul(rad, 2))
  val tr = col_rgba(0, 0, 0, 0)
  val () = rend_rrect_ex(r, x, iadd(y, 4), w, h, rad, rad, rad, rad,
    col_rgba(0, 0, 0, 88), col_rgba(0, 0, 0, 88), 0, tr, soft)
  val () = rend_rrect_ex(r, x, iadd(y, 1), w, h, rad, rad, rad, rad,
    col_rgba(0, 0, 0, 40), col_rgba(0, 0, 0, 40), 0, tr, imax(4, rad))
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

fun chevron_right_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), r: !Rend, x: int, y: int, sz: int, col: uint, i: int, steps: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, steps) then let
      val t = if ige(sz, 12) then 2 else 1
      val cx = iadd(x, iadd(idiv(sz, 4), i))
      val () = rend_rect(r, cx, iadd(y, i), t, t, col)
      val () = rend_rect(r, cx, isub(iadd(y, sz), iadd(i, t)), t, t, col)
    in
      chevron_right_with_fuel(recfuel - 1, r, x, y, sz, col, iadd(i, 1), steps)
    end else ()
  ) else ()

fun chevron_down_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), r: !Rend, x: int, y: int, sz: int, col: uint, i: int, steps: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, steps) then let
      val t = if ige(sz, 12) then 2 else 1
      val cy = iadd(y, iadd(idiv(sz, 4), i))
      val () = rend_rect(r, iadd(x, i), cy, t, t, col)
      val () = rend_rect(r, isub(iadd(x, sz), iadd(i, t)), cy, t, t, col)
    in
      chevron_down_with_fuel(recfuel - 1, r, x, y, sz, col, iadd(i, 1), steps)
    end else ()
  ) else ()

fun draw_arrow_right(r: !Rend, x: int, y: int, sz: int, col: uint): void =
  if ige(sz, 8) then
    chevron_right_with_fuel(airlock_nat(MAX_REC_FUEL), r, x, y, sz, col, 0, idiv(sz, 2))
  else
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
  if ige(sz, 8) then
    chevron_down_with_fuel(airlock_nat(MAX_REC_FUEL), r, x, y, sz, col, 0, idiv(sz, 2))
  else
    arrow_down_with_fuel(airlock_nat(MAX_REC_FUEL), r, x, y, sz, col, 0, idiv(sz, 2))

extern fun arrow_left_fuel_exhausted(r: !Rend, x: int, y: int, sz: int, col: uint, i: int, steps: int): void = "mac#anth_die_void"

fun arrow_left_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), r: !Rend, x: int, y: int, sz: int, col: uint, i: int, steps: int): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, steps) then let
      val h = isub(sz, imul(i, 2))
      val () = if igt(h, 0) then rend_rect(r, isub(iadd(x, steps), iadd(i, 1)), iadd(y, i), 1, h, col) else ()
    in
      arrow_left_with_fuel(recfuel - 1, r, x, y, sz, col, iadd(i, 1), steps)
    end else ()
  ) else arrow_left_fuel_exhausted(r, x, y, sz, col, i, steps)

fun chevron_left_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), r: !Rend, x: int, y: int, sz: int, col: uint, i: int, steps: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, steps) then let
      val px = isub(iadd(x, steps), iadd(i, 1))
      val () = rend_rect(r, px, iadd(y, i), 2, 2, col)
      val () = rend_rect(r, px, isub(iadd(y, sz), iadd(i, 2)), 2, 2, col)
    in
      chevron_left_with_fuel(recfuel - 1, r, x, y, sz, col, iadd(i, 1), steps)
    end else ()
  ) else ()

fun draw_arrow_left(r: !Rend, x: int, y: int, sz: int, col: uint): void =
  if ige(sz, 12) then
    chevron_left_with_fuel(airlock_nat(MAX_REC_FUEL), r, x, y, sz, col, 0, idiv(sz, 2))
  else
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
      val ry = isub(isub(sz, 1), i)
      val () = rend_rect(r, iadd(x, i), iadd(y, i), 1, 1, col)
      val () = rend_rect(r, iadd(x, ry), iadd(y, i), 1, 1, col)
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

fun diag_stroke_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), r: !Rend, x: int, y: int, i: int, n: int, col: uint
): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, n) then let
      val () = rend_rect(r, iadd(x, i), iadd(y, i), 2, 2, col)
    in
      diag_stroke_with_fuel(recfuel - 1, r, x, y, iadd(i, 1), n, col)
    end else ()
  ) else ()

fun draw_search_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val ring = imax(6, isub(sz, 3))
  val rad = idiv(ring, 2)
  val tr = col_rgba(0, 0, 0, 0)
  val () = rend_rrect_ex(r, x, y, ring, ring, rad, rad, rad, rad, tr, tr, 1, col, 1)
  val hx = iadd(x, isub(ring, 2))
  val hy = iadd(y, isub(ring, 2))
in
  diag_stroke_with_fuel(airlock_nat(MAX_REC_FUEL), r, hx, hy, 0, 4, col)
end

fun draw_settings_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val () = rend_rect(r, x, iadd(y, 2), sz, 1, col)
  val () = rend_rect(r, iadd(x, 3), iadd(y, 1), 2, 3, col)
  val () = rend_rect(r, x, iadd(y, idiv(sz, 2)), sz, 1, col)
  val () = rend_rect(r, iadd(x, isub(sz, 5)), isub(iadd(y, idiv(sz, 2)), 1), 2, 3, col)
  val () = rend_rect(r, x, isub(iadd(y, sz), 3), sz, 1, col)
  val () = rend_rect(r, iadd(x, 2), isub(iadd(y, sz), 4), 2, 3, col)
in
end

fun draw_plus_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val mid = idiv(sz, 2)
  val () = rend_rect(r, iadd(x, mid), y, 1, sz, col)
  val () = rend_rect(r, x, iadd(y, mid), sz, 1, col)
in
end

fun draw_split_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val tr = col_rgba(0, 0, 0, 0)
  val () = rend_rrect_ex(r, x, y, sz, sz, 2, 2, 2, 2, tr, tr, 1, col, 1)
  val () = rend_rect(r, iadd(x, idiv(sz, 2)), iadd(y, 1), 1, isub(sz, 2), col)
in
end

fun draw_sidebar_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val tr = col_rgba(0, 0, 0, 0)
  val h = imax(6, isub(sz, 2))
  val div_x = iadd(x, imax(4, idiv(sz, 3)))
  val () = rend_rrect_ex(r, x, iadd(y, 1), sz, h, 3, 3, 3, 3, tr, tr, 1, col, 1)
  val () = rend_rect(r, div_x, iadd(y, 2), 1, isub(h, 2), col)
  val () = rend_rect(r, iadd(x, 2), iadd(y, 5), imax(1, isub(div_x, iadd(x, 3))), 1, col)
in
  rend_rect(r, iadd(x, 2), iadd(y, 8), imax(1, isub(div_x, iadd(x, 3))), 1, col)
end

fun pencil_stroke_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), r: !Rend, x: int, y: int, i: int, n: int, col: uint
): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, n) then let
      val () = rend_rect(r, iadd(x, i), isub(y, i), 2, 2, col)
    in
      pencil_stroke_with_fuel(recfuel - 1, r, x, y, iadd(i, 1), n, col)
    end else ()
  ) else ()

fun draw_edit_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val tr = col_rgba(0, 0, 0, 0)
  val steps = imax(4, isub(sz, 5))
  val () = rend_rrect_ex(r, x, y, sz, sz, 3, 3, 3, 3, tr, tr, 1, col, 1)
  val () = pencil_stroke_with_fuel(airlock_nat(MAX_REC_FUEL), r, iadd(x, 3), isub(iadd(y, sz), 5), 0, steps, col)
in
  rend_rect(r, iadd(x, 2), isub(iadd(y, sz), 3), 2, 1, col)
end

fun draw_eye_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val tr = col_rgba(0, 0, 0, 0)
  val eh = imax(6, idiv(sz, 2))
  val ey = iadd(y, idiv(isub(sz, eh), 2))
  val rad = idiv(eh, 2)
  val () = rend_rrect_ex(r, x, ey, sz, eh, rad, rad, rad, rad, tr, tr, 1, col, 1)
  val pr = imax(2, idiv(eh, 4))
  val psz = imul(pr, 2)
in
  rend_rrect(r, iadd(x, idiv(isub(sz, psz), 2)), iadd(y, idiv(isub(sz, psz), 2)), psz, psz, pr, col)
end

fun draw_chevron_thin_r(r: !Rend, x: int, y: int, sz: int, col: uint): void =
  chevron_right_with_fuel(airlock_nat(MAX_REC_FUEL), r, x, y, sz, col, 0, idiv(sz, 2))

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
  else if ieq(icon, UI_ICON_SIDEBAR) then draw_sidebar_icon(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_EDIT) then draw_edit_icon(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_EYE) then draw_eye_icon(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_CHEVRON_RIGHT) then draw_chevron_thin_r(r, x, y, sz, col)
  else ()

implement ui_divider(r, x, y, len, is_vert) =
  if is_vertical(is_vert) then rend_rect(r, x, y, 1, len, col_line())
  else rend_rect(r, x, y, len, 1, col_line())

implement ui_badge(f, r, x, y, s, bg_col, text_col) = let
  val n = c_strlen(s)
  val tw = font_width(f, r, c_str_ptr(s), n)
  val bw = iadd(tw, 14)
  val bh = iadd(font_line_h(f), 2)
  val rad = idiv(bh, 2)
  val () = rend_rrect_ex(r, x, y, bw, bh, rad, rad, rad, rad, bg_col, bg_col, 1, col_line(), 1)
  val () = draw_s(f, r, iadd(x, 7), iadd(y, 1), s, text_col)
in
end
