#include "font/native/ownership/font_native_test.hats"
staload "data_ast/document/doc.sats"
fun bytes(s: string): Buf = let val n=c_strlen(s) val b=buf_make(n)
  fun copy{k:nat} .<k>. (left: int(k),s: string,b: !Buf,i: int): void = if left = 0 then () else let
    val ()=buf_set(b,i,c_str_byte(s,i)) in copy(left-1,s,b,iadd(i,1)) end
  val ()=copy(airlock_nat(n),s,b,0) val ()=buf_set_len(b,n)
in b end
fun valid(): int = let val d=doc_open() val b=bytes("Aİب😀Z") val ()=doc_insert_buf(d,b,buf_len(b))
  val ok=ieq(doc_codepoints(d,0,10),5) andalso ieq(doc_advance_cps(d,0,10,1),1)
    andalso ieq(doc_advance_cps(d,0,10,2),3) andalso ieq(doc_advance_cps(d,0,10,3),5)
    andalso ieq(doc_advance_cps(d,0,10,4),9) andalso ieq(doc_advance_cps(d,0,10,5),10)
  val ()=doc_set_caret_move(d,3) val space=bytes(" ") val ()=doc_insert_buf(d,space,1)
  val gap_ok=ieq(doc_codepoints(d,0,11),6) andalso ieq(doc_advance_cps(d,0,11,4),6)
    andalso ieq(doc_advance_cps(d,4,11,1),6)
  val ()=buf_free(space) val ()=buf_free(b) val ()=doc_free(d)
in if ok andalso gap_ok then 0 else 1 end
fun malformed(): int = let val d=doc_open() val b=buf_make(2)
  val ()=buf_set(b,0,226) val ()=buf_set(b,1,130) val ()=doc_insert_buf(d,b,2)
  val ok=ieq(doc_codepoints(d,0,2),1) andalso ieq(doc_advance_cps(d,0,2,1),2)
  val ()=buf_free(b) val ()=doc_free(d)
in if ok then 0 else 1 end
implement native_doc_navigation_cases() = let val before=mem_live() val errors=iadd(valid(),malformed())
  val balanced=ieq(before,mem_live()) val result=iadd(errors,if balanced then 0 else 1)
  val ()=println!("event=native_doc_navigation errors=",result," balanced=",balanced)
in result end
