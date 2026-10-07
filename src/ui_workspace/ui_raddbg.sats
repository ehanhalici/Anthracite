staload "mem.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"

fun rd_menu_bar_button(f: !Font, r: !Rend, x: int, y: int, w: int, h: int, text: string, is_active: int, is_hover: int): void
fun rd_icon_button(f: !Font, r: !Rend, icon: int, text: string, x: int, y: int, w: int, h: int, is_active: int, is_hover: int): void
fun rd_cell(f: !Font, r: !Rend, x: int, y: int, w: int, h: int, depth: int, is_expandable: int, is_expanded: int, icon: int, label: string, value_text: string, is_selected: int, is_hover: int): void
fun rd_loading_overlay(f: !Font, r: !Rend, w: int, h: int, progress_pct: int, title: string, status_msg: string): void
fun rd_code_slice(f: !Font, r: !Rend, x: int, y: int, w: int, h: int, line_num: int, code_text: string, is_active: int, has_bp: int, is_hover: int): void
fun rd_label(f: !Font, r: !Rend, x: int, y: int, text: string): int
fun rd_error_label(f: !Font, r: !Rend, x: int, y: int, text: string): int
fun rd_help_label(f: !Font, r: !Rend, x: int, y: int, text: string): int
