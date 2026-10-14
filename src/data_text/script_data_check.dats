#include "data_text/script_data_internal.hats"
fun scalar(s: !PropertyMap(7),e: !ScriptExtensions,cp: int): bool = let
  val set=script_set(e,s,cp)
in if ieq(set.script.code,SCRIPT_UNKNOWN) then false
  else script_code_implicit(set.script) orelse script_set_contains(e,set,set.script) end
fun points{n:nat} .<n>. (left: int(n),s: !PropertyMap(7),e: !ScriptExtensions,cp: int): bool =
  if left = 0 then true else scalar(s,e,cp) andalso points(left-1,s,e,iadd(cp,1))
fun rows{n:nat} .<n>. (left: int(n),s: !PropertyMap(7),e: !ScriptExtensions,b: !Buf,index: int,
  remaining: int): ScriptDataStatus = if left = 0 then ScriptDataReady() else let
    val at=iadd(4,imul(index,4)) val first=buf_get32(b,at) and last=buf_get32(b,iadd(at,1))
    val size=iadd(isub(last,first),1) and width=iadd(buf_get32(b,iadd(at,3)),1)
  in if igt(size,idiv(remaining,width)) then ScriptDataCapacity()
    else if not(points(airlock_nat(size),s,e,first)) then ScriptDataInvalid()
    else rows(left-1,s,e,b,iadd(index,1),isub(remaining,imul(size,width))) end
implement script_data_check(s,e) = let val+ ScriptExtensions(b,count,total)=e
in rows(airlock_nat(count),s,e,b,0,MAX_REC_FUEL) end
