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
implement glyph_run_query(run,node) = let val+ GlyphRun(phase,meta,s)=run in
  if not(glyph_run_node(s,meta,node)) then @{kind=GlyphMissing(),core=glyph_core_empty(),
    links=glyph_links_empty(),position=glyph_position_empty()} else
    @{kind=GlyphPresent(),core=glyph_storage_core(s,node),links=glyph_storage_links(s,node),position=glyph_storage_position(s,node)} end
