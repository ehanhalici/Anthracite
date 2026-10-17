staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/definition/gdef_types.sats"
fun ot_lookup_flags_of(code: int): OtFlagsRead
(* Context matchers accept an already eligible current glyph and use this
   filter for neighbours. Outer lookup traversal must ALSO filter the current
   glyph before testing coverage. RTL does not determine text direction. *)
fun ot_lookup_skips_context(flags: OtLookupFlags,kind: GdefGlyphKind,attachment: int,member: bool): bool
