#include "script_items_test.hats"
fun append{n:nat} .<n>. (left: int(n),b: &Buf >> Buf,byte: int): void =
  if left = 0 then () else let val ()=buf_push(b,byte) in append(left-1,b,byte) end
fun rows{n:nat} .<n>. (left: int(n),items: !ScriptItems,index: int,code: int,errors: int): int =
  if left = 0 then errors else let val actual=script_items_code(items,index)
  in rows(left-1,items,iadd(index,1),code,iadd(errors,if ieq(actual.code,code) then 0 else 1)) end
fun nested(data: !ScriptData,db: !UnicodeDb,bidi: !PropertyMap(2),brackets: !BidiBrackets): int = let
  var b: Buf=buf_make(65540) val ()=append(32768,b,40)
  val ()=buf_push(b,216) and ()=buf_push(b,168) val ()=append(32768,b,41) val ()=buf_push(b,97)
  val text=script_items_test_decode(b) val result=script_items_make(data,db,bidi,text,brackets)
  val ()=scalar_dispose(text) and ()=buf_free(b)
in case+ result of | ~ScriptItemsRejected(e) => 1 | ~ScriptItemsAccepted(items) => let
  val errors=rows(65537,items,0,1098015074,0) val last=script_items_code(items,65537)
  val ok=ieq(last.code,1281455214) andalso ieq(script_items_count(items),65538) val ()=script_items_dispose(items)
in iadd(errors,if ok then 0 else 1) end end
fun unmatched(data: !ScriptData,db: !UnicodeDb,bidi: !PropertyMap(2),brackets: !BidiBrackets): int = let
  var b: Buf=buf_make(65540) val ()=append(32768,b,40) val ()=append(32768,b,93) val ()=buf_push(b,97)
  val text=script_items_test_decode(b) val result=script_items_make(data,db,bidi,text,brackets)
  val ()=scalar_dispose(text) and ()=buf_free(b)
in case+ result of | ~ScriptItemsRejected(e) => 1 | ~ScriptItemsAccepted(items) => let
  val errors=rows(65537,items,0,1281455214,0) val ()=script_items_dispose(items)
in errors end end
implement script_items_test_stress(data,db,bidi,brackets) = nested(data,db,bidi,brackets)+unmatched(data,db,bidi,brackets)
