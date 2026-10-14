staload "mem.sats"
staload "data_text/utf8.sats"
staload "data_text/normalization_types.sats"
staload "data_text/unicode_property.sats"
staload "data_text/arabic_marks_types.sats"
fun arabic_mark_step(state: ArabicMarkState,ccc: int,modifier: bool): ArabicMarkStep
fun arabic_mark_role_code(role: ArabicMarkRole): int
fun arabic_mark_role_of(code: int): ArabicMarkRole
fun arabic_mark_unit(source: !ScalarText,index: int): ArabicMarkUnit
fun arabic_mark_store(source: !ScalarText,index: int,unit: ArabicMarkUnit): void
fun arabic_mark_initialize(permutation: !Buf,count: int): void
fun arabic_mark_groups(data: !NormalizationData,mcm: !PropertyMap(9),source: !ScalarText,
  roles: !Buf,permutation: !Buf,counts: !Buf): void
fun arabic_mark_permute(source: !ScalarText,permutation: !Buf): void
fun arabic_mark_classify(data: !NormalizationData,mcm: !PropertyMap(9),source: !ScalarText,
  roles: !Buf,permutation: !Buf,counts: !Buf,start: int,finish: int): void

