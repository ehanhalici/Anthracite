#include "script_compile_internal.hats"
typedef SourcePart = @{last=int,next=int,valid=bool}
fun tail(b: !Buf,p: int,en: int,first: int): SourcePart =
  if not(ieq(buf_get(b,p),46)) then @{last=first,next=p,valid=true} else let
    var position: int=iadd(p,2) val last=text_hex(b,position,en)
  in @{last=last,next=position,valid=ieq(buf_get(b,iadd(p,1)),46) andalso igt(position,iadd(p,2))} end
implement script_source_range(b,p,en) = let var position: int=p
  val first=text_hex(b,position,en) val firstValid=igt(position,p)
  val part=tail(b,position,en,first) val separator=text_skip_space(b,part.next,en)
  val field=text_skip_space(b,iadd(separator,1),en)
  val valid=firstValid andalso part.valid andalso ilt(separator,en) andalso ieq(buf_get(b,separator),59)
    andalso ige(first,0) andalso ige(part.last,first) andalso ilt(part.last,UNICODE_SCALAR_LIMIT)
in @{first=first,last=part.last,field=field,valid=valid} end
fun lower(c: int): bool = ige(c,97) andalso ile(c,122)
fun tag_bytes(b: !Buf,p: int): bool =
  ige(buf_get(b,p),65) andalso ile(buf_get(b,p),90) andalso lower(buf_get(b,iadd(p,1)))
  andalso lower(buf_get(b,iadd(p,2))) andalso lower(buf_get(b,iadd(p,3)))
implement script_source_tag(b,p,en) =
  if ilt(p,0) orelse igt(p,isub(en,4)) orelse not(tag_bytes(b,p)) then ~1 else let
    val code=iadd(imul(buf_get(b,p),16777216),iadd(imul(buf_get(b,iadd(p,1)),WORD16_MODULUS),
      iadd(imul(buf_get(b,iadd(p,2)),256),buf_get(b,iadd(p,3)))))
  in if script_code_valid(code) then code else ~1 end
