#include "data_text/script_items_internal.hats"
extern fun script_pair_failed(): int = "mac#anth_die_int"
fun clear{n:nat} .<n>. (left: int(n),heads: !Buf,index: int): void =
  if left = 0 then () else let val ()=buf_set32(heads,index,~1) in clear(left-1,heads,iadd(index,1)) end
implement script_items_pair_reset(w) = let val+ ScriptItemsWorkspace(output,bounds,stack,heads,candidates,n)=w
in clear(airlock_nat(idiv(buf_cap(heads),4)),heads,0) end
fun push(w: !ScriptItemsWorkspace,slot: int,index: int,depth: int): ScriptPair = let
  val+ ScriptItemsWorkspace(output,bounds,stack,heads,candidates,n)=w val at=imul(depth,3)
  val previous=buf_get32(heads,slot)
  val ()=buf_set32(stack,at,slot) and ()=buf_set32(stack,iadd(at,1),index)
  val ()=buf_set32(stack,iadd(at,2),previous) and ()=buf_set32(heads,slot,depth)
in @{opening= ~1,depth=iadd(depth,1)} end
fun pop{n:nat} .<n>. (left: int(n),stack: !Buf,heads: !Buf,index: int): void =
  if left = 0 then () else let val at=imul(index,3)
    val ()=buf_set32(heads,buf_get32(stack,at),buf_get32(stack,iadd(at,2)))
  in pop(left-1,stack,heads,isub(index,1)) end
fun close(w: !ScriptItemsWorkspace,slot: int,depth: int): ScriptPair = let
  val+ ScriptItemsWorkspace(output,bounds,stack,heads,candidates,n)=w val matched=buf_get32(heads,slot)
in if ilt(matched,0) then @{opening= ~1,depth=depth} else let
  val opening=buf_get32(stack,iadd(imul(matched,3),1))
  val ()=pop(airlock_nat(isub(depth,matched)),stack,heads,isub(depth,1))
in @{opening=opening,depth=matched} end end
implement script_items_pair(brackets,w,cp,index,depth) = let val info=bidi_bracket_info(brackets,cp)
in case+ info.kind of | NoBracket() => @{opening= ~1,depth=depth}
  | OpenBracket() => let val slot=bidi_bracket_index(brackets,bidi_bracket_canonical(info.paired))
    in if ilt(slot,0) then @{opening=script_pair_failed(),depth=depth} else push(w,slot,index,depth) end
  | CloseBracket() => let val slot=bidi_bracket_index(brackets,bidi_bracket_canonical(cp))
    in if ilt(slot,0) then @{opening=script_pair_failed(),depth=depth} else close(w,slot,depth) end end
implement script_items_pair_set(w,cluster,pair,start) = let val+ ScriptItemsWorkspace(output,bounds,stack,heads,candidates,n)=w
in if ilt(pair.opening,0) orelse ige(pair.opening,start) then cluster.set else
  @{kind=ScriptSingleton(),script= @{code=buf_get32(output,pair.opening)},offset=0,count=1} end
