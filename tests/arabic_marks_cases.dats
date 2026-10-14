#include "arabic_marks_test.hats"
fun rows{n:nat} .<n>. (left: int(n),source: !ScalarText,want: !Buf,index: int): int =
  if left = 0 then 0 else let val original=buf_get32(want,iadd(imul(index,2),1))
    val ok=ieq(scalar_value(source,index),buf_get32(want,imul(index,2)))
      andalso ieq(scalar_start(source,index),imul(original,4)) andalso ieq(scalar_end(source,index),imul(iadd(original,1),4))
  in iadd(if ok then 0 else 1,rows(left-1,source,want,iadd(index,1))) end
implement marks_test_case(data,mcm,words,want) = let
  val source=marks_test_source(words) val expected=marks_test_words(want) val count=idiv(buf_len(expected),8)
  val errors=case+ arabic_marks_apply(data,mcm,source) of | ~ArabicMarksRejected(e) => 1
    | ~ArabicMarksReady(result) => let
      val errors=if ieq(count,scalar_count(result)) then rows(airlock_nat(count),result,expected,0) else 1
      val ()=scalar_dispose(result) in errors end
  val ()=scalar_dispose(source) and ()=buf_free(expected)
in errors end
implement marks_test_cases(data,mcm) =
  marks_test_case(data,mcm,"0628 064E 0651","0628 0 0651 2 064E 1")
  +marks_test_case(data,mcm,"0628 0651 064E","0628 0 0651 1 064E 2")
  +marks_test_case(data,mcm,"0628 064E 034F 0651","0628 0 064E 1 034F 2 0651 3")
  +marks_test_case(data,mcm,"0628 0650 0655 06E3 0651 0654","0628 0 0655 2 06E3 3 0654 5 0651 4 0650 1")
  +marks_test_case(data,mcm,"0628 0651 064E 0653 0654","0628 0 0651 1 064E 2 0653 3 0654 4")
  +marks_test_case(data,mcm,"0623 064E","0627 0 0654 0 064E 1")
  +marks_test_case(data,mcm,"0628 064E 0651 10EF4 10EF6 10EF9","0628 0 10EF4 3 10EF6 4 10EF9 5 0651 2 064E 1")
  +marks_test_case(data,mcm,"0651 064E","0651 0 064E 1")
  +marks_test_case(data,mcm,"0628 0651 0651 064E","0628 0 0651 1 0651 2 064E 3")
  +marks_test_case(data,mcm,"0041 0020 0628 064E 0651 0020 0628 0651 064E","0041 0 0020 1 0628 2 0651 4 064E 3 0020 5 0628 6 0651 7 064E 8")
  +marks_test_case(data,mcm,"","")

