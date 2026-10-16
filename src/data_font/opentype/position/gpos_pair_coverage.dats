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
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/position/gpos_pair_work.sats"
implement gpos_pair_coverage(b,s,floor,glyphs) = let
  val child=ot_optional_child(s,ot_u16(b,s,2),floor)
in case+ child.kind of
  | ChildMissing() => CoverageRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => CoverageRejected(ot_error(OtBounds(),s))
  | ChildPresent() => ot_coverage_parse(b,child.span,glyphs) end
implement gpos_pair_empty_class() =
  @{span= @{offset=0,length=0},encoding=OtList(),count=0,first=0,maximum=0}
implement gpos_pair_info(s,c,f,glyphs) = @{span=s,coverage=c,formats=f,
  firstClass=gpos_pair_empty_class(),secondClass=gpos_pair_empty_class(),firstCount=0,secondCount=0,glyphs=glyphs}
