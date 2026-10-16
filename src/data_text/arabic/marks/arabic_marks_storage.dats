#include "data_text/arabic/marks/arabic_marks_internal.hats"
implement arabic_mark_unit(source,index) = @{scalar=scalar_value(source,index),start=scalar_start(source,index),finish=scalar_end(source,index)}
implement arabic_mark_store(source,index,unit) = let val+ ScalarText(values,starts,ends,count,errors)=source
  val ()=buf_set32(values,index,unit.scalar) and ()=buf_set32(starts,index,unit.start)
in buf_set32(ends,index,unit.finish) end
fun initialize{n:nat} .<n>. (left: int(n),permutation: !Buf,index: int): void =
  if left = 0 then () else let val ()=buf_set32(permutation,index,index)
  in initialize(left-1,permutation,iadd(index,1)) end
implement arabic_mark_initialize(permutation,count) = initialize(airlock_nat(count),permutation,0)
