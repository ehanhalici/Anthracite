#include "data_font/native_text_context_internal.hats"
fun allocated(assets: !NativeTextAssets,a: !NativeTextAnalysis,count: int): NativeContextRead = let
  val n=airlock_pos(iadd(count,1))
  val contexts=NativeTextContexts(arrayptr_make_elt<ArabicBoundary>(i2sz(n),BoundaryNone()),
    arrayptr_make_elt<ArabicBoundary>(i2sz(n),BoundaryNone()),n)
  val+ NativeTextAssets(aux,words,lines,east)=assets val+ NativeTextAux(base,s,b,br,mirrors)=aux
  val+ NativeTextBase(shape,norm,mcm)=base val+ NativeShapeData(db,c,i,j)=shape
  val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes)=a
  val ()=native_context_before(j,text,bidi,contexts) and ()=native_context_after(j,text,bidi,contexts)
in NativeContextAccepted(contexts) end
implement native_text_context_make(assets,a) = let val count=native_text_analysis_count(a)
  val bytes=g0uint2int_size_int(sizeof<ArabicBoundary>)
in if ige(count,idiv(MAX_REC_FUEL,imul(bytes,2))) then NativeContextRejected(ContextCapacity())
  else allocated(assets,a,count) end
implement native_context_set_before(contexts,index,value) = let val+ NativeTextContexts(before,after,n)=contexts
in arrayptr_set_at<ArabicBoundary>(before,i2sz(airlock_below(index,n)),value) end
implement native_context_set_after(contexts,index,value) = let val+ NativeTextContexts(before,after,n)=contexts
in arrayptr_set_at<ArabicBoundary>(after,i2sz(airlock_below(index,n)),value) end
implement native_text_context_at(contexts,start,finish) = let val+ NativeTextContexts(before,after,n)=contexts
in @{before=arrayptr_get_at<ArabicBoundary>(before,i2sz(airlock_below(start,n))),
  after=arrayptr_get_at<ArabicBoundary>(after,i2sz(airlock_below(finish,n)))} end
implement native_text_context_dispose(contexts) = let val+ ~NativeTextContexts(before,after,n)=contexts
in arrayptr_free(before); arrayptr_free(after) end
