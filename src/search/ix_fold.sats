#define ATS_DYNLOADFLAG 0

staload "mem.sats"
staload "data_ast/doc.sats"

fun fold_next_buf(b: !Buf, i: int, n: int, cp: &int >> _, clen: &int >> _): void
fun fold_range_buf(src: !Buf, st: int, en: int, dst: &Buf >> _, omap: &Buf >> _): void
fun fold_range_doc(d: !Doc, st: int, en: int, dst: &Buf >> _, omap: &Buf >> _): void
