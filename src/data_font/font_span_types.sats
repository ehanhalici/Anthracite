staload "mem.sats"
staload "data_font/font_native_types.sats"
staload "data_font/native_text_analysis_types.sats"
staload "data_font/native_text_items_types.sats"
vtypedef FontSpanSlot = Option_vt(FontNativeRun)
datavtype FontSpanRuns = {n:nat}{l:addr} FontSpanRuns of
  (array_v(FontSpanSlot,l,n),mfree_gc_v(l) | ptr(l),int(n))
datatype FontSpanPartKind = SpanTextPart | SpanTabPart | SpanLineEndPart
typedef FontSpanPart = @{kind=FontSpanPartKind,start=int,finish=int,sourceStart=int,sourceEnd=int,level=int,width=int,x=int}
datavtype FontSpanLayout = {n:nat} FontSpanLayout of
  (NativeTextAnalysis,NativeTextItems,FontSpanRuns,arrayptr(FontSpanPart,n),Buf,int(n),int,int)
datatype FontSpanFailure = SpanAnalysis | SpanItems | SpanContext | SpanShaping | SpanCapacity | SpanOverflow | SpanParagraph
datavtype FontSpanRead = FontSpanAccepted of FontSpanLayout | FontSpanRejected of FontSpanFailure
