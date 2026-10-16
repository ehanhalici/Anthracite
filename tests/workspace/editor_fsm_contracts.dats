#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/state/editor_fsm.sats"

macdef STATE_COUNT = 6
macdef ACTION_COUNT = 11
macdef PAYLOAD_ANCHOR = 3
macdef PAYLOAD_FOCUS = 7
macdef UPDATED_FOCUS = 9

fun state_of(i: int): EditorState =
  if ieq(i,0) then StateIdle() else if ieq(i,1) then StateTyping()
  else if ieq(i,2) then StateSelecting(PAYLOAD_ANCHOR,PAYLOAD_FOCUS)
  else if ieq(i,3) then StatePrompt(PromptNewFile())
  else if ieq(i,4) then StateMenu(MenuText()) else StateSplitDrag(PAYLOAD_ANCHOR)

fun state_code(s: EditorState): int = case+ s of
  | StateIdle() => 0 | StateTyping() => 1 | StateSelecting(_,_) => 2
  | StatePrompt(_) => 3 | StateMenu(_) => 4 | StateSplitDrag(_) => 5

fun action_of(i: int): EditorAction =
  if ieq(i,0) then ActNone() else if ieq(i,1) then ActTypeKey()
  else if ieq(i,2) then ActFocusPrompt(PromptNewFile())
  else if ieq(i,3) then ActDismissPrompt() else if ieq(i,4) then ActOpenMenu(MenuText())
  else if ieq(i,5) then ActDismissMenu()
  else if ieq(i,6) then ActStartSelect(PAYLOAD_ANCHOR,PAYLOAD_FOCUS)
  else if ieq(i,7) then ActUpdateSelect(UPDATED_FOCUS)
  else if ieq(i,8) then ActStartSplitDrag(PAYLOAD_ANCHOR)
  else if ieq(i,9) then ActEndSplitDrag() else ActEscape()

(* Independent transition specification. Columns follow action_of. *)
fun expected_row(state: int): string =
  if ieq(state,0) then "01304020500"
  else if ieq(state,1) then "11314121110"
  else if ieq(state,2) then "21222222220"
  else if ieq(state,3) then "33303333330"
  else if ieq(state,4) then "44444044440" else "55555555500"

fun prompt_ok(p: PromptKind): bool = case+ p of
  | PromptNewFile() => true | PromptNone() => false
  | PromptNewFolder() => false | PromptRename() => false

fun menu_ok(m: MenuKind): bool = case+ m of
  | MenuText() => true | MenuNone() => false | MenuImage() => false | MenuFileTree() => false

fun payload_ok(s: EditorState,action: int): bool = case+ s of
  | StateSelecting(anchor,focus) => ieq(anchor,PAYLOAD_ANCHOR)
    andalso ieq(focus,if ieq(action,7) then UPDATED_FOCUS else PAYLOAD_FOCUS)
  | StatePrompt(p) => prompt_ok(p)
  | StateMenu(m) => menu_ok(m)
  | StateSplitDrag(x) => ieq(x,PAYLOAD_ANCHOR)
  | StateIdle() => true | StateTyping() => true

fun check_transition(state: int,action: int): int = let
  val next=editor_fsm_step(state_of(state),action_of(action))
  val expected=isub(c_str_byte(expected_row(state),action),CHAR_ZERO)
  val code=state_code(next)
  val flags=editor_fsm_is_editing(next) = (ieq(code,1) orelse ieq(code,2))
    andalso editor_fsm_is_modal(next) = ieq(code,3)
in if ieq(code,expected) andalso payload_ok(next,action) andalso flags then 0 else 1 end

fun transitions{n:nat} .<n>. (remaining: int(n),index: int): int =
  if remaining > 0 then let
    val errors=check_transition(idiv(index,ACTION_COUNT),imod(index,ACTION_COUNT))
  in iadd(errors,transitions(remaining-1,iadd(index,1))) end else 0

implement main0() = let
  val before=mem_live()
  val cases=imul(STATE_COUNT,ACTION_COUNT)
  val errors=transitions(airlock_nat(cases),0)
  val leak=if ieq(before,mem_live()) then 0 else 1
  val total=iadd(errors,leak)
  val ()=println!("event=editor_fsm_contracts transitions=",cases," errors=",total)
in if igt(total,0) then exit(1) else () end
