staload "mem.sats"
staload "data_font/native/ownership/font_native_types.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "data_font/native/text/native_text_items_types.sats"
vtypedef FontSpanSlot = Option_vt(FontNativeRun)
datavtype FontSpanRuns = {n:nat}{l:addr} FontSpanRuns of
  (array_v(FontSpanSlot,l,n),mfree_gc_v(l) | ptr(l),int(n))
(* SpanSkipPart keeps an unsupported-script or shaping-rejected item's source
   range with zero ink and zero advance, so the rest of the row still draws. *)
datatype FontSpanPartKind = SpanTextPart | SpanTabPart | SpanLineEndPart | SpanSkipPart
typedef FontSpanPart = @{kind=FontSpanPartKind,start=int,finish=int,sourceStart=int,sourceEnd=int,level=int,width=int,x=int}
datavtype FontSpanLayout = {n:nat} FontSpanLayout of
  (NativeTextAnalysis,NativeTextItems,FontSpanRuns,arrayptr(FontSpanPart,n),Buf,int(n),int,int)
(* SpanMissing and SpanUnsupported are presentation failures: the row installs
   a zero-ink skip part and stays accepted. The remaining variants are
   infrastructure errors and keep the whole span rejected. *)
datatype FontSpanFailure = SpanAnalysis | SpanItems | SpanContext | SpanShaping | SpanCapacity | SpanOverflow | SpanParagraph
  | SpanMissing | SpanUnsupported
datavtype FontSpanRead = FontSpanAccepted of FontSpanLayout | FontSpanRejected of FontSpanFailure
