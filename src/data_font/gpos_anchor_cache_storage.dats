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
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_anchor_cache.sats"
implement ot_anchor_cache_capacity(count) = let
  val bytes=g0uint2int_size_int(sizeof<OtAnchorSlot>)
in ige(count,0) andalso ile(count,idiv(MAX_REC_FUEL,bytes)) end
implement ot_anchor_missing() = let val a=ot_adjustment_absent() in
  @{kind=AnchorMissing(),anchor= @{kind=AnchorCoordinates(),x=0,y=0,point=0,dx=a,dy=a}} end
implement ot_anchor_cache_make(count) = let
  val rows=arrayptr_make_elt<OtAnchorSlot>(g1int2uint_int_size(count),ot_anchor_missing())
in OtAnchorCache(rows,count,0) end
implement ot_anchor_cache_count(cache) = let val+ OtAnchorCache(rows,count,filled)=cache in count end
implement ot_anchor_cache_filled(cache) = let val+ OtAnchorCache(rows,count,filled)=cache in filled end
implement ot_anchor_cache_append(cache,v) = let val+ ~OtAnchorCache(rows,count,filled)=cache
  val ()=arrayptr_set_at<OtAnchorSlot>(rows,g1int2uint_int_size(filled),v)
in OtAnchorCache(rows,count,filled+1) end
implement ot_anchor_cache_get(cache,index) = let val+ OtAnchorCache(rows,count,filled)=cache in
  arrayptr_get_at<OtAnchorSlot>(rows,g1int2uint_int_size(airlock_below(index,count))) end
implement ot_anchor_cache_dispose(cache) = let val+ ~OtAnchorCache(rows,count,filled)=cache in arrayptr_free(rows) end
