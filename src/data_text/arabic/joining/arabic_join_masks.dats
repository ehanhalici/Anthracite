#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_text/arabic/joining/arabic_join.sats"
fun single(mask: uint): bool = if mask = 0u then true else (mask land (mask - 1u)) = 0u
fun disjoint(f: ArabicMaskFields): bool =
  (f.initial land (f.medial lor f.final lor f.isolated)) = 0u
  andalso (f.medial land (f.final lor f.isolated)) = 0u andalso (f.final land f.isolated) = 0u
implement arabic_mask_plan(f) =
  if not(single(f.initial) andalso single(f.medial) andalso single(f.final) andalso single(f.isolated))
  then ArabicMaskRejected(ArabicMaskMultipleBits()) else if not(disjoint(f)) then ArabicMaskRejected(ArabicMaskOverlap())
  else ArabicMaskAccepted(ArabicMaskPlan(@{fields=f,all=f.initial lor f.medial lor f.final lor f.isolated}))
implement arabic_mask_info(plan) = let val+ ArabicMaskPlan(info)=plan in info end
implement arabic_form_mask(plan,form) = let val+ ArabicMaskPlan(info)=plan in case+ form of
  | FormNone() => 0u | FormIsolated() => info.fields.isolated | FormInitial() => info.fields.initial
  | FormMedial() => info.fields.medial | FormFinal() => info.fields.final end
implement arabic_mask_dispose(plan) = let val+ ~ArabicMaskPlan(info)=plan in () end
