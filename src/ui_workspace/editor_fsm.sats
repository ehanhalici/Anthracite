staload "ui_workspace/ui_common.sats"

datatype EditorState =
  | StateIdle
  | StateTyping
  | StateSelecting of (int, int)
  | StatePrompt of PromptKind
  | StateMenu of MenuKind
  | StateSplitDrag of int

datatype EditorAction =
  | ActNone
  | ActTypeKey
  | ActFocusPrompt of PromptKind
  | ActDismissPrompt
  | ActOpenMenu of MenuKind
  | ActDismissMenu
  | ActStartSelect of (int, int)
  | ActUpdateSelect of int
  | ActStartSplitDrag of int
  | ActEndSplitDrag
  | ActEscape

fun editor_fsm_name(st: EditorState): string
fun editor_fsm_step(st: EditorState, act: EditorAction): EditorState
fun editor_fsm_is_editing(st: EditorState): bool
fun editor_fsm_is_modal(st: EditorState): bool
fun editor_fsm_selftest(): int
