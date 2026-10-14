#include "data_font/native_text_items_internal.hats"
fun measure{fuel:nat} .<fuel>. (fuel: int(fuel),a: !NativeTextAnalysis,index: int,limit: int,count: int): int =
  if fuel = 0 then native_items_fuel_failed() else if ige(index,limit) then count
  else measure(fuel-1,a,native_text_item_finish(a,index),limit,iadd(count,1))
fun fill{fuel:nat} .<fuel>. (fuel: int(fuel),a: !NativeTextAnalysis,items: !NativeTextItems,
  index: int,limit: int,row: int): void =
  if fuel = 0 then native_items_walk_failed() else if ige(index,limit) then () else let
    val finish=native_text_item_finish(a,index)
    val ()=native_text_items_set(items,row,native_text_item_read(a,index,finish))
  in fill(fuel-1,a,items,finish,limit,iadd(row,1)) end
implement native_text_items_measure(a) = measure(MAX_REC_FUEL,a,0,native_text_analysis_count(a),0)
implement native_text_items_fill(a,items) = fill(MAX_REC_FUEL,a,items,0,native_text_analysis_count(a),0)
