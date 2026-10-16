#include "text/script/script_items_test.hats"
fun quota(data: !ScriptData,db: !UnicodeDb,bidi: !PropertyMap(2),brackets: !BidiBrackets,limit: int): int = let
  val b=script_items_test_bytes("a (ب) a") val text=script_items_test_decode(b) var remaining: int=limit
  val before=mem_live() val result=script_items_budget(data,db,bidi,text,brackets,remaining)
  val errors=case+ result of | ~ScriptItemsRejected(e) => 0
    | ~ScriptItemsAccepted(items) => let val ()=script_items_dispose(items) in 1 end
  val balanced=ieq(before,mem_live()) val ()=scalar_dispose(text) and ()=buf_free(b)
in iadd(errors,if balanced then 0 else 1) end
fun malformed(value: string): int = let val b=script_items_test_bytes(value)
  val r=script_source_range(b,0,buf_len(b)) val ()=buf_free(b)
in if r.valid then 1 else 0 end
implement script_items_test_rejections(data,db,bidi,brackets) = quota(data,db,bidi,brackets,0)
  +quota(data,db,bidi,brackets,10)+malformed("; Latin")+malformed("0000..; Latin")
  +malformed("0000.0001; Latin")+malformed("0000x; Latin")+malformed("110000; Latin")
  +malformed("0001..0000; Latin")+malformed("0Z00; Latin")
