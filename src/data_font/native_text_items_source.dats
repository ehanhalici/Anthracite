#include "data_font/native_text_items_internal.hats"
typedef SourceEnvelope = @{start=int,finish=int}
fun envelope{fuel:nat} .<fuel>. (fuel: int(fuel),text: !ScalarText,index: int,
  limit: int,span: SourceEnvelope): SourceEnvelope =
  if fuel = 0 then let val dead=native_items_fuel_failed() in span end
  else if ige(index,limit) then span else let
    val first=scalar_start(text,index) and last=scalar_end(text,index)
    val next: SourceEnvelope= @{start=imin(span.start,first),finish=imax(span.finish,last)}
  in envelope(fuel-1,text,iadd(index,1),limit,next) end
implement native_text_item_read(a,start,finish) = let
  val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes)=a
  val span=envelope(MAX_REC_FUEL,text,start,finish,@{start=scalar_start(text,start),finish=scalar_end(text,start)})
in @{start=start,finish=finish,sourceStart=span.start,sourceEnd=span.finish,
  level=native_text_analysis_level(a,start),script=native_text_analysis_script(a,start)} end
implement native_text_item_direction(item) =
  if ieq(imod(item.level,2),0) then ShapeLTR() else ShapeRTL()
