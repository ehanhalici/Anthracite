#include "data_text/script/script_items_internal.hats"
fun member{n:nat} .<n>. (left: int(n),b: !Buf,index: int,code: int): bool =
  if left = 0 then false else ieq(buf_get32(b,index),code) orelse member(left-1,b,iadd(index,1),code)
implement script_items_choice(w,count,preferred) = let val+ ScriptItemsWorkspace(output,bounds,stack,heads,b,n)=w
in if ieq(count,0) then @{code=SCRIPT_COMMON} else if member(airlock_nat(count),b,0,preferred.code) then preferred
  else @{code=buf_get32(b,0)} end
fun copy{n:nat} .<n>. (left: int(n),data: !ScriptData,b: !Buf,set: ScriptSet,index: int): void =
  if left = 0 then () else let val code=script_data_at(data,set,index) val ()=buf_set32(b,index,code.code)
  in copy(left-1,data,b,set,iadd(index,1)) end
fun filter{n:nat} .<n>. (left: int(n),data: !ScriptData,b: !Buf,set: ScriptSet,index: int,out: int): int =
  if left = 0 then out else let val code= @{code=buf_get32(b,index)} val keep=script_data_contains(data,set,code)
    val ()=if keep then buf_set32(b,out,code.code) else ()
  in filter(left-1,data,b,set,iadd(index,1),iadd(out,if keep then 1 else 0)) end
fun started(data: !ScriptData,w: !ScriptItemsWorkspace,set: ScriptSet,remaining: &int >> int): ScriptCandidate = let
  val+ ScriptItemsWorkspace(output,bounds,stack,heads,b,n)=w
in if not(script_items_charge(remaining,imul(set.count,2))) then @{count=0,preferred=set.script,valid=false} else let
  val ()=copy(airlock_nat(set.count),data,b,set,0)
  val preferred=script_items_choice(w,set.count,set.script)
in @{count=set.count,preferred=preferred,valid=true} end end
fun narrowed(data: !ScriptData,w: !ScriptItemsWorkspace,set: ScriptSet,state: ScriptItemsState,
  remaining: &int >> int): ScriptCandidate = let val+ ScriptItemsWorkspace(output,bounds,stack,heads,b,n)=w
  val width=iadd(set.count,2)
in if igt(state.count,idiv(remaining,width)) then @{count=state.count,preferred=state.preferred,valid=false} else let
  val ()=remaining := isub(remaining,imul(state.count,width))
  val count=filter(airlock_nat(state.count),data,b,set,0,0)
  val preferred=script_items_choice(w,count,state.preferred)
in @{count=count,preferred=preferred,valid=true} end end
implement script_items_candidate(data,w,set,state,remaining) =
  if script_items_wild(set) then @{count=state.count,preferred=state.preferred,valid=true}
  else if ieq(state.count,0) then started(data,w,set,remaining) else narrowed(data,w,set,state,remaining)
