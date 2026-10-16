#define ATS_DYNLOADFLAG 0

staload "mem.sats"
staload "data_ast/document/doc.sats"

fun ix_extract_doc(d: !Doc, fid: int, ixs: &Buf >> _, ixp: &Buf >> _, ixb: !Buf): void
fun ix_walk_vault(vault: !Buf, ixf: &Buf >> _, ixp: &Buf >> _, trunc: &int >> _): void
fun ix_index_file(path: string, fid: int, ixs: &Buf >> _, ixp: &Buf >> _, ixb: !Buf): void
fun ix_step_all(vault: !Buf, ixf: &Buf >> _, ixs: &Buf >> _, ixp: &Buf >> _, ixb: &Buf >> _, budget_ns: lint): int
