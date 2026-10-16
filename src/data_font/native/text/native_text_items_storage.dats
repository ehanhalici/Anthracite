#include "data_font/native/text/native_text_items_internal.hats"
fun allocated(a: !NativeTextAnalysis,count: int): NativeItemsRead = let
  val n=airlock_nat(count)
  val empty: NativeTextItem= @{start=0,finish=0,sourceStart=0,sourceEnd=0,level=0,script= @{code=SCRIPT_UNKNOWN}}
  val rows=arrayptr_make_elt<NativeTextItem>(i2sz(n),empty)
  val items=NativeTextItems(rows,n) val ()=native_text_items_fill(a,items)
in NativeItemsAccepted(items) end
implement native_text_items_make(a) = let val count=native_text_items_measure(a)
  val rowBytes=g0uint2int_size_int(sizeof<NativeTextItem>)
in if igt(count,idiv(MAX_REC_FUEL,rowBytes)) then NativeItemsRejected(ItemsCapacity()) else allocated(a,count) end
implement native_text_items_count(items) = let val+ NativeTextItems(rows,n)=items in n end
implement native_text_items_at(items,index) = let val+ NativeTextItems(rows,n)=items
in arrayptr_get_at<NativeTextItem>(rows,i2sz(airlock_below(index,n))) end
implement native_text_items_set(items,index,item) = let val+ NativeTextItems(rows,n)=items
in arrayptr_set_at<NativeTextItem>(rows,i2sz(airlock_below(index,n)),item) end
implement native_text_items_dispose(items) = let val+ ~NativeTextItems(rows,n)=items in arrayptr_free(rows) end
