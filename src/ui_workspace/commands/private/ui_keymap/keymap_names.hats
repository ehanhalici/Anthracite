fun km_lower_byte(c: int): int =
  if ige(c, CHAR_UPPER_A) andalso ile(c, CHAR_UPPER_Z) then iadd(c, 32) else c

fun km_slice_eq_m {rem:nat} .<rem>. (
  b: !Buf, st: int, s: string, i: int, rem: int(rem)
): bool =
  if rem = 0 then true
  else let
    val bc = km_lower_byte(buf_get(b, iadd(st, i)))
    val sc = km_lower_byte(c_str_byte(s, i))
  in
    if ieq(bc, sc) then km_slice_eq_m(b, st, s, iadd(i, 1), rem - 1)
    else false
  end

fun km_slice_eq(b: !Buf, st: int, en: int, s: string): bool = let
  val n = isub(en, st)
  val slen = c_strlen(s)
in
  if ieq(n, slen) andalso ige(n, 0) then km_slice_eq_m(b, st, s, 0, airlock_nat(n))
  else false
end

implement keymap_cmd_name(cmd) = case+ cmd of
  | CMD_NONE() => "" | CMD_CARET_LEFT() => "caret_left" | CMD_CARET_RIGHT() => "caret_right" | CMD_CARET_UP() => "caret_up"
  | CMD_CARET_DOWN() => "caret_down" | CMD_CARET_LINE_START() => "caret_line_start" | CMD_CARET_LINE_END() => "caret_line_end" | CMD_BACKSPACE() => "backspace"
  | CMD_DELETE() => "delete" | CMD_SELECT_ALL() => "select_all" | CMD_DELETE_SELECTION() => "delete_selection" | CMD_COLLAPSE_SELECTION() => "collapse_selection"
  | CMD_COPY() => "copy" | CMD_PASTE() => "paste" | CMD_CUT() => "cut" | CMD_SAVE() => "save"
  | CMD_UNDO() => "undo" | CMD_REDO() => "redo" | CMD_WRAP_BOLD() => "wrap_bold" | CMD_WRAP_ITALIC() => "wrap_italic"
  | CMD_WRAP_WIKILINK() => "wrap_wikilink" | CMD_SELECT_LEFT() => "select_left" | CMD_SELECT_RIGHT() => "select_right" | CMD_SELECT_UP() => "select_up"
  | CMD_SELECT_DOWN() => "select_down" | CMD_SELECT_LINE_START() => "select_line_start" | CMD_SELECT_LINE_END() => "select_line_end" | CMD_INDENT() => "indent"
  | CMD_NEWLINE() => "newline" | CMD_TEXT_INPUT() => "" | CMD_OPEN_SEARCH() => "open_search" | CMD_CLOSE_TAB() => "close_tab"
  | CMD_NEW_TAB() => "new_tab" | CMD_NEW_FILE() => "new_file" | CMD_NEW_FOLDER() => "new_folder" | CMD_TOGGLE_VIEW() => "toggle_view"
  | CMD_ESCAPE() => "escape" | CMD_WORD_LEFT() => "word_left" | CMD_WORD_RIGHT() => "word_right" | CMD_SELECT_WORD_LEFT() => "select_word_left"
  | CMD_SELECT_WORD_RIGHT() => "select_word_right" | CMD_DELETE_WORD_LEFT() => "delete_word_left" | CMD_DELETE_WORD_RIGHT() => "delete_word_right" | CMD_DOC_START() => "doc_start"
  | CMD_DOC_END() => "doc_end" | CMD_SELECT_DOC_START() => "select_doc_start" | CMD_SELECT_DOC_END() => "select_doc_end" | CMD_PAGE_UP() => "page_up"
  | CMD_PAGE_DOWN() => "page_down" | CMD_SELECT_PAGE_UP() => "select_page_up" | CMD_SELECT_PAGE_DOWN() => "select_page_down" | CMD_NEXT_TAB() => "next_tab"
  | CMD_PREV_TAB() => "prev_tab" | CMD_NAV_BACK() => "nav_back" | CMD_NAV_FORWARD() => "nav_forward" | CMD_OPEN_DOC_SEARCH() => "open_doc_search"
  | CMD_KILL_LINE() => "kill_line" | CMD_RELOAD_KEYBINDINGS() => "reload_keybindings"
  | CMD_DOC_FONT_INCREASE() => "doc_font_increase" | CMD_DOC_FONT_DECREASE() => "doc_font_decrease"
  | CMD_SPLIT_TOGGLE() => "split_toggle"

fun km_cmd_match_a(b: !Buf, st: int, en: int): Cmd =
  if km_slice_eq(b, st, en, "caret_left") then CMD_CARET_LEFT
  else if km_slice_eq(b, st, en, "caret_right") then CMD_CARET_RIGHT
  else if km_slice_eq(b, st, en, "caret_up") then CMD_CARET_UP
  else if km_slice_eq(b, st, en, "caret_down") then CMD_CARET_DOWN
  else if km_slice_eq(b, st, en, "caret_line_start") then CMD_CARET_LINE_START
  else if km_slice_eq(b, st, en, "caret_line_end") then CMD_CARET_LINE_END
  else if km_slice_eq(b, st, en, "backspace") then CMD_BACKSPACE
  else if km_slice_eq(b, st, en, "delete") then CMD_DELETE
  else if km_slice_eq(b, st, en, "select_all") then CMD_SELECT_ALL
  else if km_slice_eq(b, st, en, "delete_selection") then CMD_DELETE_SELECTION
  else if km_slice_eq(b, st, en, "collapse_selection") then CMD_COLLAPSE_SELECTION
  else if km_slice_eq(b, st, en, "copy") then CMD_COPY
  else if km_slice_eq(b, st, en, "paste") then CMD_PASTE
  else if km_slice_eq(b, st, en, "cut") then CMD_CUT
  else if km_slice_eq(b, st, en, "save") then CMD_SAVE
  else if km_slice_eq(b, st, en, "undo") then CMD_UNDO
  else if km_slice_eq(b, st, en, "redo") then CMD_REDO
  else CMD_NONE

