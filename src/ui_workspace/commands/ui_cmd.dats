#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "ui_workspace/commands/ui_cmd.sats"

implement cmd_code(k) = case+ k of
  | CMD_NONE() => 0 | CMD_CARET_LEFT() => 1 | CMD_CARET_RIGHT() => 2 | CMD_CARET_UP() => 3
  | CMD_CARET_DOWN() => 4 | CMD_CARET_LINE_START() => 5 | CMD_CARET_LINE_END() => 6 | CMD_BACKSPACE() => 7
  | CMD_DELETE() => 8 | CMD_SELECT_ALL() => 9 | CMD_DELETE_SELECTION() => 10 | CMD_COLLAPSE_SELECTION() => 11
  | CMD_COPY() => 12 | CMD_PASTE() => 13 | CMD_CUT() => 14 | CMD_SAVE() => 15
  | CMD_UNDO() => 16 | CMD_REDO() => 17 | CMD_WRAP_BOLD() => 18 | CMD_WRAP_ITALIC() => 19
  | CMD_WRAP_WIKILINK() => 20 | CMD_SELECT_LEFT() => 21 | CMD_SELECT_RIGHT() => 22 | CMD_SELECT_UP() => 23
  | CMD_SELECT_DOWN() => 24 | CMD_SELECT_LINE_START() => 25 | CMD_SELECT_LINE_END() => 26 | CMD_INDENT() => 28
  | CMD_NEWLINE() => 30 | CMD_TEXT_INPUT() => 31 | CMD_OPEN_SEARCH() => 35 | CMD_CLOSE_TAB() => 36
  | CMD_NEW_TAB() => 37 | CMD_NEW_FILE() => 38 | CMD_NEW_FOLDER() => 39 | CMD_TOGGLE_VIEW() => 40
  | CMD_ESCAPE() => 41 | CMD_WORD_LEFT() => 43 | CMD_WORD_RIGHT() => 44 | CMD_SELECT_WORD_LEFT() => 45
  | CMD_SELECT_WORD_RIGHT() => 46 | CMD_DELETE_WORD_LEFT() => 47 | CMD_DELETE_WORD_RIGHT() => 48 | CMD_DOC_START() => 49
  | CMD_DOC_END() => 50 | CMD_SELECT_DOC_START() => 51 | CMD_SELECT_DOC_END() => 52 | CMD_PAGE_UP() => 53
  | CMD_PAGE_DOWN() => 54 | CMD_SELECT_PAGE_UP() => 55 | CMD_SELECT_PAGE_DOWN() => 56 | CMD_NEXT_TAB() => 57
  | CMD_PREV_TAB() => 58 | CMD_NAV_BACK() => 59 | CMD_NAV_FORWARD() => 60 | CMD_OPEN_DOC_SEARCH() => 61
  | CMD_KILL_LINE() => 62 | CMD_RELOAD_KEYBINDINGS() => 63
  | CMD_DOC_FONT_INCREASE() => 64 | CMD_DOC_FONT_DECREASE() => 65
  | CMD_SPLIT_TOGGLE() => 66

fun cmd_of_code_a(n: int): Cmd =
  if ieq(n, 1) then CMD_CARET_LEFT else if ieq(n, 2) then CMD_CARET_RIGHT
  else if ieq(n, 3) then CMD_CARET_UP else if ieq(n, 4) then CMD_CARET_DOWN
  else if ieq(n, 5) then CMD_CARET_LINE_START else if ieq(n, 6) then CMD_CARET_LINE_END
  else if ieq(n, 7) then CMD_BACKSPACE else if ieq(n, 8) then CMD_DELETE
  else if ieq(n, 9) then CMD_SELECT_ALL else if ieq(n, 10) then CMD_DELETE_SELECTION
  else if ieq(n, 11) then CMD_COLLAPSE_SELECTION else if ieq(n, 12) then CMD_COPY
  else if ieq(n, 13) then CMD_PASTE else if ieq(n, 14) then CMD_CUT
  else if ieq(n, 15) then CMD_SAVE else if ieq(n, 16) then CMD_UNDO
  else if ieq(n, 17) then CMD_REDO else if ieq(n, 18) then CMD_WRAP_BOLD
  else if ieq(n, 19) then CMD_WRAP_ITALIC else CMD_NONE

