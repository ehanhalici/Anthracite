#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_text/arabic/joining/arabic_join.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "text/arabic/joining/arabic_join_contracts.sats"
fun rejected(fields: ArabicMaskFields): int = case+ arabic_mask_plan(fields) of
  | ~ArabicMaskRejected(e) => 0 | ~ArabicMaskAccepted(p) => let val ()=arabic_mask_dispose(p) in 1 end
fun accepted(fields: ArabicMaskFields): int = case+ arabic_mask_plan(fields) of
  | ~ArabicMaskRejected(e) => 1 | ~ArabicMaskAccepted(p) => let
    val ok=arabic_form_mask(p,FormInitial()) = fields.initial andalso arabic_form_mask(p,FormMedial()) = fields.medial
      andalso arabic_form_mask(p,FormFinal()) = fields.final andalso arabic_form_mask(p,FormIsolated()) = fields.isolated
      andalso arabic_form_mask(p,FormNone()) = 0u
    val ()=arabic_mask_dispose(p)
  in if ok then 0 else 1 end
fun boundary(): int = case+ arabic_boundary_of(JoinTransparent()) of
  | ~None_vt() => 0 | ~Some_vt(b) => 1
implement arabic_test_masks() = boundary()+
  accepted(@{initial=0u,medial=0u,final=0u,isolated=0u})+
  accepted(@{initial=2147483648u,medial=1u,final=2u,isolated=4u})+
  rejected(@{initial=1u,medial=1u,final=4u,isolated=8u})+
  rejected(@{initial=3u,medial=4u,final=8u,isolated=16u})+
  rejected(@{initial=1u,medial=2u,final=4u,isolated=4u})
