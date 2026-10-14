staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gdef_types.sats"
(* Header and immediate offset validation only; this is not full GDEF parsing. *)
fun gdef_header_parse(b: !Buf,span: OtSpan): GdefHeaderRead
