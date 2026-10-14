#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/gsub_sequence_types.sats"
staload "data_font/gsub_sequences.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_expansion_types.sats"
staload "data_font/glyph_expansion_work.sats"
fun insert{n,r:nat} .<r>. (left: int(r),s: !GlyphStorage(n),core: GlyphCore,start: int,
  previous: int,next: int,b: !Buf,view: GsubSequenceView,index: int): int =
  if left = 0 then previous else let
    val node=iadd(start,isub(index,1))
    val ()=glyph_run_initial(s,node,glyph_run_multiple_core(core,gsub_sequence_glyph(b,view,index),index,view.count),previous,next)
    val ()=glyph_run_next(s,previous,node)
  in insert(left-1,s,core,start,node,next,b,view,iadd(index,1)) end
implement glyph_expansion_replace(s,meta,node,b,view) = let
  val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
  val added=isub(view.count,1)
  val last=insert(airlock_nat(added),s,core,meta.used,node,links.next,b,view,1)
  val ()=glyph_run_previous(s,links.next,last)
  val ()=glyph_storage_set_core(s,node,glyph_run_multiple_core(core,gsub_sequence_glyph(b,view,0),0,view.count))
in glyph_run_expansion_meta(meta,node,last,added) end
