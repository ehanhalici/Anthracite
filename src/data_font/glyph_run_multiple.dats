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
fun expand {n:nat}(phase: GlyphRunPhase(1),meta: GlyphRunMeta,s: GlyphStorage(n),
  node: int,output: !Buf,count: int): GlyphRunEdit(1) = let
  val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
  val last=glyph_run_insert(s,core,meta.used,node,links.next,output,count)
  val ()=glyph_run_previous(s,links.next,last)
  val ()=glyph_storage_set_core(s,node,glyph_run_multiple_core(core,buf_get32(output,0),0,count))
  val added=isub(count,1)
  val next=glyph_run_expansion_meta(meta,node,last,added)
in GlyphRunEdited(GlyphRun(phase,next,s),GlyphUpdated(),node) end
implement glyph_run_multiple(run,node,output,count) = let val+ ~GlyphRun(phase,meta,s)=run in
  if not(glyph_run_node(s,meta,node)) then GlyphRunEdited(GlyphRun(phase,meta,s),GlyphNode(),~1)
  else if ilt(count,1) orelse igt(count,MAX_REC_FUEL) then GlyphRunEdited(GlyphRun(phase,meta,s),GlyphDomain(),~1)
  else if igt(isub(count,1),isub(glyph_storage_count(s),meta.used))
    then GlyphRunEdited(GlyphRun(phase,meta,s),GlyphCapacity(),~1)
  else if not(glyph_run_outputs(meta,output,count)) then GlyphRunEdited(GlyphRun(phase,meta,s),GlyphDomain(),~1)
  else expand(phase,meta,s,node,output,count) end
