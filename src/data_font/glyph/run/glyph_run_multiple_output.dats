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
fun valid {n:nat} .<n>. (n: int(n),meta: GlyphRunMeta,output: !Buf,index: int): bool =
  if n = 0 then true else if not(glyph_run_glyph(meta,buf_get32(output,index))) then false
  else valid(n-1,meta,output,iadd(index,1))
implement glyph_run_outputs(meta,output,count) = igt(count,0) andalso ile(count,idiv(buf_cap(output),4))
  andalso valid(airlock_nat(count),meta,output,0)
fun insert {n,r:nat} .<r>. (remaining: int(r),s: !GlyphStorage(n),core: GlyphCore,start: int,
  previous: int,next: int,output: !Buf,index: int,count: int): int =
  if remaining = 0 then previous else let
    val node=iadd(start,isub(index,1))
    val ()=glyph_run_initial(s,node,glyph_run_multiple_core(core,buf_get32(output,index),index,count),previous,next)
    val ()=glyph_run_next(s,previous,node)
  in insert(remaining-1,s,core,start,node,next,output,iadd(index,1),count) end
implement glyph_run_insert(s,core,start,node,next,output,count) =
  insert(airlock_nat(isub(count,1)),s,core,start,node,next,output,1,count)
