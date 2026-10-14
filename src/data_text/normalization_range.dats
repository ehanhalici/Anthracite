#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_text/utf8.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_engine.sats"
fun decomposed(data: !NormalizationData,text: !ScalarText,start: int,finish: int,scope: DecompositionScope): NormalizationResult =
  case+ normalization_decompose_range(data,text,start,finish,scope) of
  | ~ExpansionRejected(e) => CannotNormalize(e)
  | ~ExpandedText(expanded) => NormalizedText(normalization_finish(normalization_order(data,expanded)))
fun composed(data: !NormalizationData,text: !ScalarText,start: int,finish: int,scope: DecompositionScope): NormalizationResult =
  case+ normalization_decompose_range(data,text,start,finish,scope) of
  | ~ExpansionRejected(e) => CannotNormalize(e)
  | ~ExpandedText(expanded) => NormalizedText(normalization_compose(data,normalization_order(data,expanded)))
implement normalization_apply_range(data,text,start,finish,form) = case+ form of
  | NFC() => composed(data,text,start,finish,CanonicalScope())
  | NFD() => decomposed(data,text,start,finish,CanonicalScope())
  | NFKC() => composed(data,text,start,finish,CompatibilityScope())
  | NFKD() => decomposed(data,text,start,finish,CompatibilityScope())
