staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_sequence_types.sats"
staload "data_font/ot_sequence_lookup_types.sats"
(* Direct and uniformly extended GSUB 2/3. Descriptors borrow immutable font
   bytes. Querying never reboxes payloads or reparses their headers. *)
fun ot_sequence_lookup_parse{kind:int}(b: !Buf,span: OtSpan,glyphs: int,
  domain: GsubSequenceDomain(kind)): OtSequenceLookupRead(kind)
fun ot_multiple_lookup_query(b: !Buf,lookup: !OtSequenceLookup(2),glyph: int): GsubSequenceView
(* Stop on actual selection, not merely Coverage: a prior short or empty set
   can decline this choice, allowing a later subtable to apply it. *)
fun ot_alternate_lookup_query(b: !Buf,lookup: !OtSequenceLookup(3),glyph: int,choice: int): GsubSingleResult
fun ot_sequence_lookup_header{kind:int}(lookup: !OtSequenceLookup(kind)): OtLookupInfo(1)
fun ot_sequence_lookup_glyphs{kind:int}(lookup: !OtSequenceLookup(kind)): int
fun ot_sequence_lookup_dispose{kind:int}(lookup: OtSequenceLookup(kind)): void
