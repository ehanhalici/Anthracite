#include "native_pipeline_test.hats"
fun copy{n:nat} .<n>. (left: int(n),text: string,b: !Buf,index: int): void =
  if left = 0 then () else let val ()=buf_set(b,index,c_str_byte(text,index))
  in copy(left-1,text,b,iadd(index,1)) end
implement pipeline_bytes(text) = let val n=c_strlen(text) val b=buf_make(n)
  val ()=copy(airlock_nat(n),text,b,0) val ()=buf_set_len(b,n)
in b end
