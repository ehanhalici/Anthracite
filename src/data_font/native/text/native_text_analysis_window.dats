#include "data_font/native/text/native_text_analysis_internal.hats"
macdef ANALYSIS_WINDOW_SEARCH_FUEL = 32
macdef ANALYSIS_BUFFER_ALLOWANCE_BYTES = 64LL
macdef ANALYSIS_OBJECT_ALLOWANCE_BYTES = 1024LL
fun scalar_bound{n:nat} .<n>. (fuel: int(n),text: !ScalarText,source: int,lo: int,hi: int): int =
  if not(recursion_fuel_available(fuel)) then lo else if ige(lo,hi) then lo else let
    val middle=iadd(lo,idiv(isub(hi,lo),2))
  in if ilt(scalar_start(text,middle),source) then scalar_bound(fuel-1,text,source,iadd(middle,1),hi)
    else scalar_bound(fuel-1,text,source,lo,middle) end
fun source_boundary(a: !NativeTextAnalysis,index: int,source: int,limit: int): bool = let
  val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a val count=scalar_count(text)
in if ieq(index,count) then ieq(source,limit)
  else ieq(scalar_start(text,index),source) andalso native_text_analysis_grapheme(a,index) end
fun window_valid(a: !NativeTextAnalysis,start: int,finish: int,first: int,last: int): bool = let
  val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a val count=scalar_count(text)
  val limit=source_length
in ige(start,0) andalso ige(finish,start) andalso ile(finish,limit)
  andalso source_boundary(a,first,start,limit) andalso source_boundary(a,last,finish,limit)
  andalso (ieq(first,last) orelse ile(last,bidi_document_paragraph_end(bidi,first))) end
fun copy_scalar(parent: !NativeTextAnalysis,window: !NativeTextAnalysis,index: int,source: int,origin: int,count: int): void = let
  val+ NativeTextAnalysis(old,bidi,scripts,breaks,graphemes,source_length)=parent
  val+ NativeTextAnalysis(text,new_bidi,new_scripts,new_breaks,new_graphemes,source_length)=window
  val+ ScalarText(values,starts,ends,n,errors)=text
  val+ BidiDocument(levels,bases,paragraph_ends,nb)=new_bidi val+ ScriptItems(codes,ns)=new_scripts
  val script=native_text_analysis_script(parent,source)
  val ()=buf_set32(values,index,scalar_value(old,source))
  val ()=buf_set32(starts,index,isub(scalar_start(old,source),origin))
  val ()=buf_set32(ends,index,isub(scalar_end(old,source),origin))
  val ()=buf_set(levels,index,bidi_document_level(bidi,source)) val ()=buf_set(bases,index,bidi_document_base(bidi,source))
  val ()=buf_set32(paragraph_ends,index,count) val ()=buf_set32(codes,index,script.code)
  val ()=line_breaks_put(new_breaks,index,native_text_analysis_break(parent,source))
in buf_set(new_graphemes,index,if native_text_analysis_grapheme(parent,source) then 1 else 0) end
fun copy_scalars{n:nat} .<n>. (left: int(n),parent: !NativeTextAnalysis,window: !NativeTextAnalysis,
  first: int,origin: int,count: int,index: int): void =
  if left = 0 then () else let val ()=copy_scalar(parent,window,index,iadd(first,index),origin,count)
  in copy_scalars(left-1,parent,window,first,origin,count,iadd(index,1)) end
fun make_window(parent: !NativeTextAnalysis,first: int,last: int,origin: int,finish: int): NativeAnalysisRead = let
  val count=isub(last,first) val words=imul(count,WORD32_BYTES)
  val text=ScalarText(buf_make(words),buf_make(words),buf_make(words),count,0)
  val bidi=BidiDocument(buf_make(count),buf_make(count),buf_make(words),count)
  val breaks=line_breaks_make(count)
  val ()=line_breaks_put(breaks,count,BreakMandatory())
  val window=NativeTextAnalysis(text,bidi,ScriptItems(buf_make(words),count),breaks,buf_make(count),isub(finish,origin))
  val ()=copy_scalars(airlock_nat(count),parent,window,first,origin,count,0)
in NativeAnalysisAccepted(window) end
implement native_text_analysis_window(a,start,finish) = let
  val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a val count=scalar_count(text)
  val first=scalar_bound(ANALYSIS_WINDOW_SEARCH_FUEL,text,start,0,count)
  val last=scalar_bound(ANALYSIS_WINDOW_SEARCH_FUEL,text,finish,first,count)
in if window_valid(a,start,finish,first,last) then make_window(a,first,last,start,finish)
  else NativeAnalysisRejected(@{reason=AnalysisSpan(),detail=start}) end
fun buffer_bytes(buffer: !Buf): llint = g0int2int_int_llint(buf_cap(buffer))+ANALYSIS_BUFFER_ALLOWANCE_BYTES
implement native_text_analysis_memory_bytes(analysis) = let
  val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=analysis
  val+ ScalarText(values,starts,ends,count,errors)=text val+ BidiDocument(levels,bases,paragraphs,n)=bidi
  val+ ScriptItems(items,ni)=scripts val+ LineBreakMap(flags,nf)=breaks
in buffer_bytes(values)+buffer_bytes(starts)+buffer_bytes(ends)+buffer_bytes(levels)+buffer_bytes(bases)
  +buffer_bytes(paragraphs)+buffer_bytes(items)+buffer_bytes(flags)+buffer_bytes(graphemes)+ANALYSIS_OBJECT_ALLOWANCE_BYTES end
