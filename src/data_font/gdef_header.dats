#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gdef_types.sats"
staload "data_font/gdef_header.sats"

fun version_of(code: int): Option_vt(GdefVersion) = case+ code of
  | 0 => Some_vt(Gdef10()) | 2 => Some_vt(Gdef12()) | 3 => Some_vt(Gdef13()) | _ => None_vt()
fun header_bytes(v: GdefVersion): int = case+ v of
  | Gdef10() => 12 | Gdef12() => 14 | Gdef13() => 18
fun marks_offset(b: !Buf,s: OtSpan,v: GdefVersion): int = case+ v of
  | Gdef10() => 0 | Gdef12() => ot_u16(b,s,12) | Gdef13() => ot_u16(b,s,12)
fun variations_offset(b: !Buf,s: OtSpan,v: GdefVersion): int = case+ v of
  | Gdef10() => 0 | Gdef12() => 0 | Gdef13() => ot_u32(b,s,14)

fun descriptor(b: !Buf,s: OtSpan,v: GdefVersion): GdefHeaderInfo = let val floor=header_bytes(v) in
  @{span=s,version=v,classes=ot_optional_child(s,ot_u16(b,s,4),floor),
    attach=ot_optional_child(s,ot_u16(b,s,6),floor),
    carets=ot_optional_child(s,ot_u16(b,s,8),floor),
    markAttach=ot_optional_child(s,ot_u16(b,s,10),floor),
    markSets=ot_optional_child(s,marks_offset(b,s,v),floor),
    variations=ot_optional_child(s,variations_offset(b,s,v),floor)} end

fun offsets_valid(h: GdefHeaderInfo): bool =
  ot_child_valid(h.classes) andalso ot_child_valid(h.attach) andalso ot_child_valid(h.carets)
  andalso ot_child_valid(h.markAttach) andalso ot_child_valid(h.markSets) andalso ot_child_valid(h.variations)

fun parse_version(b: !Buf,s: OtSpan,v: GdefVersion): GdefHeaderRead =
  if ilt(s.length,header_bytes(v)) then GdefHeaderRejected(ot_error(OtBounds(),s)) else let
    val header=descriptor(b,s,v)
  in if offsets_valid(header) then GdefHeaderAccepted(header)
    else GdefHeaderRejected(ot_error(OtBounds(),s)) end

implement gdef_header_parse(b,s) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,12) then GdefHeaderRejected(ot_error(OtBounds(),s))
  else if ine(ot_u16(b,s,0),1) then GdefHeaderRejected(ot_error(OtFormat(),s)) else
    case+ version_of(ot_u16(b,s,2)) of
    | ~None_vt() => GdefHeaderRejected(ot_error(OtFormat(),s))
    | ~Some_vt(v) => parse_version(b,s,v)
