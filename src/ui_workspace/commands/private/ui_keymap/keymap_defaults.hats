fun km_defaults_edit(km: &Buf >> _): void = let
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_Z, 0, 0, CMD_UNDO)
  val () = keymap_bind(km, iadd(KEYMOD_CTRL, KEYMOD_SHIFT), CHAR_LOWER_Z, 0, 0, CMD_REDO)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_Y, 0, 0, CMD_REDO)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_S, 0, 0, CMD_SAVE)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_A, 0, 0, CMD_SELECT_ALL)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_C, 0, 0, CMD_COPY)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_X, 0, 0, CMD_CUT)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_V, 0, 0, CMD_PASTE)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_B, 0, 0, CMD_WRAP_BOLD)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_I, 0, 0, CMD_WRAP_ITALIC)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_K, 0, 0, CMD_WRAP_WIKILINK)
in
end

fun km_defaults_app(km: &Buf >> _): void = let
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_F, 0, 0, CMD_OPEN_DOC_SEARCH)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_P, 0, 0, CMD_OPEN_SEARCH)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_O, 0, 0, CMD_OPEN_SEARCH)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_W, 0, 0, CMD_CLOSE_TAB)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_T, 0, 0, CMD_NEW_TAB)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_N, 0, 0, CMD_NEW_FILE)
  val () = keymap_bind(km, iadd(KEYMOD_CTRL, KEYMOD_SHIFT), CHAR_LOWER_N, 0, 0, CMD_NEW_FOLDER)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_LOWER_E, 0, 0, CMD_TOGGLE_VIEW)
  val () = keymap_bind(km, KEYMOD_CTRL, KEYCODE_TAB, 0, 0, CMD_NEXT_TAB)
  val () = keymap_bind(km, iadd(KEYMOD_CTRL, KEYMOD_SHIFT), KEYCODE_TAB, 0, 0, CMD_PREV_TAB)
  val () = keymap_bind(km, KEYMOD_ALT, KEYCODE_LEFT, 0, 0, CMD_NAV_BACK)
  val () = keymap_bind(km, KEYMOD_ALT, KEYCODE_RIGHT, 0, 0, CMD_NAV_FORWARD)
  val () = keymap_bind(km, KEYMOD_CTRL, KEYCODE_WHEEL_UP, 0, 0, CMD_DOC_FONT_INCREASE)
  val () = keymap_bind(km, KEYMOD_CTRL, KEYCODE_WHEEL_DOWN, 0, 0, CMD_DOC_FONT_DECREASE)
  val () = keymap_bind(km, KEYMOD_CTRL, CHAR_BACKSLASH, 0, 0, CMD_SPLIT_TOGGLE)
in
end

fun km_defaults_nav_plain(km: &Buf >> _): void = let
  val () = keymap_bind(km, 0, KEYCODE_ESCAPE, 0, 0, CMD_ESCAPE)
  val () = keymap_bind(km, 0, KEYCODE_LEFT, 0, 0, CMD_CARET_LEFT)
  val () = keymap_bind(km, 0, KEYCODE_RIGHT, 0, 0, CMD_CARET_RIGHT)
  val () = keymap_bind(km, 0, KEYCODE_UP, 0, 0, CMD_CARET_UP)
  val () = keymap_bind(km, 0, KEYCODE_DOWN, 0, 0, CMD_CARET_DOWN)
  val () = keymap_bind(km, 0, KEYCODE_HOME, 0, 0, CMD_CARET_LINE_START)
  val () = keymap_bind(km, 0, KEYCODE_END, 0, 0, CMD_CARET_LINE_END)
  val () = keymap_bind(km, 0, KEYCODE_PAGE_UP, 0, 0, CMD_PAGE_UP)
  val () = keymap_bind(km, 0, KEYCODE_PAGE_DOWN, 0, 0, CMD_PAGE_DOWN)
  val () = keymap_bind(km, 0, KEYCODE_BACKSPACE, 0, 0, CMD_BACKSPACE)
  val () = keymap_bind(km, 0, KEYCODE_DELETE, 0, 0, CMD_DELETE)
  val () = keymap_bind(km, 0, KEYCODE_RETURN, 0, 0, CMD_NEWLINE)
  val () = keymap_bind(km, 0, KEYCODE_TAB, 0, 0, CMD_INDENT)
in
end

