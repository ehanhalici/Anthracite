staload "mem.sats"
staload "core_platform/x11.sats"
staload "core_render/render.sats"
staload "data_font/font.sats"

fun draw_menu(f: !Font, r: !Rend, menu: int, menux: int, menuy: int): void
fun draw_prompt(f: !Font, r: !Rend, b: !Buf, prompt: int): void
fun edit_line(b: &Buf >> Buf, ev: &event, scratch: &Buf >> Buf): int
fun act_prompt(dir: !Buf, cur: !Buf, name: !Buf, kind: int): void
fun key_is(ev: &event, id: int): int
fun ctrl_on(ev: &event): int
fun shift_on(ev: &event): int
fun key_char(ev: &event): int
