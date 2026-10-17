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
macdef MATRIX_REPETITIONS = 128
macdef PAYLOAD_BOUNDARY_COUNT = 4
macdef MODAL_PAYLOAD_COUNT = 4
macdef MODAL_KIND_COUNT = 2

fun state_of(i: int): EditorState =
  if ieq(i,0) then StateIdle() else if ieq(i,1) then StateTyping()
  else if ieq(i,2) then StateSelecting(PAYLOAD_ANCHOR,PAYLOAD_FOCUS)
  else if ieq(i,3) then StatePrompt(PromptNewFile())
  else if ieq(i,4) then StateMenu(MenuText()) else StateSplitDrag(PAYLOAD_ANCHOR)

fun state_code(s: EditorState): int = case+ s.kind of
  | EditorIdle() => 0 | EditorTyping() => 1 | EditorSelecting() => 2
  | EditorPrompt() => 3 | EditorMenu() => 4 | EditorSplitDrag() => 5

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

fun expected_name(code: int): string =
  if ieq(code,0) then "IDLE" else if ieq(code,1) then "TYPING"
  else if ieq(code,2) then "SELECTING" else if ieq(code,3) then "MODAL_PROMPT"
  else if ieq(code,4) then "MENU_OPEN" else "SPLIT_DRAG"

fun payload_ok(s: EditorState,action: int): bool = case+ s.kind of
  | EditorSelecting() => ieq(s.anchor,PAYLOAD_ANCHOR)
    andalso ieq(s.focus,if ieq(action,7) then UPDATED_FOCUS else PAYLOAD_FOCUS)
  | EditorPrompt() => prompt_ok(s.prompt)
  | EditorMenu() => menu_ok(s.menu)
  | EditorSplitDrag() => ieq(s.splitPosition,PAYLOAD_ANCHOR)
  | EditorIdle() => true | EditorTyping() => true

fun check_transition(state: int,action: int): int = let
  val next=editor_fsm_step(state_of(state),action_of(action))
  val expected=isub(c_str_byte(expected_row(state),action),CHAR_ZERO)
  val code=state_code(next)
  val named=ieq(c_strcmp(editor_fsm_name(next),expected_name(expected)),0)
  val flags=editor_fsm_is_editing(next) = (ieq(code,1) orelse ieq(code,2))
    andalso editor_fsm_is_modal(next) = (ieq(code,3) orelse ieq(code,4))
in if ieq(code,expected) andalso named andalso payload_ok(next,action) andalso flags then 0 else 1 end

fun transitions{n:nat} .<n>. (remaining: int(n),index: int): int =
  if remaining > 0 then let
    val errors=check_transition(idiv(index,ACTION_COUNT),imod(index,ACTION_COUNT))
  in iadd(errors,transitions(remaining-1,iadd(index,1))) end else 0

fun check_modal_variants(): int = let
  val menus = editor_fsm_is_modal(StateMenu(MenuNone()))
    andalso editor_fsm_is_modal(StateMenu(MenuText()))
    andalso editor_fsm_is_modal(StateMenu(MenuImage()))
    andalso editor_fsm_is_modal(StateMenu(MenuFileTree()))
  val prompts = editor_fsm_is_modal(StatePrompt(PromptNone()))
    andalso editor_fsm_is_modal(StatePrompt(PromptNewFile()))
    andalso editor_fsm_is_modal(StatePrompt(PromptNewFolder()))
    andalso editor_fsm_is_modal(StatePrompt(PromptRename()))
in if menus andalso prompts then 0 else 1 end

fun boundary_value(index: int): int =
  if ieq(index,0) then isub(~2147483647,1) else if ieq(index,1) then ~1
  else if ieq(index,2) then 0 else 2147483647

