#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_work.sats"
staload "data_font/opentype/layout/ot_layout_lookup_header.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_work.sats"
fun payload{kind:int}(b: !Buf,h: OtLookupInfo(1),glyphs: int,d: GsubSequenceDomain(kind),
  i: int,remaining: &int >> _): GsubSequencesRead(kind) = let
  val child=ot_optional_child(h.span,ot_u16(b,h.span,iadd(6,imul(i,2))),ot_lookup_header_floor(h))
in case+ child.kind of
  | ChildMissing() => SequencesRejected(ot_error(OtBounds(),h.span))
  | ChildInvalid() => SequencesRejected(ot_error(OtBounds(),h.span))
  | ChildPresent() => ot_sequence_payload(b,child.span,h.action,glyphs,d,remaining) end
fun read{n,i:nat | i <= n}{kind:int} .<n-i>. (b: !Buf,h: OtLookupInfo(1),glyphs: int,
  d: GsubSequenceDomain(kind),t: OtSequenceTables(n,i),remaining: &int >> _): OtSequenceTablesRead = let
  val+ OtSequenceTables(rows,count,filled)=t
in if filled = count then SequenceTablesAccepted(t) else case+ payload(b,h,glyphs,d,filled,remaining) of
  | ~SequencesRejected(e) => let val ()=ot_sequence_tables_dispose(t) in SequenceTablesRejected(e) end
  | ~SequencesAccepted(single) => let val+ ~GsubSequences(info)=single in
    read(b,h,glyphs,d,ot_sequence_tables_append(t,info),remaining) end end
implement ot_sequence_tables_read(b,h,glyphs,d) = let var remaining: int=MAX_REC_FUEL
  val charged=ot_layout_charge(remaining,iadd(h.count,1))
in if not(charged) then SequenceTablesRejected(ot_error(OtCapacity(),h.span))
  else read(b,h,glyphs,d,ot_sequence_tables_make(airlock_nat(h.count)),remaining) end
