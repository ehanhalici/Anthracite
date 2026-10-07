staload "mem.sats"

fun scan_dir(path: !Buf, depth: int, meta: &Buf >> _, text: &Buf >> _, n: &int >> _): void
fun do_create(dir: !Buf, name: !Buf, isdir: int): void
fun do_rename(old: !Buf, name: !Buf): void
fun do_delete(path: !Buf): void
fun write_text(path: !Buf, body: !Buf): int
