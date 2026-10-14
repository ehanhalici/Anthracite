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
staload "data_font/gpos_mark_shared_types.sats"
staload "data_font/gpos_mark_shared.sats"
implement gpos_mark_anchors(b,s,count,floor,role,presence) =
  if not(ot_anchor_cache_capacity(count)) then AnchorCacheRejected(ot_error(OtCapacity(),s)) else let
    val fields=gpos_mark_fields(count,role)
    val read=ot_anchor_cache_read(b,s,fields,floor,presence)
    val ()=buf_free(fields)
  in read end
