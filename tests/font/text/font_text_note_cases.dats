#include "font/native/ownership/font_native_test.hats"
staload "data_font/text/font_text.sats"
staload "data_font/text/font_text_types.sats"
staload "data_font/text/private/font_text_dispatch.sats"
staload "data_text/source/text_source.sats"
extern fun note_fuel_failed(): int = "mac#anth_die_int"
fun drawn(result: FontTextResult,width: int): int = case+ result of
  | FontTextValue(actual) => if ieq(actual,width) then 0 else 1
  | FontTextInactive() => 1 | FontTextFailed(error) => 1
fun line(f: !Font,r: !Rend,source: !Buf,start: int,finish: int,index: int): int = let
  val n=isub(finish,start) val b=font_text_slice_source(source,start,n)
  val errors: int=case+ font_text_width(f,b,n) of
    | FontTextInactive() => 1 | FontTextFailed(error) => 1
    | FontTextValue(width) => drawn(font_text_draw(f,r,b,n,20,300,0xFFFFFFFFu),width)
  val ()=if ine(errors,0) then println!("event=native_note_line line=",iadd(index,0)," errors=",iadd(errors,0)) else ()
  val ()=buf_free(b)
in errors end
fun lines{fuel:nat} .<fuel>. (fuel: int(fuel),f: !Font,r: !Rend,source: !Buf,start: int,
  limit: int,index: int,errors: int): int = if ige(start,limit) then errors
  else if fuel = 0 then note_fuel_failed() else let val finish=text_line_end(source,start,limit)
    val outcome=line(f,r,source,start,finish,index)
  in lines(fuel-1,f,r,source,iadd(finish,1),limit,iadd(index,1),iadd(errors,outcome)) end
implement native_text_note_cases(f,r) = let val path=c_getenv("ANTHRACITE_NATIVE_TEST_NOTE")
in if ieq(c_strlen(path),0) then 0 else case+ text_file_read(path) of
  | ~TextFileError(error) => 1 | ~TextFile(source) => let
    val errors=lines(MAX_REC_FUEL,f,r,source,0,buf_len(source),0,0)
    val ()=buf_free(source) val ()=println!("event=native_note_render errors=",errors)
  in errors end end
