staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
(* Remaining reference work is a numeric capacity, not a processing mode. *)
fun ot_layout_charge(remaining: &int >> _,count: int): bool
fun ot_language_work(b: !Buf,span: OtSpan,features: int,remaining: &int >> _): Option_vt(OtError)
fun ot_features_work(b: !Buf,info: OtLayoutInfo,remaining: &int >> _): Option_vt(OtError)
fun ot_scripts_work(b: !Buf,info: OtLayoutInfo,remaining: &int >> _): Option_vt(OtError)
fun ot_lookups_work{kind:int}(b: !Buf,info: OtLayoutInfo,domain: OtLayoutDomain(kind),
  caps: OtGdefCapabilities,remaining: &int >> _): Option_vt(OtError)
