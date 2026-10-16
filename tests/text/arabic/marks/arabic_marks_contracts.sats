staload "mem.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/normalization/normalization_types.sats"
fun marks_test_words(source: string): Buf
fun marks_test_source(words: string): ScalarText
fun marks_test_case(data: !NormalizationData,mcm: !PropertyMap(9),source: string,want: string): int
fun marks_test_cases(data: !NormalizationData,mcm: !PropertyMap(9)): int
fun marks_test_stress(data: !NormalizationData,mcm: !PropertyMap(9)): int
fun marks_test_properties(mcm: !PropertyMap(9)): int
