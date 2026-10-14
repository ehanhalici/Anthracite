#include "script_compile_internal.hats"
fun assign{n:nat} .<n>. (left: int(n),dense: !Buf,cp: int,code: int): void =
  if left = 0 then () else let val ()=buf_set32(dense,cp,code) in assign(left-1,dense,iadd(cp,1),code) end
fun row(aliases: !ScriptAliases,b: !Buf,dense: !Buf,p: int,en: int): bool =
  if ige(p,en) orelse ieq(buf_get(b,p),35) then true else let
    val r=script_source_range(b,p,en) val code=script_aliases_find(aliases,b,r.field,en)
    val valid=r.valid andalso igt(code,0)
  in if not(valid) then false else let
    val ()=assign(airlock_nat(iadd(isub(r.last,r.first),1)),dense,r.first,code)
  in true end end
fun lines{n:nat} .<n>. (left: int(n),aliases: !ScriptAliases,b: !Buf,dense: !Buf,p: int,en: int): bool =
  if ige(p,en) then true else if left = 0 then false else let val finish=text_line_end(b,p,en)
    val ok=row(aliases,b,dense,text_skip_space(b,p,finish),finish)
  in ok andalso lines(left-1,aliases,b,dense,iadd(finish,1),en) end
implement script_source_compile(aliases,path,output) = case+ text_file_read(path) of
  | ~TextFileError(code) => false | ~TextFile(b) => let
    val dense=buf_make(imul(UNICODE_SCALAR_LIMIT,4))
    val ()=assign(1114112,dense,0,SCRIPT_UNKNOWN)
    val valid=lines(airlock_nat(buf_len(b)),aliases,b,dense,0,buf_len(b))
    val written=valid andalso property_write(ScriptProperty(),dense,output)
    val ()=buf_free(b) and ()=buf_free(dense)
  in written end
