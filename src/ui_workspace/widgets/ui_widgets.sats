staload "mem.sats"
staload "flag.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"

#define UI_ICON_NONE 0
#define UI_ICON_RIGHT_ARROW 1
#define UI_ICON_DOWN_ARROW 2
#define UI_ICON_LEFT_ARROW 3
#define UI_ICON_UP_ARROW 4
#define UI_ICON_CHECK 5
#define UI_ICON_CHECK_EMPTY 6
#define UI_ICON_CLOSE 7
#define UI_ICON_FOLDER 8
#define UI_ICON_FILE 9
#define UI_ICON_SEARCH 10
#define UI_ICON_SETTINGS 11
#define UI_ICON_PLUS 12
#define UI_ICON_SPLIT 13

(* Two-state visual flags and orientation (Toggle lives in flag.sats). *)
datatype Axis = Horizontal | Vertical
datatype Axis = Horizontal | Vertical

fun is_vertical(a: Axis): bool

fun ui_draw_border(r: !Rend, x: int, y: int, w: int, h: int, th: int, col: uint): void
fun ui_draw_shadow(r: !Rend, x: int, y: int, w: int, h: int, rad: int): void
fun ui_draw_icon(f: !Font, r: !Rend, icon: int, x: int, y: int, sz: int, col: uint): void

fun ui_divider(r: !Rend, x: int, y: int, len: int, is_vert: Axis): void
fun ui_badge(f: !Font, r: !Rend, x: int, y: int, s: string, bg_col: uint, text_col: uint): void
fun ui_button(f: !Font, r: !Rend, x: int, y: int, w: int, h: int, text: string, is_hover: Toggle, is_active: Toggle): void
fun ui_hover_label(f: !Font, r: !Rend, x: int, y: int, w: int, h: int, text: string, is_hover: Toggle): void
fun ui_expander(f: !Font, r: !Rend, x: int, y: int, is_expanded: Toggle, is_hover: Toggle): void
fun ui_scroll_bar(r: !Rend, x: int, y: int, w: int, h: int, is_vert: Axis, total_len: int, visible_len: int, scroll_pos: int, is_hover: Toggle, is_dragging: Toggle): void
fun ui_line_edit_draw(f: !Font, r: !Rend, x: int, y: int, w: int, h: int, b: !Buf, cursor: int, mark: int, is_focused: Toggle, placeholder: string): void
fun ui_pane_begin(r: !Rend, x: int, y: int, w: int, h: int, bg_col: uint): void
fun ui_pane_draw_header(f: !Font, r: !Rend, x: int, y: int, w: int, title: string, has_close: Toggle): void

fun ui_menu_bar_button(f: !Font, r: !Rend, x: int, y: int, w: int, h: int, text: string, is_active: Toggle, is_hover: Toggle): void
fun ui_icon_button(f: !Font, r: !Rend, icon: int, text: string, x: int, y: int, w: int, h: int, is_active: Toggle, is_hover: Toggle): void
fun ui_cell(f: !Font, r: !Rend, x: int, y: int, w: int, h: int, depth: int, is_expandable: Toggle, is_expanded: Toggle, icon: int, label: string, value_text: string, is_selected: Toggle, is_hover: Toggle): void
fun ui_loading_overlay(f: !Font, r: !Rend, w: int, h: int, progress_pct: int, title: string, status_msg: string): void
fun ui_code_slice(f: !Font, r: !Rend, x: int, y: int, w: int, h: int, line_num: int, code_text: string, is_active: Toggle, has_bp: Toggle, is_hover: Toggle): void
fun ui_error_label(f: !Font, r: !Rend, x: int, y: int, text: string): void
fun ui_help_label(f: !Font, r: !Rend, x: int, y: int, text: string): void
