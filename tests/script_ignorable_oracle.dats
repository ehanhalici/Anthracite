#include "script_test.hats"
fun assign{n:nat} .<n>. (left: int(n),dense: !Buf,cp: int): void =
  if left = 0 then () else let val ()=buf_set(dense,cp,1) in assign(left-1,dense,iadd(cp,1)) end
fun row(b: !Buf,dense: !Buf,p: int,en: int): void =
  if ige(p,en) orelse ieq(buf_get(b,p),35) then () else let val r=script_source_range(b,p,en)
  in if text_token_is(b,r.field,en,"Default_Ignorable_Code_Point")
    then assign(airlock_nat(iadd(isub(r.last,r.first),1)),dense,r.first) else () end
fun lines{n:nat} .<n>. (left: int(n),b: !Buf,dense: !Buf,p: int,en: int): void =
  if ige(p,en) then () else if left = 0 then () else let val finish=text_line_end(b,p,en)
    val ()=row(b,dense,text_skip_space(b,p,finish),finish)
  in lines(left-1,b,dense,iadd(finish,1),en) end
fun compare{n:nat} .<n>. (left: int(n),d: !PropertyMap(8),dense: !Buf,cp: int,errors: int): int =
  if left = 0 then errors else let val ok=ieq(property_value(d,cp),buf_get(dense,cp))
  in compare(left-1,d,dense,iadd(cp,1),iadd(errors,if ok then 0 else 1)) end
implement script_test_ignorables(d,path) = case+ text_file_read(path) of | ~TextFileError(code) => 1
  | ~TextFile(b) => let val dense=buf_make(UNICODE_SCALAR_LIMIT)
    val ()=lines(airlock_nat(buf_len(b)),b,dense,0,buf_len(b))
    val errors=compare(1114112,d,dense,0,0) val ()=buf_free(b) and ()=buf_free(dense)
  in errors end
