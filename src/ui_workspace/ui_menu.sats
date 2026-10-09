staload "mem.sats"
staload "ui_workspace/ui_common.sats"
staload "core_platform/x11.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"

fun draw_menu(f: !Font, r: !Rend, menu: MenuKind, menux: int, menuy: int): void
fun draw_prompt(f: !Font, r: !Rend, b: !Buf, prompt: PromptKind): void
fun edit_line(b: &Buf >> Buf, ev: &event, scratch: &Buf >> Buf): EditResult
fun act_prompt(dir: !Buf, cur: !Buf, name: !Buf, kind: PromptKind): void
fun key_is(ev: &event, k: Key): int
fun ctrl_on(ev: &event): bool
fun shift_on(ev: &event): bool
fun key_char(ev: &event): int

macdef MENU_TEXT_CUT = 0
macdef MENU_TEXT_COPY = 1
macdef MENU_TEXT_PASTE = 2
macdef MENU_TEXT_CLEAR = 3

macdef MENU_IMG_COPY = 0
macdef MENU_IMG_REVEAL = 1
macdef MENU_IMG_DELETE = 2

macdef MENU_TREE_NEW_FILE = 0
macdef MENU_TREE_NEW_FOLDER = 1
macdef MENU_TREE_RENAME = 2
macdef MENU_TREE_DELETE = 3