fun km_cmd_match_b(b: !Buf, st: int, en: int): Cmd =
  if km_slice_eq(b, st, en, "wrap_bold") then CMD_WRAP_BOLD
  else if km_slice_eq(b, st, en, "wrap_italic") then CMD_WRAP_ITALIC
  else if km_slice_eq(b, st, en, "wrap_wikilink") then CMD_WRAP_WIKILINK
  else if km_slice_eq(b, st, en, "select_left") then CMD_SELECT_LEFT
  else if km_slice_eq(b, st, en, "select_right") then CMD_SELECT_RIGHT
  else if km_slice_eq(b, st, en, "select_up") then CMD_SELECT_UP
  else if km_slice_eq(b, st, en, "select_down") then CMD_SELECT_DOWN
  else if km_slice_eq(b, st, en, "select_line_start") then CMD_SELECT_LINE_START
  else if km_slice_eq(b, st, en, "select_line_end") then CMD_SELECT_LINE_END
  else if km_slice_eq(b, st, en, "indent") then CMD_INDENT
  else if km_slice_eq(b, st, en, "newline") then CMD_NEWLINE
  else if km_slice_eq(b, st, en, "open_search") then CMD_OPEN_SEARCH
  else if km_slice_eq(b, st, en, "open_doc_search") then CMD_OPEN_DOC_SEARCH
  else if km_slice_eq(b, st, en, "close_tab") then CMD_CLOSE_TAB
  else if km_slice_eq(b, st, en, "new_tab") then CMD_NEW_TAB
  else if km_slice_eq(b, st, en, "new_file") then CMD_NEW_FILE
  else if km_slice_eq(b, st, en, "new_folder") then CMD_NEW_FOLDER
  else CMD_NONE

fun km_cmd_match_c(b: !Buf, st: int, en: int): Cmd =
  if km_slice_eq(b, st, en, "toggle_view") then CMD_TOGGLE_VIEW
  else if km_slice_eq(b, st, en, "escape") then CMD_ESCAPE
  else if km_slice_eq(b, st, en, "word_left") then CMD_WORD_LEFT
  else if km_slice_eq(b, st, en, "word_right") then CMD_WORD_RIGHT
  else if km_slice_eq(b, st, en, "select_word_left") then CMD_SELECT_WORD_LEFT
  else if km_slice_eq(b, st, en, "select_word_right") then CMD_SELECT_WORD_RIGHT
  else if km_slice_eq(b, st, en, "delete_word_left") then CMD_DELETE_WORD_LEFT
  else if km_slice_eq(b, st, en, "delete_word_right") then CMD_DELETE_WORD_RIGHT
  else if km_slice_eq(b, st, en, "doc_start") then CMD_DOC_START
  else if km_slice_eq(b, st, en, "doc_end") then CMD_DOC_END
  else if km_slice_eq(b, st, en, "select_doc_start") then CMD_SELECT_DOC_START
  else if km_slice_eq(b, st, en, "select_doc_end") then CMD_SELECT_DOC_END
  else if km_slice_eq(b, st, en, "page_up") then CMD_PAGE_UP
  else if km_slice_eq(b, st, en, "page_down") then CMD_PAGE_DOWN
  else if km_slice_eq(b, st, en, "select_page_up") then CMD_SELECT_PAGE_UP
  else if km_slice_eq(b, st, en, "select_page_down") then CMD_SELECT_PAGE_DOWN
  else CMD_NONE

fun km_cmd_match_d(b: !Buf, st: int, en: int): Cmd =
  if km_slice_eq(b, st, en, "next_tab") then CMD_NEXT_TAB
  else if km_slice_eq(b, st, en, "prev_tab") then CMD_PREV_TAB
  else if km_slice_eq(b, st, en, "nav_back") then CMD_NAV_BACK
  else if km_slice_eq(b, st, en, "nav_forward") then CMD_NAV_FORWARD
  else if km_slice_eq(b, st, en, "kill_line") then CMD_KILL_LINE
  else if km_slice_eq(b, st, en, "reload_keybindings") then CMD_RELOAD_KEYBINDINGS
  else if km_slice_eq(b, st, en, "doc_font_increase") then CMD_DOC_FONT_INCREASE
  else if km_slice_eq(b, st, en, "doc_font_decrease") then CMD_DOC_FONT_DECREASE
  else if km_slice_eq(b, st, en, "split_toggle") then CMD_SPLIT_TOGGLE
  else CMD_NONE

implement keymap_cmd_by_name(b, st, en) = let
  val ca = km_cmd_match_a(b, st, en)
in
  if not(is_cmd(ca, CMD_NONE)) then ca
  else let val cb = km_cmd_match_b(b, st, en) in
    if not(is_cmd(cb, CMD_NONE)) then cb
    else let val cc = km_cmd_match_c(b, st, en) in
      if not(is_cmd(cc, CMD_NONE)) then cc
      else km_cmd_match_d(b, st, en)
    end
  end
end
