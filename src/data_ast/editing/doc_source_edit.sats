staload "mem.sats"
staload "data_ast/document/doc.sats"
staload "data_font/resources/font.sats"
datatype SourceEdit = SourceLeft | SourceRight | SourceSelectLeft | SourceSelectRight | SourceBackspace | SourceDelete
fun doc_source_edit(f: !Font,d: !Doc,edit: SourceEdit,scratch: &Buf >> _): bool
