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
  | EditorIdle() => false
  | EditorTyping() => true
  | EditorSelecting() => true
  | EditorPrompt() => false
  | EditorMenu() => false
  | EditorSplitDrag() => false

implement editor_fsm_is_modal(st) = case+ st.kind of
  | EditorIdle() => false
  | EditorTyping() => false
  | EditorSelecting() => false
  | EditorPrompt() => true
  | EditorMenu() => true
  | EditorSplitDrag() => false

fun step_idle(act: EditorAction): EditorState = case+ act.kind of
  | EditorNoAction() => StateIdle()
  | EditorTypeKey() => StateTyping()
  | EditorFocusPrompt() => StatePrompt(act.prompt)
  | EditorDismissPrompt() => StateIdle()
  | EditorOpenMenu() => StateMenu(act.menu)
  | EditorDismissMenu() => StateIdle()
  | EditorStartSelect() => StateSelecting(act.anchor, act.focus)
  | EditorUpdateSelect() => StateIdle()
  | EditorStartSplitDrag() => StateSplitDrag(act.splitPosition)
  | EditorEndSplitDrag() => StateIdle()
  | EditorEscape() => StateIdle()

fun step_typing(act: EditorAction): EditorState = case+ act.kind of
  | EditorNoAction() => StateTyping()
  | EditorTypeKey() => StateTyping()
  | EditorFocusPrompt() => StatePrompt(act.prompt)
  | EditorDismissPrompt() => StateTyping()
  | EditorOpenMenu() => StateMenu(act.menu)
  | EditorDismissMenu() => StateTyping()
  | EditorStartSelect() => StateSelecting(act.anchor, act.focus)
  | EditorUpdateSelect() => StateTyping()
  | EditorStartSplitDrag() => StateTyping()
  | EditorEndSplitDrag() => StateTyping()
  | EditorEscape() => StateIdle()

fun step_selecting(a: int, f: int, act: EditorAction): EditorState = case+ act.kind of
  | EditorNoAction() => StateSelecting(a, f)
  | EditorTypeKey() => StateTyping()
  | EditorFocusPrompt() => StateSelecting(a, f)
  | EditorDismissPrompt() => StateSelecting(a, f)
  | EditorOpenMenu() => StateSelecting(a, f)
  | EditorDismissMenu() => StateSelecting(a, f)
  | EditorStartSelect() => StateSelecting(a, f)
  | EditorUpdateSelect() => StateSelecting(a, act.focus)
  | EditorStartSplitDrag() => StateSelecting(a, f)
  | EditorEndSplitDrag() => StateSelecting(a, f)
  | EditorEscape() => StateIdle()

fun step_prompt(p: PromptKind, act: EditorAction): EditorState = case+ act.kind of
  | EditorNoAction() => StatePrompt(p)
  | EditorTypeKey() => StatePrompt(p)
  | EditorFocusPrompt() => StatePrompt(p)
  | EditorDismissPrompt() => StateIdle()
  | EditorOpenMenu() => StatePrompt(p)
  | EditorDismissMenu() => StatePrompt(p)
  | EditorStartSelect() => StatePrompt(p)
  | EditorUpdateSelect() => StatePrompt(p)
  | EditorStartSplitDrag() => StatePrompt(p)
  | EditorEndSplitDrag() => StatePrompt(p)
  | EditorEscape() => StateIdle()

fun step_menu(m: MenuKind, act: EditorAction): EditorState = case+ act.kind of
  | EditorNoAction() => StateMenu(m)
  | EditorTypeKey() => StateMenu(m)
  | EditorFocusPrompt() => StateMenu(m)
  | EditorDismissPrompt() => StateMenu(m)
  | EditorOpenMenu() => StateMenu(m)
  | EditorDismissMenu() => StateIdle()
  | EditorStartSelect() => StateMenu(m)
  | EditorUpdateSelect() => StateMenu(m)
  | EditorStartSplitDrag() => StateMenu(m)
  | EditorEndSplitDrag() => StateMenu(m)
  | EditorEscape() => StateIdle()

fun step_drag(x: int, act: EditorAction): EditorState = case+ act.kind of
  | EditorNoAction() => StateSplitDrag(x)
  | EditorTypeKey() => StateSplitDrag(x)
  | EditorFocusPrompt() => StateSplitDrag(x)
  | EditorDismissPrompt() => StateSplitDrag(x)
  | EditorOpenMenu() => StateSplitDrag(x)
  | EditorDismissMenu() => StateSplitDrag(x)
  | EditorStartSelect() => StateSplitDrag(x)
  | EditorUpdateSelect() => StateSplitDrag(x)
  | EditorStartSplitDrag() => StateSplitDrag(x)
  | EditorEndSplitDrag() => StateIdle()
  | EditorEscape() => StateIdle()

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
