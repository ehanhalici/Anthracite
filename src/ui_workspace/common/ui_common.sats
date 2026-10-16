staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"

fun buffer_preserve(b: &Buf >> Buf): void
fun buffer_clear(b: &Buf >> Buf): void
fun buffer_push_byte(b: &Buf >> Buf, v: int): void
fun push_if(b: &Buf >> Buf, go: Toggle, v: int): void
fun buffer_append_string_range(b: &Buf >> Buf, s: string, i: int, n: int): void
fun buffer_append_string(b: &Buf >> Buf, s: string): void
fun buffer_append_string_if(b: &Buf >> Buf, go: Toggle, s: string): void
fun buffer_append_range(dst: &Buf >> Buf, src: !Buf, i: int, n: int): void
fun buffer_append_all(dst: &Buf >> Buf, src: !Buf): void
fun buffer_append_range_if(dst: &Buf >> Buf, src: !Buf, i: int, n: int, go: Toggle): void
fun buffer_append_integer(b: &Buf >> Buf, n: int): void
fun buffer_equal_from(a: !Buf, b: !Buf, i: int): bool
fun buffer_clone(src: !Buf): Buf
fun buffer_c_string(b: !Buf): string
fun ends(b: !Buf, s: string): bool
fun is_image_path(path: !Buf): bool
fun draw_s(f: !Font, r: !Rend, x: int, y: int, s: string, c: uint): void
fun join2(a: !Buf, b: !Buf): Buf
fun last_slash(path: !Buf, i: int, a: int): int
fun base_name(path: !Buf, dst: &Buf >> Buf): void
fun dirname_of(path: !Buf, dst: &Buf >> Buf): void
fun child_path(dir: !Buf, name: !Buf, dst: &Buf >> Buf): void
fun row_path(text: !Buf, meta: !Buf, row: int, dst: &Buf >> Buf): void
fun has_dot_char(b: !Buf, i: int): bool
fun texture_is_valid(t: uint): int
fun filter_text(b: !Buf, n: int): int
fun scan_skip(name: !Buf): bool
fun meta_dir(meta: !Buf, row: int): DirMark
fun meta_depth(meta: !Buf, row: int): int
fun meta_text_off(meta: !Buf, row: int): int
fun meta_text_len(meta: !Buf, row: int): int
fun path_is_dir(path: string): bool
fun child_kind(child: !Buf, skip: Toggle, isdir: DirMark): DirMark

macdef MAX_TREE_ITEMS = 400
macdef MAX_TREE_DEPTH = 6
macdef MAX_SEARCH_HITS = 200
macdef MAX_DIR_ENTRIES = 65536

datatype Sidebar = SideNone | SideFiles | SideSearch | SideConfig
datatype MenuKind = MenuNone | MenuText | MenuImage | MenuFileTree
datatype PromptKind = PromptNone | PromptNewFile | PromptNewFolder | PromptRename
datatype ViewMode = ViewEdit | ViewRead
datatype EditResult = EditNone | EditChanged | EditSubmit | EditCancel
datatype DragKind = DragNone | DragTab | DragFile | DragSplit | DragEditor

fun is_side_none(x: Sidebar): bool
fun is_side_files(x: Sidebar): bool
fun is_side_search(x: Sidebar): bool
fun is_side_config(x: Sidebar): bool
fun is_menu_none(x: MenuKind): bool
fun is_menu_text(x: MenuKind): bool
fun is_menu_image(x: MenuKind): bool
fun is_menu_filetree(x: MenuKind): bool
fun is_prompt_none(x: PromptKind): bool
fun is_prompt_newfile(x: PromptKind): bool
fun is_prompt_newfolder(x: PromptKind): bool
fun is_prompt_rename(x: PromptKind): bool
fun is_view_edit(x: ViewMode): bool
fun is_view_read(x: ViewMode): bool
fun is_edit_none(x: EditResult): bool
fun is_edit_changed(x: EditResult): bool
fun is_edit_submit(x: EditResult): bool
fun is_edit_cancel(x: EditResult): bool
fun is_drag_none(x: DragKind): bool
fun is_drag_tab(x: DragKind): bool
fun is_drag_file(x: DragKind): bool
fun is_drag_split(x: DragKind): bool
fun is_drag_editor(x: DragKind): bool
fun view_mode_code(v: ViewMode): int
fun view_mode_of_code(n: int): ViewMode








macdef UI_SIDEBAR_WIDTH = 280
macdef UI_SIDEBAR_MIN_WIDTH = 160
macdef UI_SIDEBAR_GRAB_WIDTH = 6
macdef UI_TOPBAR_HEIGHT = 36
macdef UI_TOPBAR_BTN_WIDTH = 96
macdef UI_MENU_WIDTH = 230
macdef UI_MENU_ITEM_HEIGHT = 24
macdef UI_TREE_ROW_HEIGHT = 18
macdef UI_SEARCH_ROW_HEIGHT = 18
