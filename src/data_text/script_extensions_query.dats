#include "data_text/script_internal.hats"
extern fun script_search_failed(): int = "mac#anth_die_int"
fun search{n:nat} .<n>. (left: int(n),b: !Buf,cp: int,low: int,high: int): int =
  if ige(low,high) then ~1 else if left = 0 then script_search_failed() else let
    val middle=iadd(low,idiv(isub(high,low),2)) val at=iadd(4,imul(middle,4))
  in if ilt(cp,buf_get32(b,at)) then search(left-1,b,cp,low,middle)
    else if igt(cp,buf_get32(b,iadd(at,1))) then search(left-1,b,cp,iadd(middle,1),high) else middle end
implement script_extensions_index(b,count,cp) = search(airlock_nat(iadd(count,1)),b,cp,0,count)
implement script_set(extensions,scripts,cp) = let
  val+ ScriptExtensions(b,count,total)=extensions val index=script_extensions_index(b,count,cp)
  val code= @{code=property_value(scripts,cp)}
in if ilt(index,0) then @{kind=ScriptSingleton(),script=code,offset=0,count=1}
  else let val at=iadd(4,imul(index,4))
    in @{kind=ScriptExplicitSet(),script=code,offset=buf_get32(b,iadd(at,2)),count=buf_get32(b,iadd(at,3))} end end
implement script_set_at(extensions,set,index) = let val+ ScriptExtensions(b,count,total)=extensions
in if ilt(index,0) orelse ige(index,set.count) then @{code=0} else case+ set.kind of
  | ScriptSingleton() => set.script
  | ScriptExplicitSet() => if ilt(set.offset,0) orelse igt(set.count,isub(total,set.offset)) then @{code=0}
    else @{code=buf_get32(b,iadd(iadd(4,imul(count,4)),iadd(set.offset,index)))} end
fun contains{n:nat} .<n>. (left: int(n),extensions: !ScriptExtensions,set: ScriptSet,code: ScriptCode,index: int): bool =
  if left = 0 then false else let val candidate=script_set_at(extensions,set,index)
  in ieq(candidate.code,code.code) orelse contains(left-1,extensions,set,code,iadd(index,1)) end
implement script_set_contains(extensions,set,code) = contains(airlock_nat(set.count),extensions,set,code,0)
