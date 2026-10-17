#include "data_text/script/script_items_internal.hats"
implement script_items_charge(remaining,cost) =
  if ilt(cost,0) orelse ilt(remaining,cost) then false else let val ()=remaining := isub(remaining,cost) in true end
implement script_items_wild(set) = case+ set.kind of | ScriptExplicitSet() => false
  | ScriptSingleton() => ieq(set.script.code,SCRIPT_COMMON) orelse ieq(set.script.code,SCRIPT_INHERITED)
implement script_items_initial(start) = @{start=start,count=0,preferred= @{code=SCRIPT_COMMON},depth=0}
fun fill{n:nat} .<n>. (left: int(n),output: !Buf,index: int,code: int): void =
  if left = 0 then () else let val ()=buf_set32(output,index,code) in fill(left-1,output,iadd(index,1),code) end
implement script_items_fill(w,start,finish,code) = let val+ ScriptItemsWorkspace(output,bounds,stack,heads,candidates,n)=w
in fill(airlock_nat(isub(finish,start)),output,start,code.code) end
implement script_items_count(items) = let val+ ScriptItems(b,n)=items in n end
implement script_items_code(items,index) = let val+ ScriptItems(b,n)=items
in if ilt(index,0) orelse ige(index,n) then @{code=0} else @{code=buf_get32(b,index)} end
implement script_items_dispose(items) = let val+ ~ScriptItems(b,n)=items in buf_free(b) end
