#include "data_font/native/text/native_text_items_internal.hats"
fun changed(a: !NativeTextAnalysis,index: int,level: int,script: ScriptCode): bool = let
  val next=native_text_analysis_script(a,index)
in ine(native_text_analysis_level(a,index),level) orelse ine(next.code,script.code) end
fun finish{fuel:nat} .<fuel>. (fuel: int(fuel),a: !NativeTextAnalysis,index: int,
  limit: int,paragraph: int,level: int,script: ScriptCode): int =
  if fuel = 0 then native_items_fuel_failed() else if ige(index,limit) then limit
  else if native_text_analysis_grapheme(a,index) andalso
    (ige(index,paragraph) orelse changed(a,index,level,script)) then index
  else finish(fuel-1,a,iadd(index,1),limit,paragraph,level,script)
implement native_text_item_finish(a,start) = let
  val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a
  val limit=scalar_count(text) val paragraph=bidi_document_paragraph_end(bidi,start)
  val level=native_text_analysis_level(a,start) val script=native_text_analysis_script(a,start)
in finish(MAX_REC_FUEL,a,iadd(start,1),limit,paragraph,level,script) end
