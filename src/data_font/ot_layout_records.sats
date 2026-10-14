staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
fun ot_record_tag(b: !Buf,records: OtRecordList,index: int): OtTag
fun ot_record_child(b: !Buf,records: OtRecordList,index: int): OtChild
fun ot_records_unique(b: !Buf,records: OtRecordList): bool
fun ot_records_repeated(b: !Buf,records: OtRecordList): bool
fun ot_record_find(b: !Buf,records: OtRecordList,tag: OtTag): OtIndex
fun ot_record_list(b: !Buf,span: OtSpan,header: int): OtRecordList
