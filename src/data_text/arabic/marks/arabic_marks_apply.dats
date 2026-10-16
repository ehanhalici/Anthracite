#include "data_text/arabic/marks/arabic_marks_internal.hats"
fun reordered(data: !NormalizationData,mcm: !PropertyMap(9),source: ScalarText): ArabicMarkResult = let
  val count=scalar_count(source)
in if igt(count,idiv(isub(MAX_REC_FUEL,16),5)) then let val ()=scalar_dispose(source)
  in ArabicMarksRejected(@{reason=NormLengthReason(),detail=count}) end else let
    val roles=buf_make(count) and permutation=buf_make(imul(count,4)) and counts=buf_make(16)
    val ()=arabic_mark_initialize(permutation,count)
    val ()=arabic_mark_groups(data,mcm,source,roles,permutation,counts)
    val ()=arabic_mark_permute(source,permutation)
    val ()=buf_free(roles) and ()=buf_free(permutation) and ()=buf_free(counts)
  in ArabicMarksReady(source) end end
implement arabic_marks_apply(data,mcm,source) = arabic_marks_apply_range(data,mcm,source,0,scalar_count(source))
implement arabic_marks_apply_range(data,mcm,source,start,finish) = case+ normalization_apply_range(data,source,start,finish,NFD()) of
  | ~CannotNormalize(e) => ArabicMarksRejected(e) | ~NormalizedText(nfd) => reordered(data,mcm,nfd)
