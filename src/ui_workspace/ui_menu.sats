staload "mem.sats"
staload "ui_workspace/ui_common.sats"
staload "core_platform/x11.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"

fun draw_menu(f: !Font, r: !Rend, menu: MenuKind, menux: int, menuy: int, menuw: int): void
fun draw_prompt(f: !Font, r: !Rend, b: !Buf, prompt: PromptKind): void
fun edit_line(b: &Buf >> Buf, ev: &event, scratch: &Buf >> Buf): EditResult
fun act_prompt(dir: !Buf, cur: !Buf, name: !Buf, kind: PromptKind): void
fun key_is(ev: &event, k: Key): bool
fun ctrl_on(ev: &event): bool
fun shift_on(ev: &event): bool
fun key_char(ev: &event): int

datatype TextItem = TextCut | TextCopy | TextPaste | TextClear
datatype ImageItem = ImageCopy | ImageReveal | ImageDelete
datatype TreeItem = TreeNewFile | TreeNewFolder | TreeRename | TreeDelete

fun text_row(t: TextItem): int
fun image_row(t: ImageItem): int
fun tree_row(t: TreeItem): int
