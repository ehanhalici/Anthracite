#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"

fun list_valid {n:nat} .<n>. (n: int(n),b: !Buf,s: OtSpan,i: int,previous: int,glyphs: int): bool =
  if n = 0 then true else let val gid=ot_u16(b,s,iadd(4,imul(i,2))) in
    if ile(gid,previous) orelse ige(gid,glyphs) then false
    else list_valid(n-1,b,s,iadd(i,1),gid,glyphs) end

fun parse_list(b: !Buf,s: OtSpan,count: int,glyphs: int): OtCoverageRead =
  if not(ot_rows_fit(s,4,count,2)) then CoverageRejected(ot_error(OtBounds(),s))
  else if not(list_valid(airlock_nat(count),b,s,0,~1,glyphs)) then CoverageRejected(ot_error(OtOrder(),s))
  else CoverageAccepted(@{span=s,encoding=OtList(),count=count,total=count})

fun ranges_count {n:nat} .<n>. (n: int(n),b: !Buf,s: OtSpan,i: int,
  previous: int,total: int,glyphs: int): int =
  if n = 0 then total else let val row=ot_range(b,s,i) in
    if ile(row.first,previous) orelse ilt(row.last,row.first) orelse ige(row.last,glyphs) then ~1
    else if ine(row.value,total) then ~2
    else ranges_count(n-1,b,s,iadd(i,1),row.last,iadd(total,iadd(isub(row.last,row.first),1)),glyphs) end

fun parse_ranges(b: !Buf,s: OtSpan,count: int,glyphs: int): OtCoverageRead =
  if not(ot_rows_fit(s,4,count,6)) then CoverageRejected(ot_error(OtBounds(),s)) else let
    val total=ranges_count(airlock_nat(count),b,s,0,~1,0,glyphs)
  in if ieq(total,~1) then CoverageRejected(ot_error(OtOrder(),s))
    else if ieq(total,~2) then CoverageRejected(ot_error(OtCoverageIndex(),s))
    else CoverageAccepted(@{span=s,encoding=OtRanges(),count=count,total=total}) end

fun parse_encoding(b: !Buf,s: OtSpan,glyphs: int): OtCoverageRead =
  case+ ot_encoding_of(ot_u16(b,s,0)) of
  | ~None_vt() => CoverageRejected(ot_error(OtFormat(),s))
  | ~Some_vt(encoding) => case+ encoding of
    | OtList() => parse_list(b,s,ot_u16(b,s,2),glyphs)
    | OtRanges() => parse_ranges(b,s,ot_u16(b,s,2),glyphs)

implement ot_coverage_parse(b,s,glyphs) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,4) then CoverageRejected(ot_error(OtBounds(),s))
  else if not(ot_glyph_domain_valid(glyphs)) then CoverageRejected(ot_error(OtGlyphDomain(),s))
  else parse_encoding(b,s,glyphs)
