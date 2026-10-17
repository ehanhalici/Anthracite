#include "data_font/text/span/font_span_internal.hats"
staload "data_text/bidi/bidi_line.sats"
staload "data_font/text/span/private/font_span_order.sats"
implement font_span_order(assets,layout) = let
  val+ FontSpanLayout(a,items,runs,parts,order,n,width,direction)=layout
  val+ NativeTextAnalysis(text,doc,scripts,breaks,graphemes,source_length)=a
  val+ NativeTextAssets(aux,words,lines,east)=assets val+ NativeTextAux(base,s,b,br,mirrors)=aux
  val visual=bidi_document_line(doc,b,text,0,scalar_count(text))
  val map=buf_make(imul(scalar_count(text),4)) and seen=buf_make(n)
  val ()=font_span_order_map(layout,map,seen)
  val initial=font_span_order_walk(layout,visual,map,seen)
  val final=font_span_order_tail(layout,seen,initial)
  val ()=buf_free(map) and ()=buf_free(seen) and ()=bidi_order_dispose(visual)
  val+ @FontSpanLayout(analysis,spans,owners,rows,indices,count,total,dir)=layout
  val ()=total := final.x prval ()=fold@(layout)
in () end
