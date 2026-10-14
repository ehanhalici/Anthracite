#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_classdef.sats"

fun list_maximum {n:nat} .<n>. (n: int(n),b: !Buf,s: OtSpan,i: int,maximum: int): int =
  if n = 0 then maximum else let val value=ot_u16(b,s,iadd(6,imul(i,2))) in
    list_maximum(n-1,b,s,iadd(i,1),imax(maximum,value)) end

fun parse_list(b: !Buf,s: OtSpan,glyphs: int): OtClassRead =
  if ilt(s.length,6) then ClassRejected(ot_error(OtBounds(),s)) else let
  val first=ot_u16(b,s,2)
  val count=ot_u16(b,s,4)
in if not(ot_rows_fit(s,6,count,2)) then ClassRejected(ot_error(OtBounds(),s))
  else if igt(first,glyphs) orelse igt(count,isub(glyphs,first)) then ClassRejected(ot_error(OtGlyphDomain(),s))
  else ClassAccepted(@{span=s,encoding=OtList(),count=count,first=first,
    maximum=list_maximum(airlock_nat(count),b,s,0,0)}) end

fun ranges_maximum {n:nat} .<n>. (n: int(n),b: !Buf,s: OtSpan,i: int,
  previous: int,maximum: int,glyphs: int): int =
  if n = 0 then maximum else let val row=ot_range(b,s,i) in
    if ile(row.first,previous) orelse ilt(row.last,row.first) orelse ige(row.last,glyphs) then ~1
    else ranges_maximum(n-1,b,s,iadd(i,1),row.last,imax(maximum,row.value),glyphs) end

fun parse_ranges(b: !Buf,s: OtSpan,glyphs: int): OtClassRead = let val count=ot_u16(b,s,2) in
  if not(ot_rows_fit(s,4,count,6)) then ClassRejected(ot_error(OtBounds(),s)) else let
    val maximum=ranges_maximum(airlock_nat(count),b,s,0,~1,0,glyphs)
  in if ilt(maximum,0) then ClassRejected(ot_error(OtOrder(),s))
    else ClassAccepted(@{span=s,encoding=OtRanges(),count=count,first=0,maximum=maximum}) end end

fun parse_encoding(b: !Buf,s: OtSpan,glyphs: int): OtClassRead =
  case+ ot_encoding_of(ot_u16(b,s,0)) of
  | ~None_vt() => ClassRejected(ot_error(OtFormat(),s))
  | ~Some_vt(encoding) => case+ encoding of
    | OtList() => parse_list(b,s,glyphs)
    | OtRanges() => parse_ranges(b,s,glyphs)

implement ot_classdef_parse(b,s,glyphs) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,4) then ClassRejected(ot_error(OtBounds(),s))
  else if not(ot_glyph_domain_valid(glyphs)) then ClassRejected(ot_error(OtGlyphDomain(),s))
  else parse_encoding(b,s,glyphs)
