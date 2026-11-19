staload "mem.sats"
staload "flag.sats"
staload "core_platform/x11.sats"
staload "ui_workspace/commands/ui_cmd.sats"

macdef KEYMOD_CTRL = 1
macdef KEYMOD_ALT = 2
macdef KEYMOD_SHIFT = 4

macdef KEYCODE_LEFT = 257
macdef KEYCODE_RIGHT = 258
macdef KEYCODE_UP = 259
macdef KEYCODE_DOWN = 260
macdef KEYCODE_BACKSPACE = 261
macdef KEYCODE_DELETE = 262
macdef KEYCODE_HOME = 263
macdef KEYCODE_END = 264
macdef KEYCODE_RETURN = 265
macdef KEYCODE_TAB = 266
macdef KEYCODE_ESCAPE = 267
macdef KEYCODE_PAGE_UP = 268
macdef KEYCODE_PAGE_DOWN = 269
macdef KEYCODE_F1 = 272
macdef KEYCODE_F12 = 283
macdef KEYCODE_WHEEL_UP = 288
macdef KEYCODE_WHEEL_DOWN = 289

macdef KEYMAP_ENTRY_WORDS = 6
macdef KEYMAP_FLD_MOD1 = 0
macdef KEYMAP_FLD_KEY1 = 1
macdef KEYMAP_FLD_MOD2 = 2
macdef KEYMAP_FLD_KEY2 = 3
macdef KEYMAP_FLD_CMD = 4
macdef KEYMAP_FLD_ARG = 5
macdef KEYMAP_ENTRY_BYTES = 24

fun keymap_count(km: !Buf): int
fun keymap_clear(km: &Buf >> _): void
fun keymap_bind(km: &Buf >> _, mod1: int, key1: int, mod2: int, key2: int, cmd: Cmd): void
fun keymap_unbind(km: &Buf >> _, mod1: int, key1: int, mod2: int, key2: int): void
fun keymap_load_defaults(km: &Buf >> _): void

fun keymap_event_mods(ev: &event): int
fun keymap_event_key(ev: &event): int
fun keymap_resolve(
  km: !Buf, chord_active: &Toggle >> _, chord_mods: &int >> _, chord_key: &int >> _,
  mods: int, key: int, act: Toggle
): Cmd
fun keymap_resolve_wheel(km: !Buf, ev: &event): Cmd

fun keymap_cmd_name(cmd: Cmd): string
fun keymap_cmd_by_name(b: !Buf, st: int, en: int): Cmd
fun keymap_parse_sequence(
  src: !Buf, st: int, en: int,
  m1: &int >> _, k1: &int >> _, m2: &int >> _, k2: &int >> _
): bool

fun keymap_format_chord(mods: int, key: int, dst: &Buf >> _): void
fun keymap_format_entry(km: !Buf, idx: int, dst: &Buf >> _): void
fun keymap_default_json(dst: &Buf >> _): void
