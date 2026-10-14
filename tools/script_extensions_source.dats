#include "script_compile_internal.hats"
extern fun script_source_failed(): int = "mac#anth_die_int"
fun tags{n:nat} .<n>. (left: int(n),aliases: !ScriptAliases,b: !Buf,output: &Buf >> Buf,
  p: int,en: int,row: int,total: int): int = let val at=text_skip_space(b,p,en)
in if ige(at,en) orelse ieq(buf_get(b,at),35) then total else if left = 0 then script_source_failed()
  else if ige(total,idiv(MAX_REC_FUEL,8)) then ~1 else let
  val code=script_source_tag(b,at,en) val finish=iadd(at,4)
  val boundary=ige(finish,en) orelse ieq(buf_get(b,finish),32) orelse ieq(buf_get(b,finish),9) orelse ieq(buf_get(b,finish),35)
in if not(boundary) orelse not(script_aliases_contains(aliases,code)) then ~1 else let
  val ()=buf_ensure(output,imul(iadd(total,1),8))
  val ()=buf_set32(output,imul(total,2),row) and ()=buf_set32(output,iadd(imul(total,2),1),code)
in tags(left-1,aliases,b,output,finish,en,row,iadd(total,1)) end end end
fun append(rows: &Buf >> Buf,r: ScriptSourceRange,count: int,first: int,total: int): void = let
  val at=imul(count,4) val ()=buf_ensure(rows,imul(iadd(count,1),16))
  val ()=buf_set32(rows,at,r.first) and ()=buf_set32(rows,iadd(at,1),r.last)
  val ()=buf_set32(rows,iadd(at,2),first)
in buf_set32(rows,iadd(at,3),isub(total,first)) end
fun row(aliases: !ScriptAliases,b: !Buf,rows: &Buf >> Buf,output: &Buf >> Buf,
  p: int,en: int,count: int,total: int): ScriptSourceCounts =
  if ige(p,en) orelse ieq(buf_get(b,p),35) then @{valid=true,rows=count,total=total} else let
    val r=script_source_range(b,p,en)
    val valid=r.valid andalso ilt(count,idiv(MAX_REC_FUEL,16))
  in if not(valid) then @{valid=false,rows=count,total=total} else let
    val finish=tags(airlock_nat(isub(en,r.field)),aliases,b,output,r.field,en,r.first,total)
    val ok=igt(finish,total)
    val ()=if ok then append(rows,r,count,total,finish) else ()
  in @{valid=ok,rows=if ok then iadd(count,1) else count,total=finish} end end
fun lines{n:nat} .<n>. (left: int(n),aliases: !ScriptAliases,b: !Buf,rows: &Buf >> Buf,output: &Buf >> Buf,
  p: int,en: int,count: int,total: int): ScriptSourceCounts =
  if ige(p,en) then @{valid=true,rows=count,total=total} else if left = 0 then let val failed=script_source_failed() in @{valid=false,rows=failed,total=total} end else let
    val finish=text_line_end(b,p,en) val start=text_skip_space(b,p,finish)
    val result=row(aliases,b,rows,output,start,finish,count,total)
  in if not(result.valid) then result else let val next=iadd(finish,1)
    in lines(left-1,aliases,b,rows,output,next,en,result.rows,result.total) end end
implement script_extensions_source(aliases,b,rows,tags) =
  lines(airlock_nat(buf_len(b)),aliases,b,rows,tags,0,buf_len(b),0,0)
