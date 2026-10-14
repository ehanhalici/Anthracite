#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_values.sats"
staload "data_font/gpos_value_cache_types.sats"
staload "data_font/gpos_value_cache.sats"
staload "data_font/gpos_pair_types.sats"
staload "data_font/gpos_pairs.sats"
staload "data_font/gpos_pair_sets.sats"
staload "data_font/gpos_pair_work.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/opentype_classdef.sats"
extern fun pair_search_exhausted(): int = "mac#anth_die_int"
fun search {fuel:nat} .<fuel>. (fuel: int(fuel),b: !Buf,set: GposPairSet,stride: int,
  glyph: int,lo: int,hi: int): OtIndex =
  if ige(lo,hi) then @{found=false,index=0} else if fuel = 0 then let
    val failed=pair_search_exhausted() in @{found=false,index=failed} end else let
    val mid=iadd(lo,idiv(isub(hi,lo),2))
    val value=ot_u16(b,set.span,iadd(2,imul(mid,stride)))
  in if ieq(value,glyph) then @{found=true,index=mid}
    else if ilt(value,glyph) then search(fuel-1,b,set,stride,glyph,iadd(mid,1),hi)
    else search(fuel-1,b,set,stride,glyph,lo,mid) end
fun explicit {n,m:nat}(b: !Buf,info: GposPairInfo,sets: !GposPairSets(n,n),
  cache: !OtValueCache(m,m),first: int,second: int): GposPairView = let
  val c=ot_coverage_index(b,info.coverage,first)
in if not(c.found) then gpos_pair_missing() else let val set=gpos_pair_sets_get(sets,c.index)
    val r=search(MAX_REC_FUEL,b,set,iadd(2,info.formats.stride),second,0,set.count)
  in if not(r.found) then gpos_pair_missing() else
    gpos_pair_view(cache,iadd(set.start,imul(r.index,2)),info.formats.progress) end end
fun class_index(b: !Buf,info: GposPairInfo,first: int,second: int): int = let
  val a=ot_classdef_value(b,info.firstClass,first) and c=ot_classdef_value(b,info.secondClass,second)
in imul(iadd(imul(a,info.secondCount),c),2) end
fun query(b: !Buf,table: !GposPairs,first: int,second: int): GposPairView = case+ table of
  | PairGlyphs(info,sets,cache) => explicit(b,info,sets,cache,first,second)
  | PairClasses(info,cache) => let val c=ot_coverage_index(b,info.coverage,first) in
    if not(c.found) then gpos_pair_missing() else gpos_pair_view(cache,class_index(b,info,first,second),info.formats.progress) end
  | PairNoOpClasses(info) => let val c=ot_coverage_index(b,info.coverage,first) in
    if not(c.found) then gpos_pair_missing() else
      @{matched=true,first=ot_value_zero(),second=ot_value_zero(),progress=PairContinueSecond()} end
implement gpos_pair_glyphs(table) = case+ table of | PairGlyphs(info,sets,cache) => info.glyphs
    | PairClasses(info,cache) => info.glyphs | PairNoOpClasses(info) => info.glyphs
implement gpos_pair_query(b,table,first,second) = let
  val glyphs=gpos_pair_glyphs(table)
in if ilt(first,0) orelse ige(first,glyphs) orelse ilt(second,0) orelse ige(second,glyphs)
  then gpos_pair_missing() else query(b,table,first,second) end
