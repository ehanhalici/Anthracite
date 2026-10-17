staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/substitution/gsub_reverse_types.sats"
fun gsub_reverse_coverages{b,l:nat}(font: !Buf,info: GsubReverseInfo(b,l)): GsubReverseRead
fun gsub_reverse_fields{b,l:nat}(info: GsubReverseInfo(b,l)): Buf
