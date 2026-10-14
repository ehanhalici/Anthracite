#include "data_font/native_shape_internal.hats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_data.sats"
staload "data_text/arabic_marks_types.sats"
staload "data_text/arabic_marks_work.sats"
staload "data_font/native_shape_text_work.sats"
fun composition(b: !Buf,info: SfntInfo,data: !NormalizationData,left: int,right: int): int = let
  val a=normalization_info(data,left) and c=normalization_info(data,right)
in if ine(a.ccc,0) orelse ieq(c.ccc,0) then ~1 else let val cp=normalization_compose_pair(data,left,right)
  in if ilt(cp,0) orelse ieq(sfnt_map(b,info,cp),0) then ~1 else cp end end
fun united(a: ArabicMarkUnit,b: ArabicMarkUnit,cp: int): ArabicMarkUnit =
  @{scalar=cp,start=imin(a.start,b.start),finish=imax(a.finish,b.finish)}
fun emit(b: !Buf,info: SfntInfo,data: !NormalizationData,text: !ScalarText,index: int,output: int): int = let
  val unit=arabic_mark_unit(text,index)
in if ieq(output,0) then let val ()=arabic_mark_store(text,0,unit) in 1 end else let
    val previous=arabic_mark_unit(text,isub(output,1)) val cp=composition(b,info,data,previous.scalar,unit.scalar)
  in if ige(cp,0) then let val ()=arabic_mark_store(text,isub(output,1),united(previous,unit,cp)) in output end
    else let val ()=arabic_mark_store(text,output,unit) in iadd(output,1) end end end
fun walk{n:nat} .<n>. (left: int(n),b: !Buf,info: SfntInfo,data: !NormalizationData,text: !ScalarText,index: int,output: int): int =
  if left = 0 then output else let val next=emit(b,info,data,text,index,output)
  in walk(left-1,b,info,data,text,iadd(index,1),next) end
implement native_shape_text_compose(b,info,data,text) = let
  val count=walk(airlock_nat(scalar_count(text)),b,info,data,text,0,0)
  val+ ~ScalarText(values,starts,ends,old,errors)=text
in ScalarText(values,starts,ends,count,errors) end

