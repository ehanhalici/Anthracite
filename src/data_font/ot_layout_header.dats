#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_header.sats"
staload "data_font/ot_layout_records.sats"

fun required(b: !Buf,s: OtSpan,field: int,floor: int): OtChild =
  ot_optional_child(s,ot_u16(b,s,field),floor)
fun available(c: OtChild): bool = case+ c.kind of
  | ChildPresent() => ige(c.span.length,2) | ChildMissing() => false | ChildInvalid() => false

fun missing_child(): OtChild =
  @{kind=ChildMissing(),span= @{offset=0,length=0}}

fun descriptor(b: !Buf,s: OtSpan,scripts: OtChild,features: OtChild,lookups: OtChild,variations: OtChild): OtLayoutInfo =
  @{span=s,scripts=ot_record_list(b,scripts.span,2),features=ot_record_list(b,features.span,2),
    lookups=lookups.span,lookupCount=ot_u16(b,lookups.span,0),variations=variations}

fun parse_offsets(b: !Buf,s: OtSpan,floor: int,variations: OtChild): OtLayoutHeaderRead = let
  val scripts=required(b,s,4,floor)
  val features=required(b,s,6,floor)
  val lookups=required(b,s,8,floor)
in if available(scripts) andalso available(features) andalso available(lookups)
  then HeaderAccepted(descriptor(b,s,scripts,features,lookups,variations)) else HeaderRejected(ot_error(OtBounds(),s)) end

fun version_one(b: !Buf,s: OtSpan): OtLayoutHeaderRead =
  if ilt(s.length,14) then HeaderRejected(ot_error(OtBounds(),s))
  else let
    val vchild = ot_optional_child(s,ot_u32(b,s,10),14)
  in if not(ot_child_valid(vchild)) then HeaderRejected(ot_error(OtBounds(),s))
    else parse_offsets(b,s,14,vchild) end

implement ot_layout_header_parse(b,s) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,10) then HeaderRejected(ot_error(OtBounds(),s))
  else if ine(ot_u16(b,s,0),1) then HeaderRejected(ot_error(OtFormat(),s))
  else case+ ot_u16(b,s,2) of
    | 0 => parse_offsets(b,s,10,missing_child()) | 1 => version_one(b,s)
    | _ => HeaderRejected(ot_error(OtFormat(),s))
