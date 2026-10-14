staload "mem.sats"
staload "data_text/utf8.sats"

datatype NormalizationForm = NFC | NFD | NFKC | NFKD
datatype DecompositionScope = CanonicalScope | CompatibilityScope
datatype DecompositionKind = NoMapping | CanonicalMapping | CompatibilityMapping
datatype NormalizationErrorReason = NormIoReason | NormHeaderReason | NormRangesReason | NormGraphReason | NormSourceReason | NormLengthReason
typedef NormalizationError = @{reason=NormalizationErrorReason, detail=int}

typedef NormalizationHeader = @{rows=int, mappings=int, pairs=int, expansion=int, depth=int}
typedef NormalizationRow = @{
  cp=int, ccc=int, kind=DecompositionKind, offset=int, count=int,
  depth=int, canonical=int, compatibility=int, excluded=bool
}
datavtype NormalizationData = NormalizationData of (Buf, NormalizationHeader)
datavtype NormalizationLoad = NormalizationLoaded of NormalizationData | NormalizationRejected of NormalizationError
(* The order/composition call order is checked statically, without new assumes. *)
datavtype NormalText(int) = {phase:int} NormalText(phase) of (Buf, Buf, Buf, int, int)

macdef NORMALIZATION_MAGIC = 1096110670
macdef NORMALIZATION_VERSION = 180000
macdef NORMALIZATION_HEADER_WORDS = 8
macdef NORMALIZATION_ROW_WORDS = 9
