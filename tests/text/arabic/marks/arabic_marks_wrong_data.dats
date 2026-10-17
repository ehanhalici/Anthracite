#include "data_text/arabic/marks/arabic_marks_internal.hats"
fun illegal(n: !NormalizationData,m: !PropertyMap(8),source: !ScalarText): ArabicMarkResult =
  arabic_marks_apply(n,m,source)
