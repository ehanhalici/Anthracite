#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_run_work.sats"
implement glyph_run_set_position(run,node,p) = let val+ ~GlyphRun(phase,meta,s)=run in
  if not(glyph_run_node(s,meta,node)) then GlyphRunEdited(GlyphRun(phase,meta,s),GlyphNode(),~1) else
    case+ glyph_run_attachment_check(s,meta,node,p) of
    | AttachmentInvalid() => GlyphRunEdited(GlyphRun(phase,meta,s),GlyphNode(),~1)
    | AttachmentCycle() => GlyphRunEdited(GlyphRun(phase,meta,s),GlyphOrder(),~1)
    | AttachmentValid() => let
    val ()=glyph_storage_set_position(s,node,p)
  in GlyphRunEdited(GlyphRun(phase,meta,s),GlyphUpdated(),node) end end
