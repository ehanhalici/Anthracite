staload "mem.sats"

fun scan_dir(path: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _): void
fun do_create(dir: !Buf, name: !Buf, isdir: bool): void
fun do_rename(old: !Buf, name: !Buf): void
fun do_rename_resolved(old: !Buf, name: !Buf, out_new: &Buf >> Buf): bool
fun do_delete(path: !Buf): void
fun do_duplicate(src_path: !Buf, is_dir: bool, out_path: &Buf >> Buf): bool
fun do_delete_in_vault(vault: !Buf, target: !Buf, is_dir: bool): bool
fun write_text(path: !Buf, body: !Buf): int
