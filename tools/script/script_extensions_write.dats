#include "script_compile_internal.hats"
fun offsets{n:nat} .<n>. (left: int(n),rows: !Buf,index: int,total: int): int =
  if left = 0 then total else let val at=imul(index,4) val size=buf_get32(rows,iadd(at,3))
    val ()=buf_set32(rows,iadd(at,2),total)
  in offsets(left-1,rows,iadd(index,1),iadd(total,size)) end
fun emit_tags{n:nat} .<n>. (left: int(n),tags: !Buf,output: !Buf,from: int,to: int): void =
  if left = 0 then () else let val ()=buf_set32(output,to,buf_get32(tags,iadd(imul(from,2),1)))
  in emit_tags(left-1,tags,output,iadd(from,1),iadd(to,1)) end
fun assembled(rows: !Buf,tags: !Buf,count: int,total: int): Buf = let
  val bytes=iadd(16,iadd(imul(count,16),imul(total,4))) var output: Buf=buf_make(bytes)
  val ()=buf_set32(output,0,SCRIPT_EXTENSIONS_MAGIC) and ()=buf_set32(output,1,PROPERTY_VERSION)
  val ()=buf_set32(output,2,count) and ()=buf_set32(output,3,total) val ()=buf_set_len(output,16)
  val ()=buf_append_at(output,rows,0,imul(count,16))
  val ()=emit_tags(airlock_nat(total),tags,output,0,iadd(4,imul(count,4)))
  val ()=buf_set_len(output,bytes)
in output end
fun write(rows: !Buf,tags: !Buf,count: int,total: int,path: string): bool = let
  val ()=word_rows_sort(tags,total,2,1) and ()=word_rows_sort(tags,total,2,0)
  val ()=unicode_rows_sort(rows,count,4,0)
  val expected=offsets(airlock_nat(count),rows,0,0)
  val b=assembled(rows,tags,count,total)
in case+ script_extensions_parse(b) of | ~ScriptExtensionsRejected(e) => false
  | ~ScriptExtensionsAccepted(extensions) => let val+ ScriptExtensions(b,count,total)=extensions
    val written=if ieq(expected,total) then fs_write_buf(path,b,buf_len(b)) else 0
    val ()=script_extensions_dispose(extensions)
  in ieq(written,1) end end
implement script_extensions_write(rows,tags,count,total,path) =
  if igt(iadd(16,iadd(imul(count,16),imul(total,4))),MAX_REC_FUEL) then false else write(rows,tags,count,total,path)
