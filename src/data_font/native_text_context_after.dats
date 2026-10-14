#include "data_font/native_text_context_internal.hats"
fun after(bidi: !BidiDocument,index: int,current: ArabicBoundary): ArabicBoundary =
  if ige(iadd(index,1),bidi_document_paragraph_end(bidi,index)) then BoundaryNone() else current
fun walk{n:nat} .<n>. (left: int(n),map: !PropertyMap(3),text: !ScalarText,bidi: !BidiDocument,
  contexts: !NativeTextContexts,current: ArabicBoundary): void =
  if left = 0 then () else let val index=isub(left,1)
    val next=native_context_next(map,scalar_value(text,index),after(bidi,index,current))
    val ()=native_context_set_after(contexts,index,next)
  in walk(left-1,map,text,bidi,contexts,next) end
implement native_context_after(map,text,bidi,contexts) =
  walk(airlock_nat(scalar_count(text)),map,text,bidi,contexts,BoundaryNone())
implement native_context_next(map,cp,current) = case+ arabic_boundary_of(arabic_joining(map,cp)) of
  | ~None_vt() => current | ~Some_vt(boundary) => boundary
