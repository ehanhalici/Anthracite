#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_engine.sats"

fun decomposed(data: !NormalizationData, text: !ScalarText, scope: DecompositionScope): NormalizationResult =
  case+ normalization_decompose(data,text,scope) of
  | ~ExpansionRejected(error) => CannotNormalize(error)
  | ~ExpandedText(expanded) => let
      val ordered = normalization_order(data,expanded)
    in NormalizedText(normalization_finish(ordered)) end

fun composed(data: !NormalizationData, text: !ScalarText, scope: DecompositionScope): NormalizationResult =
  case+ normalization_decompose(data,text,scope) of
  | ~ExpansionRejected(error) => CannotNormalize(error)
  | ~ExpandedText(expanded) => let
      val ordered = normalization_order(data,expanded)
    in NormalizedText(normalization_compose(data,ordered)) end

implement normalization_apply(data,text,form) = case+ form of
  | NFC() => composed(data,text,CanonicalScope())
  | NFD() => decomposed(data,text,CanonicalScope())
  | NFKC() => composed(data,text,CompatibilityScope())
  | NFKD() => decomposed(data,text,CompatibilityScope())
