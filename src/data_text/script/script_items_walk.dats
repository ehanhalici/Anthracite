#include "data_text/script/script_items_internal.hats"
extern fun script_items_exhausted(): int = "mac#anth_die_int"
fun update(w: !ScriptItemsWorkspace,cluster: ScriptCluster,state: ScriptItemsState,pair: ScriptPair,
  result: ScriptCandidate,start: int): ScriptItemsState =
  @{start=start,count=result.count,preferred=result.preferred,depth=pair.depth}
fun step(data: !ScriptData,w: !ScriptItemsWorkspace,cluster: ScriptCluster,set: ScriptSet,
  state: ScriptItemsState,pair: ScriptPair,remaining: &int >> int): ScriptItemsState = let
  val chosen=script_items_choice(w,state.count,state.preferred)
  val result=script_items_candidate(data,w,set,state,remaining)
in if not(result.valid) then @{start= ~1,count=0,preferred=chosen,depth=pair.depth}
  else if igt(result.count,0) orelse ieq(state.count,0) then update(w,cluster,state,pair,result,state.start) else let
    val ()=script_items_fill(w,state.start,cluster.first,chosen)
    val fresh=script_items_candidate(data,w,set,script_items_initial(cluster.first),remaining)
  in if fresh.valid then update(w,cluster,state,pair,fresh,cluster.first)
    else @{start= ~1,count=0,preferred=chosen,depth=pair.depth} end end
fun boundary(bidi: !PropertyMap(2),text: !ScalarText,cluster: ScriptCluster): bool =
  bidi_is_paragraph_separator(bidi_class_of(property_value(bidi,scalar_value(text,isub(cluster.finish,1)))))
fun completed(w: !ScriptItemsWorkspace,finish: int,state: ScriptItemsState): ScriptItemsState = let
  val chosen=script_items_choice(w,state.count,state.preferred)
  val ()=script_items_fill(w,state.start,finish,chosen) and ()=script_items_pair_reset(w)
in script_items_initial(finish) end
fun walk{n:nat} .<n>. (left: int(n),data: !ScriptData,bidi: !PropertyMap(2),text: !ScalarText,brackets: !BidiBrackets,
  w: !ScriptItemsWorkspace,index: int,state: ScriptItemsState,remaining: &int >> int): ScriptItemsStatus =
  if ige(index,scalar_count(text)) then let val next=completed(w,index,state) in ScriptItemsReady() end
  else if left = 0 then let val failed=script_items_exhausted() in ScriptItemsCapacity() end else let
    val cluster=script_items_cluster(data,text,w,index)
  in if not(script_items_charge(remaining,iadd(isub(cluster.finish,index),1))) then ScriptItemsCapacity() else let
    val pair=script_items_pair(brackets,w,scalar_value(text,index),index,state.depth)
    val set=script_items_pair_set(w,cluster,pair,state.start)
    val next=step(data,w,cluster,set,state,pair,remaining)
  in if ilt(next.start,0) then ScriptItemsCapacity() else let
    val final=if boundary(bidi,text,cluster) then completed(w,cluster.finish,next) else next
  in walk(left-1,data,bidi,text,brackets,w,cluster.finish,final,remaining) end end end
implement script_items_walk(data,bidi,text,brackets,w,remaining) =
  walk(airlock_nat(scalar_count(text)),data,bidi,text,brackets,w,0,script_items_initial(0),remaining)
