#include "script_compile_internal.hats"
fun append(b: !Buf,rows: &Buf >> Buf,p: int,en: int,count: int): int =
  if not(text_token_is(b,p,en,"sc")) then count else let
    val short=text_skip_space(b,iadd(text_find_byte(b,p,en,59),1),en)
    val name=text_skip_space(b,iadd(text_find_byte(b,short,en,59),1),en)
    val code=script_source_tag(b,short,en)
    val ()=buf_ensure(rows,imul(iadd(count,1),12))
    val ()=buf_set32(rows,imul(count,3),code)
    val ()=buf_set32(rows,iadd(imul(count,3),1),name)
    val ()=buf_set32(rows,iadd(imul(count,3),2),en)
  in if ilt(code,0) then ~1 else iadd(count,1) end
fun lines{n:nat} .<n>. (left: int(n),b: !Buf,rows: &Buf >> Buf,p: int,en: int,count: int): int =
  if ige(p,en) then count else if left = 0 then ~1 else let
    val finish=text_line_end(b,p,en) val next=append(b,rows,text_skip_space(b,p,finish),finish,count)
  in if ilt(next,0) then ~1 else let val nextp=iadd(finish,1)
    in lines(left-1,b,rows,nextp,en,next) end end
fun finish(b: Buf,rows: Buf,count: int): Option_vt(ScriptAliases) =
  if ile(count,0) then let val ()=buf_free(b) and ()=buf_free(rows) in None_vt() end
  else Some_vt(ScriptAliases(b,rows,count))
implement script_aliases_read(path) = case+ text_file_read(path) of | ~TextFileError(code) => None_vt()
  | ~TextFile(b) => let var rows: Buf=buf_make(1024)
    val count=lines(airlock_nat(buf_len(b)),b,rows,0,buf_len(b),0)
  in finish(b,rows,count) end
implement script_aliases_dispose(aliases) = let val+ ~ScriptAliases(b,rows,count)=aliases
in buf_free(b); buf_free(rows) end
