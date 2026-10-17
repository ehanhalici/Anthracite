#define ATS_DYNLOADFLAG 0

staload "mem.sats"
staload "data_ast/document/doc.sats"

fun line_end(d: !Doc, ls: int): int
fun line_next(d: !Doc, ls: int): int
fun indent_cols(d: !Doc, p: int, le: int, cols: &int >> _, next_p: &int >> _): void
fun is_blank(d: !Doc, p: int, le: int): bool

fun blk_parse_until(
  d: !Doc, from: int, resync: !Buf, nres: int, delta: int, minpos: int, stk: &Buf >> _,
  matched_old: &int >> _
): int

fun ast_parse_all(d: !Doc): void

fun ast_reparse_v2(
  d: !Doc, at: int, oldlen: int, newlen: int
): void
