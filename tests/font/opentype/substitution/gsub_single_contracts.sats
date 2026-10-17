staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
fun single_expect(b: !Buf,s: OtSpan,glyphs: int,input: int,output: int): int
fun single_reject(b: !Buf,s: OtSpan,glyphs: int): int
fun single_test_formats(): int
fun single_test_mutations(): int
fun single_test_stress(): int
datatype SingleTestFont = SingleLatin | SingleArabic
fun single_test_font(path: string,font: SingleTestFont): int
fun single_font_oracle(font: SingleTestFont): Buf
