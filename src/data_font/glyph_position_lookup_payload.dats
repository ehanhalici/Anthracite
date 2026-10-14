#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_position_lookup_types.sats"
staload "data_font/gpos_mark_matrix_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_pair_work.sats"
staload "data_font/glyph_position_mark_work.sats"
staload "data_font/glyph_position_lookup_work.sats"
extern fun lookup_payload_failed(): int = "mac#anth_die_int"
fun mark{n,m,kind:int | n >= 0; m >= 0}(b: !Buf,t: !GposMarkMatrix(kind),metadata: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,scale: GlyphScale,c: !GlyphPositionCache(m),node: int,p: GlyphMarkParent,next: int): GlyphPairStep =
  if not(glyph_position_ready(p.status)) then @{status=p.status,next=next,matched=false} else let
    val step=glyph_position_mark_matrix_step(b,t,metadata,s,meta,scale,c,node,p.node)
  in @{status=step.status,next=next,matched=step.matched} end
implement glyph_position_lookup_payload(b,p,m,s,meta,scale,c,f,set,selection,d,node,base) = let
  val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
in case+ p of
  | PositionPayloadVacant() => let val failed=lookup_payload_failed() in @{status=PositionReference(),next=failed,matched=false} end
  | PositionPayloadSingle(t) => glyph_position_lookup_single(b,t,scale,c,node,core,links.next)
  | PositionPayloadPair(t) => glyph_position_lookup_pair(b,t,m,s,meta,scale,c,f,set,selection,node,core,links.next)
  | PositionPayloadCursive(t) => glyph_position_lookup_cursive(b,t,m,s,meta,scale,c,f,set,selection,d,node,links.next)
  | PositionPayloadBase(t) => mark(b,t,m,s,meta,scale,c,node,@{status=PositionReady(),node=base},links.next)
  | PositionPayloadMark(t) => mark(b,t,m,s,meta,scale,c,node,glyph_position_lookup_mark(b,m,s,meta,f,set,selection,node),links.next)
  | PositionPayloadLigature(t) => let val step=glyph_position_mark_ligature_step(b,t,s,meta,scale,c,node,base)
    in @{status=step.status,next=links.next,matched=step.matched} end end
