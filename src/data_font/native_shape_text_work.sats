staload "mem.sats"
staload "data_font/sfnt.sats"
staload "data_text/utf8.sats"
staload "data_text/normalization_types.sats"
fun native_shape_text_compose(b: !Buf,info: SfntInfo,data: !NormalizationData,text: ScalarText): ScalarText

