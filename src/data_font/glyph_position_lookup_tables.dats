#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_position_lookup_types.sats"
staload "data_font/ot_position_lookup_work.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_pair_work.sats"
staload "data_font/glyph_position_mark_work.sats"
staload "data_font/glyph_position_lookup_work.sats"
fun walk{n,m,k,i:nat | i <= k} .<k-i>. (index: int(i),b: !Buf,t: !OtPositionTables(k,k),metadata: !GlyphMetadata,
  s: !GlyphStorage(n),meta: GlyphRunMeta,scale: GlyphScale,c: !GlyphPositionCache(m),f: OtLookupFlags,set: int,
  selection: GlyphSelection,d: GlyphPositionDirection,node: int,bases: !GlyphPositionBases(k)): GlyphPairStep = let
  val+ OtPositionTables(pf,gc | rows,count,filled)=t
in if index = count then let val links=glyph_storage_links(s,node) in @{status=PositionReady(),next=links.next,matched=false} end else let
  var loan: OtPositionPayload=PositionPayloadVacant()
  val ()=array_exch_at<OtPositionPayload>(!rows,i2sz(index),loan)
  val result=glyph_position_lookup_payload(b,loan,metadata,s,meta,scale,c,f,set,selection,d,node,glyph_position_bases_get(bases,index))
  val ()=array_exch_at<OtPositionPayload>(!rows,i2sz(index),loan)
  val ()=ot_position_payload_dispose(loan)
in if result.matched orelse not(glyph_position_ready(result.status)) then result
  else walk(index+1,b,t,metadata,s,meta,scale,c,f,set,selection,d,node,bases) end end
implement glyph_position_lookup_tables(b,t,m,s,meta,scale,c,f,set,selection,d,node,bases) =
  walk(0,b,t,m,s,meta,scale,c,f,set,selection,d,node,bases)
