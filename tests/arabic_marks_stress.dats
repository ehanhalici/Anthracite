#include "arabic_marks_test.hats"
fun fill{n:nat} .<n>. (left: int(n),values: !Buf,starts: !Buf,ends: !Buf,index: int,total: int): void =
  if left = 0 then () else let
    val cp=if ieq(index,0) then 1576 else if ieq(index,1) then 1614 else if ieq(index,isub(total,1)) then 1617 else 1620
    val ()=buf_set32(values,index,cp) and ()=buf_set32(starts,index,imul(index,4)) and ()=buf_set32(ends,index,imul(iadd(index,1),4))
  in fill(left-1,values,starts,ends,iadd(index,1),total) end
fun source(): ScalarText = let val count=32771 val values=buf_make(imul(count,4))
  val starts=buf_make(imul(count,4)) and ends=buf_make(imul(count,4))
  val ()=fill(airlock_nat(count),values,starts,ends,0,count)
in ScalarText(values,starts,ends,count,0) end
fun check{n:nat} .<n>. (left: int(n),text: !ScalarText,index: int): int =
  if left = 0 then 0 else let
    val cp=if ieq(index,0) then 1576 else if ieq(index,32769) then 1617 else if ieq(index,32770) then 1614 else 1620
    val original=if ieq(index,0) then 0 else if ieq(index,32769) then 32770 else if ieq(index,32770) then 1 else iadd(index,1)
    val ok=ieq(scalar_value(text,index),cp) andalso ieq(scalar_start(text,index),imul(original,4))
  in iadd(if ok then 0 else 1,check(left-1,text,iadd(index,1))) end
implement marks_test_stress(data,mcm) = let val before=mem_live() val text=source()
  val errors=case+ arabic_marks_apply(data,mcm,text) of | ~ArabicMarksRejected(e) => 1
    | ~ArabicMarksReady(result) => let val errors=check(32771,result,0)
      val ()=scalar_dispose(result) in errors end
  val ()=scalar_dispose(text)
in iadd(errors,if ieq(before,mem_live()) then 0 else 1) end

