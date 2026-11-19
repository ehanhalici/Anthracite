staload "mem.sats"
staload "ui_workspace/common/ui_common.sats"
staload "core_platform/x11.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"

fun draw_menu(f: !Font, r: !Rend, menu: MenuKind, menux: int, menuy: int, menuw: int): void
fun draw_prompt(f: !Font, r: !Rend, b: !Buf, prompt: PromptKind): void
fun edit_line(b: &Buf >> Buf, ev: &event, scratch: &Buf >> Buf): EditResult
fun act_prompt(dir: !Buf, cur: !Buf, name: !Buf, kind: PromptKind): void
fun key_is(ev: &event, k: Key): bool
fun ctrl_on(ev: &event): bool
fun shift_on(ev: &event): bool
fun alt_on(ev: &event): bool
fun key_char(ev: &event): int

datatype TextItem = TextCut | TextCopy | TextPaste | TextClear
datatype ImageItem = ImageCopy | ImageReveal | ImageDelete
datatype TreeItem = TreeNewFile | TreeNewFolder | TreeRename | TreeDelete

datatype MenuVariant =
  | MenuVarEditText
  | MenuVarImage
  | MenuVarReadText
  | MenuVarTreeItem
  | MenuVarTreeEmpty

datatype SubmenuL1 =
  | SubNone
  | SubFormat
  | SubParagraph
  | SubInsert

datatype ContextAction =
  | CtxNone
  | CtxWikiLink
  | CtxExtLink
  | CtxBold
  | CtxItalic
  | CtxStrike
  | CtxHighlight
  | CtxBulletList
  | CtxNumberList
  | CtxTaskList
  | CtxHeading1
  | CtxHeading2
  | CtxHeading3
  | CtxHeading4
  | CtxHeading5
  | CtxHeading6
  | CtxFootnote
  | CtxTable
  | CtxCallout
  | CtxHr
  | CtxCodeBlock
  | CtxMathBlock
  | CtxCut
  | CtxCopy
  | CtxPaste
  | CtxPastePlain
  | CtxSelectAll
  | CtxImgCopy
  | CtxImgReveal
  | CtxImgRemove
  | CtxTreeNewNote
  | CtxTreeNewDir
  | CtxTreeDuplicate
  | CtxTreeRename
  | CtxTreeDelete

fun text_row(t: TextItem): int
fun image_row(t: ImageItem): int
fun tree_row(t: TreeItem): int

fun is_sub_none(s: SubmenuL1): bool
fun sub_menu_eq(a: SubmenuL1, b: SubmenuL1): bool
fun menu_var_count(mv: MenuVariant): int
fun menu_sub_count(sub: SubmenuL1): int
fun menu_var_row_y(mv: MenuVariant, idx: int): int
fun menu_sub_row_y(sub: SubmenuL1, idx: int): int
fun menu_var_height(mv: MenuVariant): int
fun menu_sub_height(sub: SubmenuL1): int
fun menu_var_action(mv: MenuVariant, idx: int): ContextAction
fun menu_sub_action(sub: SubmenuL1, idx: int): ContextAction
fun menu_var_submenu(mv: MenuVariant, idx: int): SubmenuL1
fun menu_var_label(mv: MenuVariant, idx: int): string
fun menu_sub_label(sub: SubmenuL1, idx: int): string
fun menu_var_row_for_sub(mv: MenuVariant, sub: SubmenuL1): int
fun menu_var_measure_width(f: !Font, r: !Rend, mv: MenuVariant): int
fun menu_sub_measure_width(f: !Font, r: !Rend, sub: SubmenuL1): int
fun menu_hit_root(mv: MenuVariant, mx: int, my: int, mw: int, x: int, y: int): int
fun menu_hit_sub(sub: SubmenuL1, sx: int, sy: int, sw: int, x: int, y: int): int
fun menu_sub_pos(mv: MenuVariant, sub: SubmenuL1, mx: int, my: int, mw: int, sub_w: int, w: int, h: int, sx: &int >> _, sy: &int >> _, sw: &int >> _): void
fun menu_clamp_root(mv: MenuVariant, mx: &int >> _, my: &int >> _, mw: int, w: int, h: int): void
fun menu_compute_width(f: !Font, r: !Rend): int
fun draw_menu_v2(f: !Font, r: !Rend, mv: MenuVariant, sub: SubmenuL1, mx: int, my: int, mw: int, sx: int, sy: int, sw: int, hx: int, hy: int): void
