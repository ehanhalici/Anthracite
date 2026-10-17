#include "data_text/script/script_items_internal.hats"
extern fun script_cluster_failed(): int = "mac#anth_die_int"
fun finish{n:nat} .<n>. (left: int(n),bounds: !Buf,index: int): int =
  if left = 0 then script_cluster_failed() else if ieq(buf_get(bounds,index),1) then index
  else finish(left-1,bounds,iadd(index,1))
fun representative{n:nat} .<n>. (left: int(n),data: !ScriptData,text: !ScalarText,index: int,saved: ScriptSet): ScriptSet =
  if left = 0 then saved else let val set=script_data_set(data,scalar_value(text,index))
    val ordinary=ieq(set.script.code,SCRIPT_COMMON) orelse ieq(set.script.code,SCRIPT_INHERITED)
  in if not(ordinary) then set else let val next=if script_items_wild(saved) andalso not(script_items_wild(set)) then set else saved
    in representative(left-1,data,text,iadd(index,1),next) end end
implement script_items_cluster(data,text,w,start) = let
  val+ ScriptItemsWorkspace(output,bounds,stack,heads,candidates,n)=w
  val endpos=finish(airlock_nat(isub(n,start)),bounds,iadd(start,1))
  val base=script_data_set(data,scalar_value(text,start))
  val set=representative(airlock_nat(isub(endpos,start)),data,text,start,base)
in @{first=start,finish=endpos,set=set} end
