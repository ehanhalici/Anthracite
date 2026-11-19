(* Kasa penceresi tıklama işleme; geometri vault_dialog.hats içindedir. *)

fun vault_row_at_loop {n:nat} .<n>. (
  left: int(n), f: !Font, r: !Rend, s: &App_record, g: VaultGeo, vi: int, y: int, py: int
): int =
  if left = 0 then ~1
  else let
    val hgt = vault_row_height(g.lh, vault_row_lines(f, r, s, g.list_w, vi))
  in
    if ige(py, y) andalso ilt(py, iadd(y, hgt)) then vi
    else vault_row_at_loop(left - 1, f, r, s, g, iadd(vi, 1), iadd(iadd(y, hgt), VAULT_DIALOG_ROW_GAP), py)
  end

fun vault_row_at(f: !Font, r: !Rend, s: &App_record, g: VaultGeo, x: int, y: int): int =
  if ige(x, vault_row_x(g)) andalso ilt(x, iadd(vault_row_x(g), vault_row_w(g))) then
    vault_row_at_loop(airlock_nat(g.rows), f, r, s, g, 0, iadd(g.my, g.rows_y), y)
  else ~1

fun vault_close_dialog(s: &App_record >> _): void =
  if igt(buf_len(s.vault), 0) then s.vault_select := Off else ()

fun vault_click_buttons(s: &App_record >> _, g: VaultGeo, x: int, y: int): void = let
  val cs = VAULT_DIALOG_CLOSE_SIZE
  val on_open = vault_in_rect(x, y, vault_button_x(g), iadd(g.my, g.input_y), VAULT_DIALOG_BUTTON_WIDTH, vault_input_h(g))
  val on_close = vault_in_rect(x, y, vault_close_x(g), vault_close_y(g), cs, cs)
  val outside = not(vault_in_rect(x, y, g.mx, g.my, g.dw, g.dh))
in
  if on_open andalso igt(buf_len(s.promptb), 0) then vault_open_from_prompt(s)
  else if on_close orelse outside then vault_close_dialog(s)
  else ()
end

fun handle_vault_select_click(s: &App_record >> _, f: !Font, r: !Rend, x: int, y: int, w: int, h: int): void = let
  val () = font_set_px(f, s.fontpx)
  val g = vault_geo(f, r, s, w, h)
  val row = vault_row_at(f, r, s, g, x, y)
in
  if ige(row, 0) then select_vault_row(s, row) else vault_click_buttons(s, g, x, y)
end
