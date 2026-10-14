#include "data_font/font_span_internal.hats"
staload "data_font/private/font_span_partition.sats"
staload "data_font/native_text_items_work.sats"
fun measure{n:nat} .<n>. (left: int(n),cuts: !Buf,index: int,total: int): int = if left = 0 then total
  else measure(left-1,cuts,iadd(index,1),iadd(total,buf_get(cuts,index)))
fun finish{n:nat} .<n>. (left: int(n),cuts: !Buf,index: int): int =
  if left = 0 then index else if ine(buf_get(cuts,index),0) then index else finish(left-1,cuts,iadd(index,1))
fun fill{n:nat} .<n>. (left: int(n),a: !NativeTextAnalysis,cuts: !Buf,items: !NativeTextItems,
  start: int,limit: int,index: int): void = if left = 0 then () else let
    val stop=finish(airlock_span(iadd(start,1),limit),cuts,iadd(start,1))
    val ()=native_text_items_set(items,index,native_text_item_read(a,start,stop))
  in fill(left-1,a,cuts,items,stop,limit,iadd(index,1)) end
fun allocated(a: !NativeTextAnalysis,cuts: !Buf,count: int): NativeItemsRead = let
  val n=airlock_nat(count) val empty: NativeTextItem= @{start=0,finish=0,sourceStart=0,sourceEnd=0,level=0,script= @{code=SCRIPT_UNKNOWN}}
  val items=NativeTextItems(arrayptr_make_elt<NativeTextItem>(i2sz(n),empty),n)
  val ()=fill(n,a,cuts,items,0,native_text_analysis_count(a),0)
in NativeItemsAccepted(items) end
fun bounded(a: !NativeTextAnalysis,cuts: !Buf,count: int): NativeItemsRead =
  if igt(count,idiv(MAX_REC_FUEL,128)) then NativeItemsRejected(ItemsCapacity()) else allocated(a,cuts,count)
implement font_span_items_make(f,assets,a) = let
  val size=airlock_nat(native_text_analysis_count(a)) val cuts=buf_make(size) val ()=buf_zero(cuts)
  val ()=font_span_partition_mark(f,assets,a,cuts) val count=measure(size,cuts,0,0)
  val result=bounded(a,cuts,count)
  val ()=buf_free(cuts)
in result end
