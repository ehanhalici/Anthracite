staload "mem.sats"
staload "ui_workspace/ui_tab.sats"

fun conf_init_dirs(base: &Buf >> Buf): int
fun conf_get_active_vault(dst: &Buf >> Buf): int
fun conf_set_active_vault(vault: string): void

fun conf_list_vaults(paths: &Buf >> Buf, names: &Buf >> Buf, meta: &Buf >> Buf, cnt: &int >> int): void

fun conf_save_session(vault: string, font_p: string, font_px: int, viewmode: int, split: int, active: int, ts: !Tabs): void
fun conf_load_session(vault: string, font_p: &Buf >> Buf, font_px: &int >> int, viewmode: &int >> int, split: &int >> int, active: &int >> int, ts: Tabs): Tabs
