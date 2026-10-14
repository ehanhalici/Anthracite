#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/gsub_ligatures.sats"
staload "data_font/gsub_ligature_work.sats"
staload "data_font/ot_ligation_lookup_types.sats"
staload "data_font/ot_ligation_lookup_work.sats"
staload "data_font/ot_layout_lookup_header.sats"
fun payload(b: !Buf,h: OtLookupInfo(1),glyphs: int,i: int): GsubLigaturesRead = let
  val child=ot_optional_child(h.span,ot_u16(b,h.span,iadd(6,imul(i,2))),ot_lookup_header_floor(h))
in case+ child.kind of | ChildMissing() => LigaturesRejected(ot_error(OtBounds(),h.span))
  | ChildInvalid() => LigaturesRejected(ot_error(OtBounds(),h.span))
  | ChildPresent() => ot_ligation_payload(b,child.span,glyphs,h.action) end
fun append{n,i:nat | i < n}(info: GsubLigatureInfo,t: OtLigationTables(n,i),maximum: &int >> _): OtLigationTables(n,i+1) = let
  val ()=maximum := imax(maximum,info.maximum)
in ot_ligation_tables_append(t,info) end
fun read{n,i:nat | i <= n} .<n-i>. (b: !Buf,h: OtLookupInfo(1),glyphs: int,t: OtLigationTables(n,i),
  remaining: &int >> _,maximum: &int >> _): OtLigationTablesRead = let val+ OtLigationTables(rows,count,filled)=t
in if filled = count then LigationTablesAccepted(t) else case+ payload(b,h,glyphs,filled) of
  | ~LigaturesRejected(e) => let val ()=ot_ligation_tables_dispose(t) in LigationTablesRejected(e) end
  | ~LigaturesAccepted(table) => let val+ ~GsubLigatures(info)=table in
    if ot_ligation_charge(b,info,remaining) then read(b,h,glyphs,append(info,t,maximum),remaining,maximum)
    else let val ()=ot_ligation_tables_dispose(t) in LigationTablesRejected(ot_error(OtCapacity(),h.span)) end end end
implement ot_ligation_tables_read(b,h,glyphs,maximum) = let var remaining: int=MAX_REC_FUEL
in read(b,h,glyphs,ot_ligation_tables_make(airlock_nat(h.count)),remaining,maximum) end
