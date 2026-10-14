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
staload "data_font/gpos_mark_ligature_types.sats"
staload "data_font/gpos_mark_ligature_groups.sats"
implement gpos_ligature_groups_make(count) = let
  val zero: GposLigatureGroup= @{span= @{offset=0,length=0},components=0,start=0,floor=0}
  val rows=arrayptr_make_elt<GposLigatureGroup>(g1int2uint_int_size(count),zero)
in GposLigatureGroups(rows,count,0) end
implement gpos_ligature_groups_count(groups) = let val+ GposLigatureGroups(rows,count,filled)=groups in count end
implement gpos_ligature_groups_filled(groups) = let val+ GposLigatureGroups(rows,count,filled)=groups in filled end
implement gpos_ligature_groups_append(groups,v) = let val+ ~GposLigatureGroups(rows,count,filled)=groups
  val ()=arrayptr_set_at<GposLigatureGroup>(rows,g1int2uint_int_size(filled),v)
in GposLigatureGroups(rows,count,filled+1) end
implement gpos_ligature_groups_get(groups,index) = let val+ GposLigatureGroups(rows,count,filled)=groups in
  arrayptr_get_at<GposLigatureGroup>(rows,g1int2uint_int_size(airlock_below(index,count))) end
implement gpos_ligature_groups_dispose(groups) = let val+ ~GposLigatureGroups(rows,count,filled)=groups in arrayptr_free(rows) end
