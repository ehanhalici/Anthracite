#define ATS_DYNLOADFLAG 0

staload "mem.sats"
staload "data_ast/document/doc.sats"

fun kind_name(k: NodeKind): string

fun ast_dump(d: !Doc, dst: &Buf >> _): void
