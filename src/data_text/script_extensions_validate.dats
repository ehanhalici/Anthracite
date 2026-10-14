#include "data_text/script_internal.hats"
fun tags{n:nat} .<n>. (left: int(n),b: !Buf,index: int,previous: int): bool =
  if left = 0 then true else let val code=buf_get32(b,index)
  in script_code_valid(code) andalso not(script_code_implicit(@{code=code}))
    andalso igt(code,previous) andalso tags(left-1,b,iadd(index,1),code) end
fun rows{n:nat} .<n>. (left: int(n),b: !Buf,index: int,previous: int,offset: int,count: int,total: int): bool =
  if left = 0 then ieq(offset,total) else let
    val at=iadd(4,imul(index,4)) val first=buf_get32(b,at) and last=buf_get32(b,iadd(at,1))
    val start=buf_get32(b,iadd(at,2)) and size=buf_get32(b,iadd(at,3))
    val valid=igt(first,previous) andalso ige(last,first) andalso ilt(last,UNICODE_SCALAR_LIMIT)
      andalso ieq(start,offset) andalso igt(size,0) andalso ile(size,isub(total,offset))
  in if not(valid) then false else tags(airlock_nat(size),b,iadd(iadd(4,imul(count,4)),start),0)
    andalso rows(left-1,b,iadd(index,1),last,iadd(offset,size),count,total) end
implement script_extensions_valid(b,count,total) =
  rows(airlock_nat(count),b,0,~1,0,count,total)
