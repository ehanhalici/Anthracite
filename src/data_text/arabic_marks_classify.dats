#include "data_text/arabic_marks_internal.hats"
fun classify{n:nat} .<n>. (left: int(n),data: !NormalizationData,mcm: !PropertyMap(9),source: !ScalarText,
  roles: !Buf,counts: !Buf,index: int,state: ArabicMarkState): void =
  if left = 0 then () else let
    val cp=scalar_value(source,index) val info=normalization_info(data,cp)
    val step=arabic_mark_step(state,info.ccc,ieq(property_value(mcm,cp),1))
    val role=arabic_mark_role_code(step.role)
    val ()=buf_set(roles,index,role) and ()=buf_set32(counts,role,iadd(buf_get32(counts,role),1))
  in classify(left-1,data,mcm,source,roles,counts,iadd(index,1),step.state) end
fun offsets{n:nat} .<n>. (left: int(n),counts: !Buf,index: int,offset: int): void =
  if left = 0 then () else let val count=buf_get32(counts,index) val ()=buf_set32(counts,index,offset)
  in offsets(left-1,counts,iadd(index,1),iadd(offset,count)) end
fun scatter{n:nat} .<n>. (left: int(n),roles: !Buf,permutation: !Buf,counts: !Buf,index: int): void =
  if left = 0 then () else let val role=buf_get(roles,index) val position=buf_get32(counts,role)
    val ()=buf_set32(permutation,index,position) and ()=buf_set32(counts,role,iadd(position,1))
  in scatter(left-1,roles,permutation,counts,iadd(index,1)) end
implement arabic_mark_classify(data,mcm,source,roles,permutation,counts,start,finish) = let
  val count=airlock_nat(isub(finish,start)) val ()=buf_zero(counts)
  val ()=classify(count,data,mcm,source,roles,counts,start,@{ccc=0,gate=MarkPrefixOpen()})
  val ()=offsets(4,counts,0,start)
in scatter(count,roles,permutation,counts,start) end
