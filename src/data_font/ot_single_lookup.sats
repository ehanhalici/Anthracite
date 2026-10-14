staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/ot_single_lookup_types.sats"
(* Payload-validated direct/extended GSUB type 1 lookup. Cached descriptors
   borrow the same immutable font bytes. GDEF dependencies and glyph eligibility
   belong to outer traversal, not this scalar, allocation-free candidate query. *)
fun ot_single_lookup_parse(b: !Buf,span: OtSpan,glyphs: int): OtSingleLookupRead
fun ot_single_lookup_query(b: !Buf,lookup: !OtSingleLookup,glyph: int): GsubSingleResult
fun ot_single_lookup_header(lookup: !OtSingleLookup): OtSingleHeader
fun ot_single_lookup_glyphs(lookup: !OtSingleLookup): int
fun ot_single_lookup_dispose(lookup: OtSingleLookup): void
