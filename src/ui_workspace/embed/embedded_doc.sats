staload "data_ast/document/doc.sats"
staload "os/fs.sats"
typedef EmbedSourceStamp = @{file=FileStamp,shadow=bool}
fun embedded_source_stamp(path: string): EmbedSourceStamp
fun embedded_source_equal(a: EmbedSourceStamp,b: EmbedSourceStamp): bool

fun embedded_doc_load(d: !Doc, path: string, level: int): bool