fun km_defaults_nav_mod(km: &Buf >> _): void = let
  val () = keymap_bind(km, KEYMOD_SHIFT, KEYCODE_LEFT, 0, 0, CMD_SELECT_LEFT)
  val () = keymap_bind(km, KEYMOD_SHIFT, KEYCODE_RIGHT, 0, 0, CMD_SELECT_RIGHT)
  val () = keymap_bind(km, KEYMOD_SHIFT, KEYCODE_UP, 0, 0, CMD_SELECT_UP)
  val () = keymap_bind(km, KEYMOD_SHIFT, KEYCODE_DOWN, 0, 0, CMD_SELECT_DOWN)
  val () = keymap_bind(km, KEYMOD_SHIFT, KEYCODE_HOME, 0, 0, CMD_SELECT_LINE_START)
  val () = keymap_bind(km, KEYMOD_SHIFT, KEYCODE_END, 0, 0, CMD_SELECT_LINE_END)
  val () = keymap_bind(km, KEYMOD_SHIFT, KEYCODE_PAGE_UP, 0, 0, CMD_SELECT_PAGE_UP)
  val () = keymap_bind(km, KEYMOD_SHIFT, KEYCODE_PAGE_DOWN, 0, 0, CMD_SELECT_PAGE_DOWN)
  val () = keymap_bind(km, KEYMOD_CTRL, KEYCODE_LEFT, 0, 0, CMD_WORD_LEFT)
  val () = keymap_bind(km, KEYMOD_CTRL, KEYCODE_RIGHT, 0, 0, CMD_WORD_RIGHT)
  val () = keymap_bind(km, iadd(KEYMOD_CTRL, KEYMOD_SHIFT), KEYCODE_LEFT, 0, 0, CMD_SELECT_WORD_LEFT)
  val () = keymap_bind(km, iadd(KEYMOD_CTRL, KEYMOD_SHIFT), KEYCODE_RIGHT, 0, 0, CMD_SELECT_WORD_RIGHT)
  val () = keymap_bind(km, KEYMOD_CTRL, KEYCODE_BACKSPACE, 0, 0, CMD_DELETE_WORD_LEFT)
  val () = keymap_bind(km, KEYMOD_CTRL, KEYCODE_DELETE, 0, 0, CMD_DELETE_WORD_RIGHT)
  val () = keymap_bind(km, KEYMOD_CTRL, KEYCODE_HOME, 0, 0, CMD_DOC_START)
  val () = keymap_bind(km, KEYMOD_CTRL, KEYCODE_END, 0, 0, CMD_DOC_END)
  val () = keymap_bind(km, iadd(KEYMOD_CTRL, KEYMOD_SHIFT), KEYCODE_HOME, 0, 0, CMD_SELECT_DOC_START)
  val () = keymap_bind(km, iadd(KEYMOD_CTRL, KEYMOD_SHIFT), KEYCODE_END, 0, 0, CMD_SELECT_DOC_END)
in
end

implement keymap_load_defaults(km) = let
  val () = keymap_clear(km)
  val () = km_defaults_edit(km)
  val () = km_defaults_app(km)
  val () = km_defaults_nav_plain(km)
in
  km_defaults_nav_mod(km)
end

fun km_append_json_item(dst: &Buf >> _, key_s: string, cmd_s: string, comma: Toggle): void = let
  val () = if is_on(comma) then buffer_append_string(dst, ",\n") else ()
  val () = buffer_append_string(dst, "  {\"key\": \"")
  val () = buffer_append_string(dst, key_s)
  val () = buffer_append_string(dst, "\", \"command\": \"")
  val () = buffer_append_string(dst, cmd_s)
in
  buffer_append_string(dst, "\"}")
end

implement keymap_default_json(dst) = let
  val () = buffer_clear(dst)
  val () = buffer_append_string(dst, "[\n")
  val () = km_append_json_item(dst, "Ctrl+Z", "undo", Off)
  val () = km_append_json_item(dst, "Ctrl+Shift+Z", "redo", On)
  val () = km_append_json_item(dst, "Ctrl+S", "save", On)
  val () = km_append_json_item(dst, "Ctrl+F", "open_doc_search", On)
  val () = km_append_json_item(dst, "Ctrl+P", "open_search", On)
  val () = km_append_json_item(dst, "Ctrl+T", "new_tab", On)
  val () = km_append_json_item(dst, "Ctrl+W", "close_tab", On)
  val () = km_append_json_item(dst, "Ctrl+E", "toggle_view", On)
  val () = km_append_json_item(dst, "Alt+Left", "nav_back", On)
  val () = km_append_json_item(dst, "Alt+Right", "nav_forward", On)
  val () = km_append_json_item(dst, "Ctrl+WheelUp", "doc_font_increase", On)
  val () = km_append_json_item(dst, "Ctrl+WheelDown", "doc_font_decrease", On)
in
  buffer_append_string(dst, "\n]\n")
end
