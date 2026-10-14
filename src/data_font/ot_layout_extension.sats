staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
typedef OtExtensionInfo(kind:int) = @{span=OtSpan,action=OtLookupKind(kind)}
datavtype OtExtensionRead(kind:int) =
  | ExtensionAccepted(kind) of OtExtensionInfo(kind) | ExtensionRejected(kind) of OtError
(* Extension format 1 resolves a checked Offset32 and a non-extension kind.
   The returned target still needs its action-specific payload reader. *)
fun ot_extension_parse{kind:int}(b: !Buf,span: OtSpan,domain: OtLayoutDomain(kind)): OtExtensionRead(kind)
(* Every extension in one outer lookup must resolve to the same action.
   Header validation does not certify the resolved primitive payload. *)
fun ot_extension_lookup_validate{kind:int}(b: !Buf,span: OtSpan,domain: OtLayoutDomain(kind),
  count: int,floor: int): Option_vt(OtError)
fun ot_lookup_extension_validate{kind:int}(b: !Buf,span: OtSpan,action: OtLookupKind(kind),
  count: int,floor: int): Option_vt(OtError)
