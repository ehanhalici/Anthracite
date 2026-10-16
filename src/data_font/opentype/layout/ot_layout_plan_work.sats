staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
fun ot_plan_selection(b: !Buf,info: OtLayoutInfo,language: OtChild,set: !OtFeatureSet): Buf
fun ot_plan_selection_requested(b: !Buf,info: OtLayoutInfo,language: OtChild,set: !OtFeatureSet): Buf
fun ot_plan_reference_cost(b: !Buf,info: OtLayoutInfo,selected: !Buf): int
fun ot_plan_count_edges(b: !Buf,info: OtLayoutInfo,selected: !Buf,counts: !Buf,seen: !Buf): int
fun ot_plan_prefix(counts: !Buf,offsets: !Buf,n: int): int
fun ot_plan_fill(b: !Buf,info: OtLayoutInfo,selected: !Buf,cursors: !Buf,seen: !Buf,owners: !Buf): void
fun ot_plan_lookup_ids(counts: !Buf,ids: !Buf,n: int): int