fun cmd_of_code_b(n: int): Cmd =
  if ieq(n, 20) then CMD_WRAP_WIKILINK else if ieq(n, 21) then CMD_SELECT_LEFT
  else if ieq(n, 22) then CMD_SELECT_RIGHT else if ieq(n, 23) then CMD_SELECT_UP
  else if ieq(n, 24) then CMD_SELECT_DOWN else if ieq(n, 25) then CMD_SELECT_LINE_START
  else if ieq(n, 26) then CMD_SELECT_LINE_END else if ieq(n, 28) then CMD_INDENT
  else if ieq(n, 30) then CMD_NEWLINE else if ieq(n, 31) then CMD_TEXT_INPUT
  else if ieq(n, 35) then CMD_OPEN_SEARCH else if ieq(n, 36) then CMD_CLOSE_TAB
  else if ieq(n, 37) then CMD_NEW_TAB else if ieq(n, 38) then CMD_NEW_FILE
  else if ieq(n, 39) then CMD_NEW_FOLDER else if ieq(n, 40) then CMD_TOGGLE_VIEW
  else if ieq(n, 41) then CMD_ESCAPE else CMD_NONE

fun cmd_of_code_c(n: int): Cmd =
  if ieq(n, 43) then CMD_WORD_LEFT else if ieq(n, 44) then CMD_WORD_RIGHT
  else if ieq(n, 45) then CMD_SELECT_WORD_LEFT else if ieq(n, 46) then CMD_SELECT_WORD_RIGHT
  else if ieq(n, 47) then CMD_DELETE_WORD_LEFT else if ieq(n, 48) then CMD_DELETE_WORD_RIGHT
  else if ieq(n, 49) then CMD_DOC_START else if ieq(n, 50) then CMD_DOC_END
  else if ieq(n, 51) then CMD_SELECT_DOC_START else if ieq(n, 52) then CMD_SELECT_DOC_END
  else if ieq(n, 53) then CMD_PAGE_UP else if ieq(n, 54) then CMD_PAGE_DOWN
  else if ieq(n, 55) then CMD_SELECT_PAGE_UP else if ieq(n, 56) then CMD_SELECT_PAGE_DOWN
  else if ieq(n, 57) then CMD_NEXT_TAB else if ieq(n, 58) then CMD_PREV_TAB
  else if ieq(n, 59) then CMD_NAV_BACK else if ieq(n, 60) then CMD_NAV_FORWARD
  else if ieq(n, 61) then CMD_OPEN_DOC_SEARCH else if ieq(n, 62) then CMD_KILL_LINE
  else if ieq(n, 63) then CMD_RELOAD_KEYBINDINGS
  else if ieq(n, 64) then CMD_DOC_FONT_INCREASE
  else if ieq(n, 65) then CMD_DOC_FONT_DECREASE
  else if ieq(n, 66) then CMD_SPLIT_TOGGLE
  else CMD_NONE

implement cmd_of_code(n) =
  if ilt(n, 20) then cmd_of_code_a(n)
  else if ilt(n, 42) then cmd_of_code_b(n)
  else cmd_of_code_c(n)

implement is_cmd(a, b) = ieq(cmd_code(a), cmd_code(b))

fun letter_code(k: Letter): int = case+ k of
  | LNone() => 0
  | LA() => 97
  | LB() => 98
  | LC() => 99
  | LE() => 101
  | LF() => 102
  | LI() => 105
  | LK() => 107
  | LN() => 110
  | LO() => 111
  | LP() => 112
  | LS() => 115
  | LSup() => 83
  | LT() => 116
  | LV() => 118
  | LW() => 119
  | LX() => 120
  | LY() => 121
  | LZ() => 122

implement letter_of(n) =
  if ieq(n, 97) then LA
  else if ieq(n, 98) then LB
  else if ieq(n, 99) then LC
  else if ieq(n, 101) then LE
  else if ieq(n, 102) then LF
  else if ieq(n, 105) then LI
  else if ieq(n, 107) then LK
  else if ieq(n, 110) then LN
  else if ieq(n, 111) then LO
  else if ieq(n, 112) then LP
  else if ieq(n, 115) then LS
  else if ieq(n, 83) then LSup
  else if ieq(n, 116) then LT
  else if ieq(n, 118) then LV
  else if ieq(n, 119) then LW
  else if ieq(n, 120) then LX
  else if ieq(n, 121) then LY
  else if ieq(n, 122) then LZ
  else LNone

implement is_letter(a, b) = ieq(letter_code(a), letter_code(b))
