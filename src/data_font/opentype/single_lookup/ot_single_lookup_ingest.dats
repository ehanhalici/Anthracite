#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_types.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_work.sats"
fun payload(b: !Buf,h: OtSingleHeader,glyphs: int,i: int): GsubSingleRead = let
  val child=ot_optional_child(h.span,ot_u16(b,h.span,iadd(6,imul(i,2))),h.floor)
in case+ child.kind of
  | ChildMissing() => SingleRejected(ot_error(OtBounds(),h.span))
  | ChildInvalid() => SingleRejected(ot_error(OtBounds(),h.span))
  | ChildPresent() => ot_single_payload(b,child.span,h.envelope,glyphs) end
fun read{n,i:nat | i <= n} .<n-i>. (b: !Buf,h: OtSingleHeader,glyphs: int,t: OtSingleTables(n,i)): OtSingleTablesRead = let
  val+ OtSingleTables(rows,count,filled)=t
in if filled = count then SingleTablesAccepted(t) else case+ payload(b,h,glyphs,filled) of
  | ~SingleRejected(e) => let val ()=ot_single_tables_dispose(t) in SingleTablesRejected(e) end
  | ~SingleAccepted(single) => let val+ ~GsubSingle(info)=single in
    read(b,h,glyphs,ot_single_tables_append(t,info)) end end
implement ot_single_tables_read(b,h,glyphs) = read(b,h,glyphs,ot_single_tables_make(airlock_nat(h.count)))
