staload "mem.sats"
staload "data_text/utf8.sats"
staload "data_text/normalization_types.sats"

datavtype NormalizationExpansion = ExpandedText of NormalText(0) | ExpansionRejected of NormalizationError
datavtype NormalizationResult = NormalizedText of ScalarText | CannotNormalize of NormalizationError
fun normalization_expanded_count(data: !NormalizationData, text: !ScalarText, scope: DecompositionScope): int
fun normalization_decompose(data: !NormalizationData, text: !ScalarText, scope: DecompositionScope): NormalizationExpansion
fun normalization_order(data: !NormalizationData, text: NormalText(0)): NormalText(1)
fun normalization_compose(data: !NormalizationData, text: NormalText(1)): ScalarText
fun normalization_finish(text: NormalText(1)): ScalarText
fun normalization_apply(data: !NormalizationData, text: !ScalarText, form: NormalizationForm): NormalizationResult
(* Half-open scalar range in the borrowed source. Only the normalization
   output is allocated; no intermediate scalar or UTF-8 copy is created.
   Original byte spans and the source's aggregate decode-error count survive. *)
fun normalization_apply_range(data: !NormalizationData,text: !ScalarText,start: int,finish: int,form: NormalizationForm): NormalizationResult
fun normalization_decompose_range(data: !NormalizationData,text: !ScalarText,start: int,finish: int,scope: DecompositionScope): NormalizationExpansion
fun normalization_expanded_count_range(data: !NormalizationData,text: !ScalarText,start: int,finish: int,scope: DecompositionScope): int
