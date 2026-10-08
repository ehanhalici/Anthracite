#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "ui_workspace/ui_cmd.sats"

fun cmd_code(k: Cmd): int = case+ k of
  | CMD_NONE() => 0
  | CMD_CARET_LEFT() => 1
  | CMD_CARET_RIGHT() => 2
  | CMD_CARET_UP() => 3
  | CMD_CARET_DOWN() => 4
  | CMD_CARET_LINE_START() => 5
  | CMD_CARET_LINE_END() => 6
  | CMD_BACKSPACE() => 7
  | CMD_DELETE() => 8
  | CMD_SELECT_ALL() => 9
  | CMD_DELETE_SELECTION() => 10
  | CMD_COLLAPSE_SELECTION() => 11
  | CMD_COPY() => 12
  | CMD_PASTE() => 13
  | CMD_CUT() => 14
  | CMD_SAVE() => 15
  | CMD_UNDO() => 16
  | CMD_REDO() => 17
  | CMD_WRAP_BOLD() => 18
  | CMD_WRAP_ITALIC() => 19
  | CMD_WRAP_WIKILINK() => 20
  | CMD_SELECT_LEFT() => 21
  | CMD_SELECT_RIGHT() => 22
  | CMD_SELECT_UP() => 23
  | CMD_SELECT_DOWN() => 24
  | CMD_SELECT_LINE_START() => 25
  | CMD_SELECT_LINE_END() => 26
  | CMD_INDENT() => 28
  | CMD_NEWLINE() => 30
  | CMD_TEXT_INPUT() => 31
  | CMD_OPEN_SEARCH() => 35
  | CMD_CLOSE_TAB() => 36
  | CMD_NEW_TAB() => 37
  | CMD_NEW_FILE() => 38
  | CMD_NEW_FOLDER() => 39
  | CMD_TOGGLE_VIEW() => 40
  | CMD_ESCAPE() => 41
  | CMD_WORD_LEFT() => 43
  | CMD_WORD_RIGHT() => 44
  | CMD_SELECT_WORD_LEFT() => 45
  | CMD_SELECT_WORD_RIGHT() => 46
  | CMD_DELETE_WORD_LEFT() => 47
  | CMD_DELETE_WORD_RIGHT() => 48
  | CMD_DOC_START() => 49
  | CMD_DOC_END() => 50
  | CMD_SELECT_DOC_START() => 51
  | CMD_SELECT_DOC_END() => 52
  | CMD_PAGE_UP() => 53
  | CMD_PAGE_DOWN() => 54
  | CMD_SELECT_PAGE_UP() => 55
  | CMD_SELECT_PAGE_DOWN() => 56
  | CMD_NEXT_TAB() => 57
  | CMD_PREV_TAB() => 58

implement is_cmd(a, b) = ieq(cmd_code(a), cmd_code(b))
