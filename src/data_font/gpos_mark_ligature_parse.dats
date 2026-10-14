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
staload "data_font/gpos_mark_ligature.sats"
staload "data_font/gpos_mark_ligature_groups.sats"
staload "data_font/gpos_mark_ligature_work.sats"
fun marks {n:nat}(b: !Buf,info: GposMarkInfo,groups: GposLigatureGroups(n,n),count: int): GposMarkLigatureRead =
  case+ gpos_mark_anchors(b,info.markArray,info.markCount,iadd(2,imul(info.markCount,4)),MarkRecordFields(),AnchorRequired()) of
  | ~AnchorCacheRejected(e) => let val ()=gpos_ligature_groups_dispose(groups) in MarkLigatureRejected(e) end
  | ~AnchorCacheAccepted(cache) => gpos_ligature_anchors(b,info,cache,groups,airlock_nat(count))
fun groups(b: !Buf,info: GposMarkInfo): GposMarkLigatureRead = case+ gpos_ligature_groups_read(b,info) of
  | ~LigatureGroupsRejected(e) => MarkLigatureRejected(e) | ~LigatureGroupsAccepted(cache,count) => marks(b,info,cache,count)
implement gpos_mark_ligature_parse(b,s,glyphs) = case+ gpos_mark_header(b,s,glyphs) of
  | ~MarkHeaderRejected(e) => MarkLigatureRejected(e) | ~MarkHeaderAccepted(info) => groups(b,info)
