#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/state/editor_fsm.sats"

implement editor_fsm_name(st) = case+ st of
  | StateIdle() => "IDLE"
  | StateTyping() => "TYPING"
  | StateSelecting(_, _) => "SELECTING"
  | StatePrompt(_) => "MODAL_PROMPT"
  | StateMenu(_) => "MENU_OPEN"
  | StateSplitDrag(_) => "SPLIT_DRAG"

implement editor_fsm_is_editing(st) = case+ st of
  | StateTyping() => true
  | StateSelecting(_, _) => true
  | _ => false

implement editor_fsm_is_modal(st) = case+ st of
  | StatePrompt(_) => true
  | StateMenu(_) => true
  | _ => false

fun step_idle(act: EditorAction): EditorState = case+ act of
  | ActTypeKey() => StateTyping()
  | ActFocusPrompt(p) => StatePrompt(p)
  | ActOpenMenu(m) => StateMenu(m)
  | ActStartSelect(a, f) => StateSelecting(a, f)
  | ActStartSplitDrag(x) => StateSplitDrag(x)
  | _ => StateIdle()

fun step_typing(act: EditorAction): EditorState = case+ act of
  | ActTypeKey() => StateTyping()
  | ActStartSelect(a, f) => StateSelecting(a, f)
  | ActFocusPrompt(p) => StatePrompt(p)
  | ActOpenMenu(m) => StateMenu(m)
  | ActEscape() => StateIdle()
  | _ => StateTyping()

fun step_selecting(a: int, f: int, act: EditorAction): EditorState = case+ act of
  | ActUpdateSelect(f2) => StateSelecting(a, f2)
  | ActTypeKey() => StateTyping()
  | ActEscape() => StateIdle()
  | _ => StateSelecting(a, f)

fun step_prompt(p: PromptKind, act: EditorAction): EditorState = case+ act of
  | ActDismissPrompt() => StateIdle()
  | ActEscape() => StateIdle()
  | _ => StatePrompt(p)

fun step_menu(m: MenuKind, act: EditorAction): EditorState = case+ act of
  | ActDismissMenu() => StateIdle()
  | ActEscape() => StateIdle()
  | _ => StateMenu(m)

fun step_drag(x: int, act: EditorAction): EditorState = case+ act of
  | ActEndSplitDrag() => StateIdle()
  | ActEscape() => StateIdle()
  | _ => StateSplitDrag(x)

implement editor_fsm_step(st, act) = case+ st of
  | StateIdle() => step_idle(act)
  | StateTyping() => step_typing(act)
  | StateSelecting(a, f) => step_selecting(a, f, act)
  | StatePrompt(p) => step_prompt(p, act)
  | StateMenu(m) => step_menu(m, act)
  | StateSplitDrag(x) => step_drag(x, act)

implement editor_fsm_selftest() = let
  val s0 = StateIdle()
  val s1 = editor_fsm_step(s0, ActTypeKey())
  val ok1 = editor_fsm_is_editing(s1)
  val s2 = editor_fsm_step(s1, ActStartSelect(10, 20))
  val ok2 = editor_fsm_is_editing(s2)
  val s3 = editor_fsm_step(s2, ActEscape())
  val s4 = editor_fsm_step(s3, ActFocusPrompt(PromptNewFile))
  val ok3 = editor_fsm_is_modal(s4)
  val s5 = editor_fsm_step(s4, ActDismissPrompt())
in
  if ok1 andalso ok2 andalso ok3 then 1 else 0
end
