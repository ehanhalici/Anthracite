staload "mem.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"

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

fun ui_draw_border(r: !Rend, x: int, y: int, w: int, h: int, th: int, col: uint): void
fun ui_draw_shadow(r: !Rend, x: int, y: int, w: int, h: int, rad: int): void
fun ui_draw_icon(f: !Font, r: !Rend, icon: int, x: int, y: int, sz: int, col: uint): void

fun ui_divider(r: !Rend, x: int, y: int, len: int, is_vert: int): void
fun ui_label(f: !Font, r: !Rend, x: int, y: int, s: string, col: uint): int
fun ui_label_multiline(f: !Font, r: !Rend, x: int, y: int, max_w: int, s: string, col: uint, lh: int): int
fun ui_badge(f: !Font, r: !Rend, x: int, y: int, s: string, bg_col: uint, text_col: uint): int
fun ui_button(f: !Font, r: !Rend, x: int, y: int, w: int, h: int, text: string, is_hover: int, is_active: int): void
fun ui_hover_label(f: !Font, r: !Rend, x: int, y: int, w: int, h: int, text: string, is_hover: int): void
fun ui_expander(f: !Font, r: !Rend, x: int, y: int, is_expanded: int, is_hover: int): void
fun ui_sort_header(f: !Font, r: !Rend, x: int, y: int, w: int, h: int, text: string, is_sorted: int, is_ascending: int, is_hover: int): void
fun ui_toggle_switch(r: !Rend, x: int, y: int, w: int, h: int, is_on: int): void
fun ui_slider(r: !Rend, x: int, y: int, w: int, h: int, val_pct: int, is_hover: int, is_active: int): void
fun ui_scroll_bar(r: !Rend, x: int, y: int, w: int, h: int, is_vert: int, total_len: int, visible_len: int, scroll_pos: int, is_hover: int, is_dragging: int): void
fun ui_line_edit_draw(f: !Font, r: !Rend, x: int, y: int, w: int, h: int, b: !Buf, cursor: int, mark: int, is_focused: int, placeholder: string): void
fun ui_pane_begin(r: !Rend, x: int, y: int, w: int, h: int, bg_col: uint): void
fun ui_pane_draw_header(f: !Font, r: !Rend, x: int, y: int, w: int, title: string, has_close: int): void
fun ui_color_picker(r: !Rend, x: int, y: int, w: int, h: int, r_val: int, g_val: int, b_val: int): void
fun ui_hue_strip(r: !Rend, x: int, y: int, w: int, h: int, hue_pct: int): void
