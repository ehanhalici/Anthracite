#include "data_text/arabic_marks_internal.hats"
extern fun arabic_permutation_failed(): void = "mac#anth_die_void"
fun cycle{n:nat} .<n>. (left: int(n),source: !ScalarText,permutation: !Buf,start: int,node: int,carry: ArabicMarkUnit): void =
  if left = 0 then arabic_permutation_failed() else let val target=buf_get32(permutation,node)
  in if ilt(target,0) orelse ige(target,scalar_count(source)) then arabic_permutation_failed() else let
    val next=arabic_mark_unit(source,target)
    val ()=arabic_mark_store(source,target,carry) and ()=buf_set32(permutation,node,node)
  in if ieq(target,start) then () else cycle(left-1,source,permutation,start,target,next) end end
fun walk{n:nat} .<n>. (left: int(n),source: !ScalarText,permutation: !Buf,index: int): void =
  if left = 0 then () else let
    val ()=if ieq(buf_get32(permutation,index),index) then () else
      cycle(airlock_nat(scalar_count(source)),source,permutation,index,index,arabic_mark_unit(source,index))
  in walk(left-1,source,permutation,iadd(index,1)) end
implement arabic_mark_permute(source,permutation) = walk(airlock_nat(scalar_count(source)),source,permutation,0)

