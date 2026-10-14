#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gsub_sequence_types.sats"
staload "data_font/opentype_glyphs.sats"
staload "data_font/ot_layout_work.sats"
staload "data_font/gsub_sequence_work.sats"
implement gsub_sequence_child(b,info,index) = ot_optional_child(info.span,
  ot_u16(b,info.span,iadd(6,imul(index,2))),iadd(6,imul(info.count,2)))
fun count_valid{kind:int}(domain: GsubSequenceDomain(kind),count: int): bool = case+ domain of
  | GsubMultiple() => igt(count,0) | GsubAlternate() => true
fun sequence{kind:int}(b: !Buf,s: OtSpan,glyphs: int,domain: GsubSequenceDomain(kind),
  remaining: &int >> _): Option_vt(OtError) =
  if ilt(s.length,2) then Some_vt(ot_error(OtBounds(),s)) else let val count=ot_u16(b,s,0) in
    if not(ot_rows_fit(s,2,count,2)) then Some_vt(ot_error(OtBounds(),s))
    else if not(count_valid(domain,count)) then Some_vt(ot_error(OtFormat(),s))
    else if not(ot_layout_charge(remaining,iadd(count,1))) then Some_vt(ot_error(OtCapacity(),s))
    else if not(ot_glyph_array_valid(b,s,2,count,glyphs)) then Some_vt(ot_error(OtGlyphDomain(),s))
    else None_vt() end
fun sequences {n:nat}{kind:int} .<n>. (n: int(n),b: !Buf,info: GsubSequenceInfo,
  domain: GsubSequenceDomain(kind),remaining: &int >> _,index: int): Option_vt(OtError) =
  if n = 0 then None_vt() else let val child=gsub_sequence_child(b,info,index) in
    case+ child.kind of
    | ChildMissing() => Some_vt(ot_error(OtBounds(),info.span))
    | ChildInvalid() => Some_vt(ot_error(OtBounds(),info.span))
    | ChildPresent() => case+ sequence(b,child.span,info.glyphs,domain,remaining) of
      | ~Some_vt(e) => Some_vt(e)
      | ~None_vt() => sequences(n-1,b,info,domain,remaining,iadd(index,1)) end
implement gsub_sequences_validate(b,info,domain,remaining) =
  if not(ot_layout_charge(remaining,info.count)) then Some_vt(ot_error(OtCapacity(),info.span))
  else sequences(airlock_nat(info.count),b,info,domain,remaining,0)
