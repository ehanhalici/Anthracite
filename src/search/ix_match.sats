#define ATS_DYNLOADFLAG 0

staload "mem.sats"
staload "data_ast/document/doc.sats"
staload "ui_workspace/tabs/ui_tab.sats"

datatype SearchScope = ScopeVault | ScopeDoc

fun ix_match_search(q: !Buf, vault: !Buf, tabs: !Tabs, ixf: !Buf, ixs: !Buf, ixp: !Buf, ixb: !Buf,
                    hits: &Buf >> _, hmeta: &Buf >> _, hjump: &Buf >> _, hn: &int >> _,
                    nfiles_hit: &int >> _, is_partial: &int >> _): void

fun ix_doc_find(d: !Doc, q: !Buf, from_pos: int, dir: int): int
fun doc_reveal(d: !Doc, off: int): void
