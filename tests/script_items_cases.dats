#include "script_items_test.hats"
fun compare{n:nat} .<n>. (left: int(n),items: !ScriptItems,expected: !Buf,index: int,errors: int): int =
  if left = 0 then errors else let val actual=script_items_code(items,index)
    val code=script_source_tag(expected,imul(index,5),buf_len(expected))
  in compare(left-1,items,expected,iadd(index,1),iadd(errors,if ieq(actual.code,code) then 0 else 1)) end
fun checked(items: ScriptItems,expected: string): int = let val b=script_items_test_bytes(expected)
  val count=idiv(iadd(buf_len(b),1),5)
  val errors=if ieq(script_items_count(items),count) then compare(airlock_nat(count),items,b,0,0) else 1
  val ()=script_items_dispose(items) and ()=buf_free(b)
in errors end
fun consumed(result: ScriptItemsRead,expected: string): int = case+ result of
  | ~ScriptItemsRejected(e) => 1 | ~ScriptItemsAccepted(items) => checked(items,expected)
fun test(data: !ScriptData,db: !UnicodeDb,bidi: !PropertyMap(2),brackets: !BidiBrackets,value: string,expected: string): int = let
  val b=script_items_test_bytes(value) val text=script_items_test_decode(b)
  val result=script_items_make(data,db,bidi,text,brackets)
  val ()=scalar_dispose(text) and ()=buf_free(b)
  val errors=consumed(result,expected)
  val ()=if ieq(errors,0) then () else println!("event=script_item_case text=",value," errors=",errors)
in errors end
implement script_items_test_cases(data,db,bidi,brackets) =
  test(data,db,bidi,brackets,"aب","Latn Arab")
  +test(data,db,bidi,brackets,"işğüöç أَب","Latn Latn Latn Latn Latn Latn Latn Arab Arab Arab")
  +test(data,db,bidi,brackets,"aְ","Latn Latn")+test(data,db,bidi,brackets,"◌ְ","Hebr Hebr")
  +test(data,db,bidi,brackets,"  ب","Arab Arab Arab")+test(data,db,bidi,brackets,"ب،a","Arab Arab Latn")
  +test(data,db,bidi,brackets,"a،ب","Latn Arab Arab")+test(data,db,bidi,brackets,"aーア","Latn Kana Kana")
  +test(data,db,bidi,brackets,"a (ب) a","Latn Latn Latn Arab Latn Latn Latn")
  +test(data,db,bidi,brackets,"a (ب[γ]) a","Latn Latn Latn Arab Arab Grek Arab Latn Latn Latn")
  +test(data,db,bidi,brackets,"([a)γ]","Latn Latn Latn Latn Grek Grek")
  +test(data,db,bidi,brackets,"ب\n  a","Arab Arab Latn Latn Latn")
  +test(data,db,bidi,brackets,"ب(\n)a","Arab Arab Arab Latn Latn")
  +test(data,db,bidi,brackets,"a","Zzzz Latn")
  +test(data,db,bidi,brackets,"a‍ب","Latn Latn Arab")
  +test(data,db,bidi,brackets,"","")
