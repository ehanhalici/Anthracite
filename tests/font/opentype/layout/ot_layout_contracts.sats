staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
fun layout_fixture(): Buf
fun layout_bytes(s: string): Buf
fun layout_tag(s: string): OtTag
fun layout_accept{kind:int}(b: !Buf,domain: OtLayoutDomain(kind),caps: OtGdefCapabilities): int
fun layout_reject{kind:int}(b: !Buf,span: OtSpan,domain: OtLayoutDomain(kind),caps: OtGdefCapabilities): int
fun layout_test_structure(): int
fun layout_test_selection(): int
fun layout_test_flags(): int
fun layout_test_sets(): int
fun layout_test_capacity(): int
fun layout_test_stress(): int
fun layout_test_fallback(): int
fun layout_test_extensions(): int
fun layout_test_stages(): int
fun layout_test_params(): int
datatype LayoutTestFont = LayoutLatin | LayoutArabic
fun layout_test_font(path: string,font: LayoutTestFont): int
fun layout_font_script(font: LayoutTestFont): OtTag
fun layout_font_plan_check{kind:int}(plan: !OtStagePlan(kind),font: LayoutTestFont,domain: OtLayoutDomain(kind)): int
