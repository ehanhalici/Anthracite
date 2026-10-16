staload "mem.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/normalization/normalization_types.sats"
fun native_shape_text_compose(b: !Buf,info: SfntInfo,data: !NormalizationData,text: ScalarText): ScalarText
