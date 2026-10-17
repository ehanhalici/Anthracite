#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_work.sats"
staload "data_font/opentype/position/gpos_mark_matrix.sats"
staload "data_font/opentype/position/gpos_mark_ligature.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/pass/glyph_pass_work.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_pair_work.sats"
staload "data_font/glyph/position/glyph_position_mark_work.sats"
staload "data_font/glyph/position/glyph_position_lookup_work.sats"
extern fun lookup_refresh_failed(): int = "mac#anth_die_int"
fun accepted{n:nat}(b: !Buf,p: !OtPositionPayload,m: !GlyphMetadata,s: !GlyphStorage(n),core: GlyphCore,previous: int): bool = case+ p of
  | PositionPayloadVacant() => let val failed=lookup_refresh_failed() in false end
  | PositionPayloadBase(t) => glyph_position_mark_base_accept(m,s,core,previous) orelse gpos_mark_matrix_target(b,t,core.glyph)
  | PositionPayloadLigature(t) => not(core.multiplied) orelse ieq(core.component,0) orelse igt(gpos_mark_ligature_components(b,t,core.glyph),0)
  | PositionPayloadSingle(t) => false | PositionPayloadPair(t) => false | PositionPayloadCursive(t) => false | PositionPayloadMark(t) => false
fun walk{n,k,i:nat | i <= k} .<k-i>. (index: int(i),b: !Buf,t: !OtPositionTables(k,k),m: !GlyphMetadata,s: !GlyphStorage(n),
  node: int,core: GlyphCore,previous: int,bases: !GlyphPositionBases(k)): void = let val+ OtPositionTables(pf,gc | rows,count,filled)=t in
  if index = count then () else let
    var loan: OtPositionPayload=PositionPayloadVacant()
    val ()=array_exch_at<OtPositionPayload>(!rows,i2sz(index),loan)
    val keep=accepted(b,loan,m,s,core,previous)
    val ()=array_exch_at<OtPositionPayload>(!rows,i2sz(index),loan)
    val ()=ot_position_payload_dispose(loan)
    val ()=if keep then glyph_position_bases_set(bases,index,node) else ()
  in walk(index+1,b,t,m,s,node,core,previous,bases) end end
implement glyph_position_lookup_refresh(b,t,m,s,node,selection,bases) = let
  val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
in if glyph_position_is_mark(m,core) orelse not(glyph_pass_selected(selection,core.mask)) then ()
  else walk(0,b,t,m,s,node,core,links.previous,bases) end
