#include "data_text/script_items_internal.hats"
fun finish(w: ScriptItemsWorkspace,status: ScriptItemsStatus): ScriptItemsRead = let
  val+ ~ScriptItemsWorkspace(output,bounds,stack,heads,candidates,n)=w
  val ()=buf_free(bounds) and ()=buf_free(stack) and ()=buf_free(heads) and ()=buf_free(candidates)
in case+ status of | ScriptItemsReady() => ScriptItemsAccepted(ScriptItems(output,n))
  | ScriptItemsCapacity() => let val ()=buf_free(output) in ScriptItemsRejected(status) end end
fun allocated(data: !ScriptData,db: !UnicodeDb,bidi: !PropertyMap(2),text: !ScalarText,
  brackets: !BidiBrackets,remaining: &int >> int): ScriptItemsRead = let val count=scalar_count(text)
  val+ BidiBrackets(rows,total)=brackets val capacity=script_data_capacity(data)
  val w=ScriptItemsWorkspace(buf_make(imul(count,4)),grapheme_boundaries(db,text),
    buf_make(imul(count,12)),buf_make(imul(total,4)),buf_make(imul(capacity,4)),count)
  val ()=script_items_pair_reset(w)
  val status=script_items_walk(data,bidi,text,brackets,w,remaining)
in finish(w,status) end
fun checked(data: !ScriptData,db: !UnicodeDb,bidi: !PropertyMap(2),text: !ScalarText,
  brackets: !BidiBrackets,remaining: &int >> int): ScriptItemsRead = let
  val count=scalar_count(text) val capacity=script_data_capacity(data)
  val+ BidiBrackets(rows,total)=brackets
  val fixed=iadd(iadd(1,imul(total,4)),imul(capacity,4))
in if igt(fixed,MAX_REC_FUEL) orelse igt(count,idiv(isub(MAX_REC_FUEL,fixed),17))
  then ScriptItemsRejected(ScriptItemsCapacity()) else allocated(data,db,bidi,text,brackets,remaining) end
implement script_items_budget(data,db,bidi,text,brackets,remaining) = let
  val capacity=script_data_capacity(data) val+ BidiBrackets(rows,total)=brackets
in if igt(capacity,idiv(MAX_REC_FUEL,4)) orelse igt(total,idiv(MAX_REC_FUEL,4))
  then ScriptItemsRejected(ScriptItemsCapacity()) else checked(data,db,bidi,text,brackets,remaining) end
implement script_items_make(data,db,bidi,text,brackets) = let var remaining: int=MAX_REC_FUEL
in script_items_budget(data,db,bidi,text,brackets,remaining) end
