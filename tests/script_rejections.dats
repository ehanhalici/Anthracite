#include "script_test.hats"
fun fixture(): Buf = let val b=buf_make(40) val ()=buf_set_len(b,40)
  val ()=buf_set32(b,0,SCRIPT_EXTENSIONS_MAGIC) and ()=buf_set32(b,1,PROPERTY_VERSION)
  val ()=buf_set32(b,2,1) and ()=buf_set32(b,3,2) val ()=buf_set32(b,4,769) and ()=buf_set32(b,5,770)
  val ()=buf_set32(b,6,0) and ()=buf_set32(b,7,2)
  val ()=buf_set32(b,8,1098015074) and ()=buf_set32(b,9,1281455214)
in b end
fun reject(b: Buf): int = case+ script_extensions_parse(b) of | ~ScriptExtensionsRejected(e) => 0
  | ~ScriptExtensionsAccepted(e) => let val ()=script_extensions_dispose(e) in 1 end
fun changed(word: int,value: int): int = let val b=fixture() val ()=buf_set32(b,word,value)
in reject(b) end
fun truncated{n:nat} .<n>. (left: int(n),size: int): int =
  if left = 0 then 0 else let val b=fixture() val ()=buf_set_len(b,size)
  in iadd(reject(b),truncated(left-1,iadd(size,1))) end
fun bad_script(): int = let val b=buf_make(28) val ()=buf_set_len(b,28)
  val ()=buf_set32(b,0,PROPERTY_MAGIC) and ()=buf_set32(b,1,PROPERTY_VERSION)
  val ()=buf_set32(b,2,7) and ()=buf_set32(b,3,1) val ()=buf_set32(b,5,1114111)
in case+ property_parse(b,ScriptProperty()) of | ~PropertyRejected(e) => 0
  | ~PropertyLoaded(m) => let val ()=property_dispose(m) in 1 end end
implement script_test_rejections() = truncated(40,0)+changed(0,0)+changed(1,170000)+changed(2,2147483647)
  +changed(3,2147483647)+changed(4,~1)+changed(5,1114112)+changed(6,1)+changed(7,0)
  +changed(7,3)+changed(8,1281455214)+changed(9,1098015074)+changed(9,0)+bad_script()
