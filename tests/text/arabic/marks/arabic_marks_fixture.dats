#include "text/arabic/marks/arabic_marks_test.hats"
extern fun marks_fixture_failed(): int = "mac#anth_die_int"
fun copy{n:nat} .<n>. (left: int(n),source: string,b: !Buf,index: int): void =
  if left = 0 then () else let val ()=buf_set(b,index,c_str_byte(source,index)) in copy(left-1,source,b,iadd(index,1)) end
fun words{n:nat} .<n>. (left: int(n),b: !Buf,p: int,en: int,output: !Buf,index: int): int =
  if ige(text_skip_space(b,p,en),en) then index else if left = 0 then marks_fixture_failed() else let
    var next: int=text_skip_space(b,p,en) val cp=text_hex(b,next,en)
    val ()=buf_set32(output,index,cp)
  in words(left-1,b,next,en,output,iadd(index,1)) end
implement marks_test_words(source) = let val length=c_strlen(source) val b=buf_make(length)
  val ()=copy(airlock_nat(length),source,b,0) val output=buf_make(imul(length,4))
  val count=words(airlock_nat(iadd(length,1)),b,0,length,output,0)
  val ()=buf_set_len(output,imul(count,4)) and ()=buf_free(b)
in output end
fun spans{n:nat} .<n>. (left: int(n),starts: !Buf,ends: !Buf,index: int): void =
  if left = 0 then () else let val ()=buf_set32(starts,index,imul(index,4))
    val ()=buf_set32(ends,index,imul(iadd(index,1),4)) in spans(left-1,starts,ends,iadd(index,1)) end
implement marks_test_source(source) = let val values=marks_test_words(source) val count=idiv(buf_len(values),4)
  val starts=buf_make(imul(count,4)) and ends=buf_make(imul(count,4))
  val ()=spans(airlock_nat(count),starts,ends,0)
in ScalarText(values,starts,ends,count,0) end
