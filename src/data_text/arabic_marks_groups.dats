#include "data_text/arabic_marks_internal.hats"
extern fun arabic_group_fuel_failed(): int = "mac#anth_die_int"
fun end_of{n:nat} .<n>. (left: int(n),data: !NormalizationData,source: !ScalarText,index: int,count: int): int =
  if ige(index,count) then index else if left = 0 then arabic_group_fuel_failed() else let
    val info=normalization_info(data,scalar_value(source,index))
  in if ieq(info.ccc,0) then index else end_of(left-1,data,source,iadd(index,1),count) end
fun walk{n:nat} .<n>. (left: int(n),data: !NormalizationData,mcm: !PropertyMap(9),source: !ScalarText,
  roles: !Buf,permutation: !Buf,counts: !Buf,index: int,count: int): void =
  if ige(index,count) then () else if left = 0 then let val failed=arabic_group_fuel_failed() in seen_int(failed) end else let
    val info=normalization_info(data,scalar_value(source,index))
    val finish=if ieq(info.ccc,0) then iadd(index,1) else end_of(airlock_nat(isub(count,index)),data,source,index,count)
    val ()=if ieq(info.ccc,0) then () else arabic_mark_classify(data,mcm,source,roles,permutation,counts,index,finish)
  in walk(left-1,data,mcm,source,roles,permutation,counts,finish,count) end
implement arabic_mark_groups(data,mcm,source,roles,permutation,counts) =
  let val count=scalar_count(source)
  in walk(airlock_nat(iadd(count,1)),data,mcm,source,roles,permutation,counts,0,count) end

