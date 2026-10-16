#include "text/arabic/marks/arabic_marks_test.hats"
fun expected{n:nat} .<n>. (left: int(n),values: !Buf,cp: int,index: int): int =
  if left = 0 then 0 else if ieq(cp,buf_get32(values,index)) then 1 else expected(left-1,values,cp,iadd(index,1))
fun check{n:nat} .<n>. (left: int(n),mcm: !PropertyMap(9),values: !Buf,cp: int,errors: int): int =
  if left = 0 then errors else let
    val matches=ieq(property_value(mcm,cp),expected(17,values,cp,0))
  in check(left-1,mcm,values,iadd(cp,1),iadd(errors,if matches then 0 else 1)) end
implement marks_test_properties(mcm) = let
  val values=marks_test_words("0654 0655 0658 06DC 06E3 06E7 06E8 08CA 08CB 08CD 08CE 08CF 08D3 08F3 10EF4 10EF6 10EF9")
  val errors=check(1114112,mcm,values,0,0) val ()=buf_free(values)
in errors end
