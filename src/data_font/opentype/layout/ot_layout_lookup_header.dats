#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/tables/opentype_lookup_flags.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_lookups.sats"
staload "data_font/opentype/layout/ot_layout_lookup_header.sats"
implement ot_lookup_header_floor(h) = iadd(iadd(6,imul(h.count,2)),if h.flags.useMarkSet then 2 else 0)
fun flagged{kind:int}(b: !Buf,s: OtSpan,a: OtLookupKind(kind),f: OtLookupFlags): OtLookupHeaderRead(kind) = let
  val count=ot_u16(b,s,4)
  val floor=iadd(iadd(6,imul(count,2)),if f.useMarkSet then 2 else 0)
in if igt(floor,s.length) then LookupHeaderRejected(ot_error(OtBounds(),s)) else
  LookupHeaderAccepted(@{span=s,action=a,flags=f,count=count,
    markSet=if f.useMarkSet then ot_u16(b,s,isub(floor,2)) else 0}) end
fun action{kind:int}(b: !Buf,s: OtSpan,a: OtLookupKind(kind)): OtLookupHeaderRead(kind) =
  case+ ot_lookup_flags_of(ot_u16(b,s,2)) of
  | ~FlagsRejected(reason) => LookupHeaderRejected(ot_error(reason,s))
  | ~FlagsAccepted(f) => flagged(b,s,a,f)
implement ot_lookup_header_parse(b,s,domain) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,6) then LookupHeaderRejected(ot_error(OtBounds(),s))
  else case+ ot_lookup_kind_of(domain,ot_u16(b,s,0)) of
  | ~None_vt() => LookupHeaderRejected(ot_error(OtUnsupported(),s))
  | ~Some_vt(a) => action(b,s,a)
