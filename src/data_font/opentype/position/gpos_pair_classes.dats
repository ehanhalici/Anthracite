#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_values.sats"
staload "data_font/opentype/position/gpos_value_cache_types.sats"
staload "data_font/opentype/position/gpos_value_cache.sats"
staload "data_font/opentype/position/gpos_pair_types.sats"
staload "data_font/opentype/tables/opentype_classdef.sats"
staload "data_font/opentype/position/gpos_pair_work.sats"
fun class_at(b: !Buf,s: OtSpan,field: int,floor: int,glyphs: int): OtClassRead = let
  val child=ot_optional_child(s,ot_u16(b,s,field),floor)
in case+ child.kind of
  | ChildMissing() => ClassRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => ClassRejected(ot_error(OtBounds(),s))
  | ChildPresent() => ot_classdef_parse(b,child.span,glyphs) end
fun second(b: !Buf,s: OtSpan,c: OtCoverageInfo,f: GposPairFormat,glyphs: int,floor: int,
  first: OtClassInfo): GposPairRead = case+ class_at(b,s,10,floor,glyphs) of
  | ~ClassRejected(e) => PairRejected(e) | ~ClassAccepted(next) => let
    val n=ot_u16(b,s,12) and m=ot_u16(b,s,14)
  in if ige(first.maximum,n) orelse ige(next.maximum,m) then PairRejected(ot_error(OtReference(),s))
    else gpos_pair_matrix(b,@{span=s,coverage=c,formats=f,firstClass=first,secondClass=next,firstCount=n,secondCount=m,glyphs=glyphs}) end
fun classes(b: !Buf,s: OtSpan,c: OtCoverageInfo,f: GposPairFormat,glyphs: int,floor: int): GposPairRead =
  case+ class_at(b,s,8,floor,glyphs) of
  | ~ClassRejected(e) => PairRejected(e) | ~ClassAccepted(first) => second(b,s,c,f,glyphs,floor,first)
implement gpos_pair_classes(b,s,glyphs,f) =
  if ilt(s.length,16) then PairRejected(ot_error(OtBounds(),s)) else let
    val n=ot_u16(b,s,12) and m=ot_u16(b,s,14)
    val row=imul(m,f.stride)
  in if ieq(n,0) orelse ieq(m,0) then PairRejected(ot_error(OtFormat(),s))
    else if igt(row,0) andalso not(ot_rows_fit(s,16,n,row)) then PairRejected(ot_error(OtBounds(),s)) else let
      val floor=iadd(16,imul(n,row))
    in case+ gpos_pair_coverage(b,s,floor,glyphs) of
      | ~CoverageRejected(e) => PairRejected(e) | ~CoverageAccepted(c) => classes(b,s,c,f,glyphs,floor) end end
