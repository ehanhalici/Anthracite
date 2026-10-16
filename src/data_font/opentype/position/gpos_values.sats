staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
fun ot_value_format(code: int): OtValueFormatRead
fun ot_value_field(format: OtValueFormat,field: OtValueField): int
fun ot_adjustment_absent(): OtAdjustment
fun ot_adjustment_parse(b: !Buf,parent: OtSpan,offset: int,floor: int): OtAdjustmentRead
fun ot_adjustment_sample(b: !Buf,value: OtAdjustment,ppem: int): OtPixelSample
(* at is relative to the immediate parent, NOT always the lookup subtable.
   For PairPos format 1 this is the PairSet table. floor covers all its records. *)
fun ot_value_parse(b: !Buf,parent: OtSpan,at: int,format: OtValueFormat,floor: int): OtValueRead
fun ot_value_zero(): OtValueInfo
fun ot_value_sample(b: !Buf,value: OtValueInfo,ppem: int): OtValueSample
fun ot_anchor_parse(b: !Buf,span: OtSpan): OtAnchorRead
(* A contour anchor is returned as a contour descriptor, not falsely resolved
   from the design coordinates: the outline/hinting owner supplies that point. *)
