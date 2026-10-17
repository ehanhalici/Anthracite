#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/state/editor_fsm.sats"

implement editor_state(kind,anchor,focus,split,prompt,menu) =
  @{kind=kind,anchor=anchor,focus=focus,splitPosition=split,prompt=prompt,menu=menu}
implement editor_action(kind,anchor,focus,split,prompt,menu) =
  @{kind=kind,anchor=anchor,focus=focus,splitPosition=split,prompt=prompt,menu=menu}

implement editor_fsm_name(st) = case+ st.kind of
  | EditorIdle() => "IDLE"
  | EditorTyping() => "TYPING"
  | EditorSelecting() => "SELECTING"
  | EditorPrompt() => "MODAL_PROMPT"
  | EditorMenu() => "MENU_OPEN"
  | EditorSplitDrag() => "SPLIT_DRAG"

implement editor_fsm_is_editing(st) = case+ st.kind of
  | EditorTyping() => true
  | EditorSelecting() => true
  | _ => false

implement editor_fsm_is_modal(st) = case+ st.kind of
  | EditorPrompt() => true
  | EditorMenu() => true
  | _ => false

fun step_idle(act: EditorAction): EditorState = case+ act.kind of
  | EditorTypeKey() => StateTyping()
  | EditorFocusPrompt() => StatePrompt(act.prompt)
  | EditorOpenMenu() => StateMenu(act.menu)
  | EditorStartSelect() => StateSelecting(act.anchor,act.focus)
  | EditorStartSplitDrag() => StateSplitDrag(act.splitPosition)
  | _ => StateIdle()

fun step_typing(act: EditorAction): EditorState = case+ act.kind of
  | EditorTypeKey() => StateTyping()
  | EditorStartSelect() => StateSelecting(act.anchor,act.focus)
  | EditorFocusPrompt() => StatePrompt(act.prompt)
  | EditorOpenMenu() => StateMenu(act.menu)
  | EditorEscape() => StateIdle()
  | _ => StateTyping()

fun step_selecting(a: int, f: int, act: EditorAction): EditorState = case+ act.kind of
  | EditorUpdateSelect() => StateSelecting(a, act.focus)
  | EditorTypeKey() => StateTyping()
  | EditorEscape() => StateIdle()
  | _ => StateSelecting(a, f)

fun step_prompt(p: PromptKind, act: EditorAction): EditorState = case+ act.kind of
  | EditorDismissPrompt() => StateIdle()
  | EditorEscape() => StateIdle()
  | _ => StatePrompt(p)

fun step_menu(m: MenuKind, act: EditorAction): EditorState = case+ act.kind of
  | EditorDismissMenu() => StateIdle()
  | EditorEscape() => StateIdle()
  | _ => StateMenu(m)

fun step_drag(x: int, act: EditorAction): EditorState = case+ act.kind of
  | EditorEndSplitDrag() => StateIdle()
  | EditorEscape() => StateIdle()
  | _ => StateSplitDrag(x)

implement editor_fsm_step(st, act) = case+ st.kind of
  | EditorIdle() => step_idle(act)
  | EditorTyping() => step_typing(act)
  | EditorSelecting() => step_selecting(st.anchor, st.focus, act)
  | EditorPrompt() => step_prompt(st.prompt, act)
  | EditorMenu() => step_menu(st.menu, act)
  | EditorSplitDrag() => step_drag(st.splitPosition, act)

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
