staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
(* Immutable font bytes must outlive this owner. GPOS 1..6 and uniform
   extension lookup 9 are executable; 7/8 fail explicitly, never fall through. *)
fun ot_position_lookup_parse(b: !Buf,span: OtSpan,glyphs: int): OtPositionLookupRead
fun ot_position_lookup_info(lookup: !OtPositionLookup): OtLookupInfo(2)
fun ot_position_lookup_action(lookup: !OtPositionLookup): OtLookupKind(2)
fun ot_position_lookup_glyphs(lookup: !OtPositionLookup): int
fun ot_position_lookup_dispose(lookup: OtPositionLookup): void
