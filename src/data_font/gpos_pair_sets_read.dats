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
staload "data_font/gpos_pair_sets.sats"
staload "data_font/gpos_pair_work.sats"
fun append {n,i:nat | i < n} .<n-i,0>. (b: !Buf,s: OtSpan,set: OtSpan,f: GposPairFormat,glyphs: int,
  cache: GposPairSets(n,i),total: int): GposPairSetRead = let
  val count=ot_u16(b,set,0) and stride=iadd(f.stride,2)
  val next=iadd(total,imul(count,2))
in if not(ot_rows_fit(set,2,count,stride)) then let val ()=gpos_pair_sets_dispose(cache)
    in PairSetsRejected(ot_error(OtBounds(),set)) end
  else if not(ot_value_cache_capacity(next)) then let val ()=gpos_pair_sets_dispose(cache)
    in PairSetsRejected(ot_error(OtCapacity(),set)) end
  else if not(gpos_pair_set_glyphs(b,set,count,stride,glyphs)) then let val ()=gpos_pair_sets_dispose(cache)
    in PairSetsRejected(ot_error(OtOrder(),set)) end else let
    val info: GposPairSet= @{span=set,count=count,start=total,floor=iadd(2,imul(count,stride))}
  in fill(b,s,f,glyphs,gpos_pair_sets_append(cache,info),next) end end
and fill {n,i:nat | i <= n} .<n-i,1>. (b: !Buf,s: OtSpan,f: GposPairFormat,glyphs: int,
  cache: GposPairSets(n,i),total: int): GposPairSetRead = let
  val count=gpos_pair_sets_count(cache) and index=gpos_pair_sets_filled(cache)
in if index = count then PairSetsAccepted(cache,total) else let
    val child=ot_optional_child(s,ot_u16(b,s,iadd(10,imul(index,2))),iadd(10,imul(count,2)))
  in case+ child.kind of
    | ChildMissing() => let val ()=gpos_pair_sets_dispose(cache) in PairSetsRejected(ot_error(OtBounds(),s)) end
    | ChildInvalid() => let val ()=gpos_pair_sets_dispose(cache) in PairSetsRejected(ot_error(OtBounds(),s)) end
    | ChildPresent() => if ilt(child.span.length,2) then let val ()=gpos_pair_sets_dispose(cache)
        in PairSetsRejected(ot_error(OtBounds(),child.span)) end
      else append(b,s,child.span,f,glyphs,cache,total) end end
implement gpos_pair_sets_read(b,s,count,f,glyphs) = fill(b,s,f,glyphs,gpos_pair_sets_make(airlock_nat(count)),0)
