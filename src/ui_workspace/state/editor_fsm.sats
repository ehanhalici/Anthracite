staload "ui_workspace/common/ui_common.sats"

datatype EditorStateKind =
  | EditorIdle | EditorTyping | EditorSelecting
  | EditorPrompt | EditorMenu | EditorSplitDrag

datatype EditorActionKind =
  | EditorNoAction | EditorTypeKey | EditorFocusPrompt | EditorDismissPrompt
  | EditorOpenMenu | EditorDismissMenu | EditorStartSelect | EditorUpdateSelect
  | EditorStartSplitDrag | EditorEndSplitDrag | EditorEscape

(* Flat values: no GC-dependent constructor boxes on a transition. Only fields
   selected by kind are meaningful. Builders initialize the remaining fields. *)
typedef EditorState = @{kind=EditorStateKind,anchor=int,focus=int,
  splitPosition=int,prompt=PromptKind,menu=MenuKind}
typedef EditorAction = @{kind=EditorActionKind,anchor=int,focus=int,
  splitPosition=int,prompt=PromptKind,menu=MenuKind}
fun editor_state(kind: EditorStateKind,anchor: int,focus: int,split: int,
  prompt: PromptKind,menu: MenuKind): EditorState
fun editor_action(kind: EditorActionKind,anchor: int,focus: int,split: int,
  prompt: PromptKind,menu: MenuKind): EditorAction

macdef StateIdle() = editor_state(EditorIdle(),0,0,0,PromptNone(),MenuNone())
macdef StateTyping() = editor_state(EditorTyping(),0,0,0,PromptNone(),MenuNone())
macdef StateSelecting(a,f) = editor_state(EditorSelecting(),,(a),,(f),0,PromptNone(),MenuNone())
macdef StatePrompt(p) = editor_state(EditorPrompt(),0,0,0,,(p),MenuNone())
macdef StateMenu(m) = editor_state(EditorMenu(),0,0,0,PromptNone(),,(m))
macdef StateSplitDrag(x) = editor_state(EditorSplitDrag(),0,0,,(x),PromptNone(),MenuNone())
macdef ActNone() = editor_action(EditorNoAction(),0,0,0,PromptNone(),MenuNone())
macdef ActTypeKey() = editor_action(EditorTypeKey(),0,0,0,PromptNone(),MenuNone())
macdef ActFocusPrompt(p) = editor_action(EditorFocusPrompt(),0,0,0,,(p),MenuNone())
macdef ActDismissPrompt() = editor_action(EditorDismissPrompt(),0,0,0,PromptNone(),MenuNone())
macdef ActOpenMenu(m) = editor_action(EditorOpenMenu(),0,0,0,PromptNone(),,(m))
macdef ActDismissMenu() = editor_action(EditorDismissMenu(),0,0,0,PromptNone(),MenuNone())
macdef ActStartSelect(a,f) = editor_action(EditorStartSelect(),,(a),,(f),0,PromptNone(),MenuNone())
macdef ActUpdateSelect(f) = editor_action(EditorUpdateSelect(),0,,(f),0,PromptNone(),MenuNone())
macdef ActStartSplitDrag(x) = editor_action(EditorStartSplitDrag(),0,0,,(x),PromptNone(),MenuNone())
macdef ActEndSplitDrag() = editor_action(EditorEndSplitDrag(),0,0,0,PromptNone(),MenuNone())
macdef ActEscape() = editor_action(EditorEscape(),0,0,0,PromptNone(),MenuNone())

fun editor_fsm_name(st: EditorState): string
fun editor_fsm_step(st: EditorState, act: EditorAction): EditorState
fun editor_fsm_is_editing(st: EditorState): bool
fun editor_fsm_is_modal(st: EditorState): bool
fun editor_fsm_selftest(): int
