#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_hangul.sats"

implement normalization_hangul_syllable(cp) = ige(cp,44032) andalso ilt(cp,55204)

implement normalization_hangul_parts(cp) =
  if not(normalization_hangul_syllable(cp)) then @{first=cp,second=0,third=0,count=0} else let
    val index = isub(cp,44032)
    val trailing = imod(index,28)
    val leading = iadd(4352,idiv(index,588))
    val vowel = iadd(4449,idiv(imod(index,588),28))
  in @{first=leading,second=vowel,third=iadd(4519,trailing),count=(if ieq(trailing,0) then 2 else 3)} end

implement normalization_hangul_compose(left,right) =
  if ige(left,4352) andalso ilt(left,4371) andalso ige(right,4449) andalso ilt(right,4470) then
    iadd(44032,imul(iadd(imul(isub(left,4352),21),isub(right,4449)),28))
  else if ige(left,44032) andalso ilt(left,55204) andalso ieq(imod(isub(left,44032),28),0)
    andalso igt(right,4519) andalso ilt(right,4547) then iadd(left,isub(right,4519))
  else ~1

implement normalization_leaf_info(cp) = let
  val parts = normalization_hangul_parts(cp)
  val size = if ieq(parts.count,0) then 1 else parts.count
in @{cp=cp,ccc=0,kind=NoMapping(),offset=0,count=0,depth=(if ieq(parts.count,0) then 0 else 1),
    canonical=size,compatibility=size,excluded=false} end