fun check_payload_boundary(index: int): int = let
  val anchor=boundary_value(imod(index,PAYLOAD_BOUNDARY_COUNT))
  val focus=boundary_value(imod(idiv(index,PAYLOAD_BOUNDARY_COUNT),PAYLOAD_BOUNDARY_COUNT))
  val updated=boundary_value(idiv(index,imul(PAYLOAD_BOUNDARY_COUNT,PAYLOAD_BOUNDARY_COUNT)))
  val selection=editor_fsm_step(StateIdle(),ActStartSelect(anchor,focus))
  val unchanged=editor_fsm_step(selection,ActNone())
  val next=editor_fsm_step(unchanged,ActUpdateSelect(updated))
  val drag=editor_fsm_step(StateTyping(),ActStartSplitDrag(anchor))
  val split=editor_fsm_step(StateIdle(),ActStartSplitDrag(anchor))
  val ignored=editor_fsm_step(split,ActUpdateSelect(focus))
  val ok=ieq(state_code(selection),2) andalso ieq(unchanged.anchor,anchor)
    andalso ieq(unchanged.focus,focus) andalso ieq(next.anchor,anchor)
    andalso ieq(next.focus,updated) andalso ieq(state_code(drag),1)
    andalso ieq(state_code(ignored),5) andalso ieq(ignored.splitPosition,anchor)
in if ok then 0 else 1 end

fun payload_boundaries{n:nat} .<n>. (left: int(n),index: int): int =
  if left = 0 then 0 else iadd(check_payload_boundary(index),payload_boundaries(left-1,iadd(index,1)))

fun repeated_matrix{n:nat} .<n>. (left: int(n),cases: int): int =
  if left = 0 then 0 else iadd(transitions(airlock_nat(cases),0),repeated_matrix(left-1,cases))

fun prompt_value(index: int): PromptKind =
  if ieq(index,0) then PromptNone() else if ieq(index,1) then PromptNewFile()
  else if ieq(index,2) then PromptNewFolder() else PromptRename()
fun prompt_number(prompt: PromptKind): int = case+ prompt of
  | PromptNone() => 0 | PromptNewFile() => 1 | PromptNewFolder() => 2 | PromptRename() => 3
fun menu_value(index: int): MenuKind =
  if ieq(index,0) then MenuNone() else if ieq(index,1) then MenuText()
  else if ieq(index,2) then MenuImage() else MenuFileTree()
fun menu_number(menu: MenuKind): int = case+ menu of
  | MenuNone() => 0 | MenuText() => 1 | MenuImage() => 2 | MenuFileTree() => 3
fun check_modal_payload(index: int): int = let
  val action=imod(index,ACTION_COUNT)
  val variant=imod(idiv(index,ACTION_COUNT),MODAL_PAYLOAD_COUNT)
  val prompt=ilt(index,imul(ACTION_COUNT,MODAL_PAYLOAD_COUNT))
  val state=if prompt then StatePrompt(prompt_value(variant)) else StateMenu(menu_value(variant))
  val next=editor_fsm_step(state,action_of(action))
  val closed=ieq(action,10) orelse ieq(action,if prompt then 3 else 5)
  val ok=if closed then ieq(state_code(next),0) else if prompt then
    ieq(state_code(next),3) andalso ieq(prompt_number(next.prompt),variant)
    else ieq(state_code(next),4) andalso ieq(menu_number(next.menu),variant)
in if ok then 0 else 1 end
fun modal_payloads{n:nat} .<n>. (left: int(n),index: int): int =
  if left = 0 then 0 else iadd(check_modal_payload(index),modal_payloads(left-1,iadd(index,1)))

implement main0() = let
  val before=mem_live()
  val cases=imul(STATE_COUNT,ACTION_COUNT)
  val boundaries=imul(PAYLOAD_BOUNDARY_COUNT,imul(PAYLOAD_BOUNDARY_COUNT,PAYLOAD_BOUNDARY_COUNT))
  val modal=imul(MODAL_KIND_COUNT,imul(MODAL_PAYLOAD_COUNT,ACTION_COUNT))
  val errors=iadd(repeated_matrix(MATRIX_REPETITIONS,cases),
    iadd(payload_boundaries(airlock_nat(boundaries),0),
      iadd(modal_payloads(airlock_nat(modal),0),check_modal_variants())))
  val leak=if ieq(before,mem_live()) then 0 else 1
  val total=iadd(errors,leak)
  val ()=println!("event=editor_fsm_contracts transitions=",cases," repetitions=",MATRIX_REPETITIONS,
    " payload_boundaries=",boundaries," modal_transitions=",modal," errors=",total)
in if igt(total,0) then exit(1) else () end
