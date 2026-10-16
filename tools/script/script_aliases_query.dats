#include "script_compile_internal.hats"
fun delimiter(c: int): bool = ieq(c,32) orelse ieq(c,9) orelse ieq(c,13) orelse ieq(c,35) orelse ieq(c,59)
fun token_end{n:nat} .<n>. (left: int(n),b: !Buf,p: int): int =
  if left = 0 then p else if delimiter(buf_get(b,p)) then p else token_end(left-1,b,iadd(p,1))
fun equal{n:nat} .<n>. (left: int(n),a: !Buf,b: !Buf,i: int,j: int): bool =
  if left = 0 then true else ieq(buf_get(a,i),buf_get(b,j)) andalso equal(left-1,a,b,iadd(i,1),iadd(j,1))
fun find{n:nat} .<n>. (left: int(n),source: !Buf,rows: !Buf,b: !Buf,p: int,size: int,index: int): int =
  if left = 0 then ~1 else let val at=imul(index,3)
    val name=buf_get32(rows,iadd(at,1)) and en=buf_get32(rows,iadd(at,2))
    val length=isub(token_end(airlock_nat(isub(en,name)),source,name),name)
  in if ieq(length,size) andalso equal(airlock_nat(size),source,b,name,p) then buf_get32(rows,at)
    else find(left-1,source,rows,b,p,size,iadd(index,1)) end
implement script_aliases_find(aliases,b,p,en) = let val+ ScriptAliases(source,rows,count)=aliases
  val size=isub(token_end(airlock_nat(isub(en,p)),b,p),p)
in find(airlock_nat(count),source,rows,b,p,size,0) end
fun contains{n:nat} .<n>. (left: int(n),rows: !Buf,code: int,index: int): bool =
  if left = 0 then false else ieq(buf_get32(rows,imul(index,3)),code) orelse contains(left-1,rows,code,iadd(index,1))
implement script_aliases_contains(aliases,code) = let val+ ScriptAliases(source,rows,count)=aliases
in contains(airlock_nat(count),rows,code,0) end
