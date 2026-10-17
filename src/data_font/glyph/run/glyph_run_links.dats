#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
implement glyph_run_previous(s,node,previous) = if ilt(node,0) then () else let
  val old=glyph_storage_links(s,node)
in glyph_storage_set_links(s,node,@{life=old.life,previous=previous,next=old.next}) end
implement glyph_run_next(s,node,next) = if ilt(node,0) then () else let
  val old=glyph_storage_links(s,node)
in glyph_storage_set_links(s,node,@{life=old.life,previous=old.previous,next=next}) end
implement glyph_run_initial(s,node,core,previous,next) = let
  val ()=glyph_storage_set_core(s,node,core)
  val ()=glyph_storage_set_links(s,node,@{life=GlyphLive(),previous=previous,next=next})
in glyph_storage_set_position(s,node,glyph_position_empty()) end
