staload "data_text/bidi/bidi_line.sats"
fun window_order{n:nat} .<n>. (left: int(n),whole: !BidiOrder,window: !BidiOrder,first: int,index: int): bool =
  if left = 0 then true else let val+ BidiOrder(a,na)=whole val+ BidiOrder(b,nb)=window
  in ieq(buf_get32(a,index),iadd(first,buf_get32(b,index))) andalso window_order(left-1,whole,window,first,iadd(index,1)) end
fun window_levels{n:nat} .<n>. (left: int(n),parent: !NativeTextAnalysis,window: !NativeTextAnalysis,first: int,index: int): bool =
  if left = 0 then true else let
    val script=native_text_analysis_script(parent,iadd(first,index)) val window_script=native_text_analysis_script(window,index)
  in ieq(script.code,window_script.code) andalso ieq(native_text_analysis_level(parent,iadd(first,index)),native_text_analysis_level(window,index))
    andalso window_levels(left-1,parent,window,first,iadd(index,1)) end
fun window_examined(assets: !NativeTextAssets,parent: !NativeTextAnalysis,window: NativeTextAnalysis,first: int,base: int,length: int): int = let
  val+ NativeTextAssets(aux,words,lines,east)=assets val+ NativeTextAux(data,s,map,br,mirrors)=aux
  val+ NativeTextAnalysis(old,old_bidi,os,ob,og,old_length)=parent
  val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=window val count=scalar_count(text)
  val whole_order=bidi_document_line(old_bidi,map,old,first,iadd(first,count))
  val local_order=bidi_document_line(bidi,map,text,0,count)
  val inherited=window_levels(airlock_nat(count),parent,window,first,0)
  val order=ieq(bidi_order_count(whole_order),bidi_order_count(local_order))
    andalso window_order(airlock_nat(count),whole_order,local_order,first,0)
  val correct=ieq(source_length,length) andalso inherited andalso order
    andalso (ieq(count,0) orelse ieq(bidi_document_base(bidi,0),base))
  val ()=bidi_order_dispose(whole_order) val ()=bidi_order_dispose(local_order) val ()=native_text_analysis_dispose(window)
in if correct then 0 else 1 end
fun window_accept(assets: !NativeTextAssets,text: string,start: int,finish: int,first: int,base: int): int = let
  val source=bytes(text) val length=buf_len(source)
  val errors=case+ native_text_analyze(assets,source,length,AutoLtr()) of | ~NativeAnalysisRejected(e) => 1
    | ~NativeAnalysisAccepted(parent) => let
      val errors=case+ native_text_analysis_window(parent,start,finish) of | ~NativeAnalysisRejected(e) => 1
        | ~NativeAnalysisAccepted(window) => window_examined(assets,parent,window,first,base,isub(finish,start))
      val ()=native_text_analysis_dispose(parent)
    in errors end
  val ()=buf_free(source)
in errors end
fun window_reject(parent: !NativeTextAnalysis,start: int,finish: int): int =
  case+ native_text_analysis_window(parent,start,finish) of | ~NativeAnalysisRejected(e) => 0
  | ~NativeAnalysisAccepted(window) => let val ()=native_text_analysis_dispose(window) in 1 end
fun window_invalid_cases(assets: !NativeTextAssets): int = let val source=bytes("a\314\225\314\200")
  val errors=case+ native_text_analyze(assets,source,5,AutoLtr()) of | ~NativeAnalysisRejected(e) => 1
    | ~NativeAnalysisAccepted(parent) => let
      val rejected=window_reject(parent,0,1)+window_reject(parent,1,5)+window_reject(parent,~1,5)
        +window_reject(parent,0,6)+window_reject(parent,5,0)
      val ()=native_text_analysis_dispose(parent)
    in rejected end
  val ()=buf_free(source)
in errors end
fun window_reject_text(assets: !NativeTextAssets,text: string,start: int,finish: int): int = let
  val source=bytes(text) val length=buf_len(source)
  val errors=case+ native_text_analyze(assets,source,length,AutoLtr()) of | ~NativeAnalysisRejected(e) => 1
    | ~NativeAnalysisAccepted(parent) => let val rejected=window_reject(parent,start,finish)
      val ()=native_text_analysis_dispose(parent)
    in rejected end
  val ()=buf_free(source)
in errors end
fun native_analysis_window_cases(assets: !NativeTextAssets): int =
  window_accept(assets,"بب 123 (abc) بب",5,8,3,1)
  +window_accept(assets,"a \342\200\253123 xyz\342\200\254 z",5,8,3,0)
  +window_accept(assets,"a \342\201\247ب 123 abc\342\201\251 z",8,12,5,0)
  +window_accept(assets,"بب 123 (abc) بب",5,14,3,1)
  +window_accept(assets,"a\314\225\314\200",0,5,0,0)
  +window_accept(assets,"I\314\207",0,3,0,0)
  +window_accept(assets,"a\nb",0,2,0,0)+window_accept(assets,"a\nb",2,3,2,0)
  +window_accept(assets,"\377A",0,1,0,0)+window_accept(assets,"",0,0,0,0)
  +window_reject_text(assets,"a\nb",0,3)
  +window_invalid_cases(assets)
