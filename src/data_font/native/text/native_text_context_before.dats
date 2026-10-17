#include "data_font/native/text/native_text_context_internal.hats"
fun before(bidi: !BidiDocument,index: int,current: ArabicBoundary): ArabicBoundary =
  if ieq(index,0) then BoundaryNone() else
  if ige(index,bidi_document_paragraph_end(bidi,isub(index,1))) then BoundaryNone() else current
fun walk{n:nat} .<n>. (left: int(n),map: !PropertyMap(3),text: !ScalarText,bidi: !BidiDocument,
  contexts: !NativeTextContexts,index: int,current: ArabicBoundary): void = let
  val boundary=before(bidi,index,current)
  val ()=native_context_set_before(contexts,index,boundary)
in if left = 0 then () else let val next=native_context_next(map,scalar_value(text,index),boundary)
  in walk(left-1,map,text,bidi,contexts,iadd(index,1),next) end end
implement native_context_before(map,text,bidi,contexts) =
  walk(airlock_nat(scalar_count(text)),map,text,bidi,contexts,0,BoundaryNone())
