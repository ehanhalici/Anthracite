staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"

fun touchb(b: &Buf >> Buf): void
fun bclear(b: &Buf >> Buf): void
fun bpush(b: &Buf >> Buf, v: int): void
fun push_if(b: &Buf >> Buf, go: Toggle, v: int): void
fun bappend(b: &Buf >> Buf, s: string, i: int, n: int): void
fun bstr(b: &Buf >> Buf, s: string): void
fun bstr_if(b: &Buf >> Buf, go: Toggle, s: string): void
fun bcat(dst: &Buf >> Buf, src: !Buf, i: int, n: int): void
fun bcat_all(dst: &Buf >> Buf, src: !Buf): void
fun bcat_if(dst: &Buf >> Buf, src: !Buf, i: int, n: int, go: Toggle): void
fun b_app_int(b: &Buf >> Buf, n: int): void
fun beq(a: !Buf, b: !Buf, i: int): bool
fun bcopy(src: !Buf): Buf
fun cstr(b: !Buf): string
fun ends(b: !Buf, s: string): bool
fun draw_s(f: !Font, r: !Rend, x: int, y: int, s: string, c: uint): void
fun join2(a: !Buf, b: !Buf): Buf
fun last_slash(path: !Buf, i: int, a: int): int
fun base_name(path: !Buf, dst: &Buf >> Buf): void
fun dirname_of(path: !Buf, dst: &Buf >> Buf): void
fun child_path(dir: !Buf, name: !Buf, dst: &Buf >> Buf): void
fun row_path(text: !Buf, meta: !Buf, row: int, dst: &Buf >> Buf): void
fun has_dot_char(b: !Buf, i: int): bool
fun uok(t: uint): int
fun filter_text(b: !Buf, n: int): int
fun scan_skip(name: !Buf): bool
fun meta_dir(meta: !Buf, row: int): DirMark
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
datatype DragKind = DragNone | DragTab | DragFile

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
fun view_mode_code(v: ViewMode): int
fun view_mode_of_code(n: int): ViewMode








macdef UI_SIDEBAR_WIDTH = 280
macdef UI_TOPBAR_HEIGHT = 36
macdef UI_TOPBAR_BTN_WIDTH = 96
macdef UI_MENU_WIDTH = 230
macdef UI_MENU_ITEM_HEIGHT = 24
macdef UI_TREE_ROW_HEIGHT = 18
macdef UI_SEARCH_ROW_HEIGHT = 18
