#include "script_items_test.hats"
fun tested(data: !ScriptData,db: !UnicodeDb,bidi: !PropertyMap(2),brackets: !BidiBrackets): int = let
  val cases=script_items_test_cases(data,db,bidi,brackets) and stress=script_items_test_stress(data,db,bidi,brackets)
  val rejected=script_items_test_rejections(data,db,bidi,brackets)
  val ()=println!("event=script_items cases=",cases," stress_errors=",stress," rejection_errors=",rejected)
in cases+stress+rejected end
fun with_brackets(data: !ScriptData,db: !UnicodeDb,bidi: !PropertyMap(2)): int =
  case+ bidi_brackets_load(c_argv(5)) of | ~BracketsRejected(e) => 1
  | ~BracketsLoaded(brackets) => let val errors=tested(data,db,bidi,brackets) val ()=bidi_brackets_dispose(brackets) in errors end
fun with_bidi(data: !ScriptData,db: !UnicodeDb): int = case+ property_load(c_argv(4),BidiProperty()) of
  | ~PropertyRejected(e) => 1 | ~PropertyLoaded(bidi) => let
    val errors=with_brackets(data,db,bidi) val ()=property_dispose(bidi) in errors end
fun with_db(data: !ScriptData): int = case+ unicode_load(c_argv(3)) of | ~UnicodeDataError() => 1
  | ~UnicodeLoaded(db) => let val errors=with_bidi(data,db) val ()=unicode_dispose(db) in errors end
fun run(): int = case+ script_data_load(c_argv(1),c_argv(2)) of | ~ScriptDataRejected(e) => 1
  | ~ScriptDataAccepted(data) => let val errors=with_db(data) val ()=script_data_dispose(data) in errors end
implement main0() = if ine(c_argc(),6) then exit(2) else let val before=mem_live() val errors=run()
  val balanced=ieq(before,mem_live()) val ()=println!("event=script_items_ownership buf_balanced=",balanced)
in if igt(errors,0) orelse not(balanced) then exit(1) else () end
