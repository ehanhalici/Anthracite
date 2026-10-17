#include "text/script/script_test.hats"
fun expected{n:nat} .<n>. (left: int(n),b: !Buf,tags: &Buf >> Buf,p: int,en: int,count: int): int = let
  val at=text_skip_space(b,p,en)
in if ige(at,en) orelse ieq(buf_get(b,at),35) then count else if left = 0 then ~1 else let
  val code=script_source_tag(b,at,en) val ()=buf_ensure(tags,imul(iadd(count,1),4))
  val ()=buf_set32(tags,count,code) val next=iadd(at,4)
in expected(left-1,b,tags,next,en,iadd(count,1)) end end
fun members{n:nat} .<n>. (left: int(n),e: !ScriptExtensions,set: ScriptSet,tags: !Buf,index: int): bool =
  if left = 0 then true else script_set_contains(e,set,@{code=buf_get32(tags,index)})
    andalso members(left-1,e,set,tags,iadd(index,1))
fun points{n:nat} .<n>. (left: int(n),s: !PropertyMap(7),e: !ScriptExtensions,tags: !Buf,cp: int,count: int,errors: int): int =
  if left = 0 then errors else let val set=script_set(e,s,cp)
    val ok=ieq(set.count,count) andalso members(airlock_nat(count),e,set,tags,0)
  in points(left-1,s,e,tags,iadd(cp,1),count,iadd(errors,if ok then 0 else 1)) end
fun row(s: !PropertyMap(7),e: !ScriptExtensions,b: !Buf,tags: &Buf >> Buf,p: int,en: int,c: ScriptTestCounts): ScriptTestCounts =
  if ige(p,en) orelse ieq(buf_get(b,p),35) then c else let val r=script_source_range(b,p,en)
    val count=expected(airlock_nat(isub(en,r.field)),b,tags,r.field,en,0) val size=iadd(isub(r.last,r.first),1)
    val errors=points(airlock_nat(size),s,e,tags,r.first,count,c.errors)
  in @{errors=errors,rows=iadd(c.rows,1),points=iadd(c.points,size)} end
fun lines{n:nat} .<n>. (left: int(n),s: !PropertyMap(7),e: !ScriptExtensions,b: !Buf,tags: &Buf >> Buf,
  p: int,en: int,c: ScriptTestCounts): ScriptTestCounts =
  if ige(p,en) then c else if left = 0 then @{errors=iadd(c.errors,1),rows=c.rows,points=c.points} else let
    val finish=text_line_end(b,p,en) val start=text_skip_space(b,p,finish) val next=row(s,e,b,tags,start,finish,c)
    val nextp=iadd(finish,1)
  in lines(left-1,s,e,b,tags,nextp,en,next) end
implement script_test_extensions(s,e,path) = case+ text_file_read(path) of
  | ~TextFileError(code) => @{errors=1,rows=0,points=0} | ~TextFile(b) => let var tags: Buf=buf_make(128)
    val result=lines(airlock_nat(buf_len(b)),s,e,b,tags,0,buf_len(b),@{errors=0,rows=0,points=0})
    val ()=buf_free(b) and ()=buf_free(tags)
  in result end
