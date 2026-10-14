#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
implement glyph_storage_core(s,index) = let val+ GlyphStorage(count,core,links,positions)=s in
  arrayptr_get_at<GlyphCore>(core,g1int2uint_int_size(airlock_below(index,count))) end
implement glyph_storage_links(s,index) = let val+ GlyphStorage(count,core,links,positions)=s in
  arrayptr_get_at<GlyphLinks>(links,g1int2uint_int_size(airlock_below(index,count))) end
implement glyph_storage_position(s,index) = let val+ GlyphStorage(count,core,links,positions)=s in
  arrayptr_get_at<GlyphPosition>(positions,g1int2uint_int_size(airlock_below(index,count))) end
implement glyph_storage_set_core(s,index,v) = let val+ GlyphStorage(count,core,links,positions)=s in
  arrayptr_set_at<GlyphCore>(core,g1int2uint_int_size(airlock_below(index,count)),v) end
implement glyph_storage_set_links(s,index,v) = let val+ GlyphStorage(count,core,links,positions)=s in
  arrayptr_set_at<GlyphLinks>(links,g1int2uint_int_size(airlock_below(index,count)),v) end
implement glyph_storage_set_position(s,index,v) = let val+ GlyphStorage(count,core,links,positions)=s in
  arrayptr_set_at<GlyphPosition>(positions,g1int2uint_int_size(airlock_below(index,count)),v) end
fun copy {n,m,r:nat} .<r>. (remaining: int(r),source: !GlyphStorage(n),target: !GlyphStorage(m),index: int): void =
  if remaining = 0 then () else let
    val ()=glyph_storage_set_core(target,index,glyph_storage_core(source,index))
    val ()=glyph_storage_set_links(target,index,glyph_storage_links(source,index))
    val ()=glyph_storage_set_position(target,index,glyph_storage_position(source,index))
  in copy(remaining-1,source,target,iadd(index,1)) end
implement glyph_storage_copy(source,target,count) = copy(airlock_nat(count),source,target,0)
