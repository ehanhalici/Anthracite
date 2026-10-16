#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
staload "data_font/opentype/tables/opentype_glyphs.sats"
staload "data_font/opentype/layout/ot_layout_work.sats"
staload "data_font/opentype/substitution/gsub_ligature_work.sats"
fun rule(b: !Buf,s: OtSpan,glyphs: int,remaining: &int >> _): Option_vt(OtError) =
  if ilt(s.length,4) then Some_vt(ot_error(OtBounds(),s)) else let val count=ot_u16(b,s,2) in
    if ieq(count,0) then Some_vt(ot_error(OtFormat(),s))
    else if not(ot_rows_fit(s,4,isub(count,1),2)) then Some_vt(ot_error(OtBounds(),s))
    else if not(ot_layout_charge(remaining,count)) then Some_vt(ot_error(OtCapacity(),s))
    else if ige(ot_u16(b,s,0),glyphs) orelse not(ot_glyph_array_valid(b,s,4,isub(count,1),glyphs))
      then Some_vt(ot_error(OtGlyphDomain(),s)) else None_vt() end
fun rules {n:nat} .<n>. (n: int(n),b: !Buf,s: OtSpan,glyphs: int,remaining: &int >> _,i: int): Option_vt(OtError) =
  if n = 0 then None_vt() else let val child=gsub_ligature_rule(b,s,i) in
    case+ child.kind of
    | ChildMissing() => Some_vt(ot_error(OtBounds(),s))
    | ChildInvalid() => Some_vt(ot_error(OtBounds(),s))
    | ChildPresent() => case+ rule(b,child.span,glyphs,remaining) of
      | ~Some_vt(e) => Some_vt(e) | ~None_vt() => rules(n-1,b,s,glyphs,remaining,iadd(i,1)) end
fun set(b: !Buf,s: OtSpan,glyphs: int,remaining: &int >> _): Option_vt(OtError) =
  if ilt(s.length,2) then Some_vt(ot_error(OtBounds(),s)) else let val count=ot_u16(b,s,0) in
    if not(ot_rows_fit(s,2,count,2)) then Some_vt(ot_error(OtBounds(),s))
    else if not(ot_layout_charge(remaining,iadd(count,1))) then Some_vt(ot_error(OtCapacity(),s))
    else rules(airlock_nat(count),b,s,glyphs,remaining,0) end
fun sets {n:nat} .<n>. (n: int(n),b: !Buf,info: GsubLigatureInfo,remaining: &int >> _,i: int): Option_vt(OtError) =
  if n = 0 then None_vt() else let val child=gsub_ligature_set(b,info,i) in
    case+ child.kind of
    | ChildMissing() => Some_vt(ot_error(OtBounds(),info.span))
    | ChildInvalid() => Some_vt(ot_error(OtBounds(),info.span))
    | ChildPresent() => case+ set(b,child.span,info.glyphs,remaining) of
      | ~Some_vt(e) => Some_vt(e) | ~None_vt() => sets(n-1,b,info,remaining,iadd(i,1)) end
implement gsub_ligatures_validate(b,info,remaining) =
  if not(ot_layout_charge(remaining,info.count)) then Some_vt(ot_error(OtCapacity(),info.span))
  else sets(airlock_nat(info.count),b,info,remaining,0)
