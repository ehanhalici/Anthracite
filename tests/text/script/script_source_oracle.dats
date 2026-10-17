#include "text/script/script_test.hats"
fun points{n:nat} .<n>. (left: int(n),s: !PropertyMap(7),cp: int,code: int,errors: int): int =
  if left = 0 then errors else points(left-1,s,iadd(cp,1),code,iadd(errors,if ieq(property_value(s,cp),code) then 0 else 1))
fun row(a: !ScriptAliases,s: !PropertyMap(7),b: !Buf,p: int,en: int,c: ScriptTestCounts): ScriptTestCounts =
  if ige(p,en) orelse ieq(buf_get(b,p),35) then c else let
    val r=script_source_range(b,p,en) val code=script_aliases_find(a,b,r.field,en) val size=iadd(isub(r.last,r.first),1)
    val errors=points(airlock_nat(size),s,r.first,code,c.errors)
  in @{errors=errors,rows=iadd(c.rows,1),points=iadd(c.points,size)} end
fun lines{n:nat} .<n>. (left: int(n),a: !ScriptAliases,s: !PropertyMap(7),b: !Buf,p: int,en: int,c: ScriptTestCounts): ScriptTestCounts =
  if ige(p,en) then c else if left = 0 then @{errors=iadd(c.errors,1),rows=c.rows,points=c.points} else let
    val finish=text_line_end(b,p,en) val next=row(a,s,b,text_skip_space(b,p,finish),finish,c)
  in lines(left-1,a,s,b,iadd(finish,1),en,next) end
implement script_test_scripts(a,s,path) = case+ text_file_read(path) of
  | ~TextFileError(code) => @{errors=1,rows=0,points=0} | ~TextFile(b) => let
    val result=lines(airlock_nat(buf_len(b)),a,s,b,0,buf_len(b),@{errors=0,rows=0,points=0})
    val ()=buf_free(b)
  in result end
