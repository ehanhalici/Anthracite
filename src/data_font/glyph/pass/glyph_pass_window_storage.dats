#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/pass/glyph_pass_work.sats"
staload "data_font/glyph/pass/glyph_pass_window_types.sats"
staload "data_font/glyph/pass/glyph_pass_window_work.sats"
staload "data_font/glyph/pass/glyph_pass_window.sats"
implement glyph_window_make(limits) = let
  val total=g0int2int_int_llint(limits.back)+g0int2int_int_llint(limits.input)+g0int2int_int_llint(limits.look)
in if ilt(limits.back,0) orelse ilt(limits.input,1) orelse ilt(limits.look,0)
  then WindowRejected(WindowReference())
  else if total > g0int2int_int_llint(idiv(MAX_REC_FUEL,8)) then WindowRejected(WindowCapacity()) else let
    val count=airlock_i32(total)
    val glyphs=buf_make(imul(count,4)) and nodes=buf_make(imul(count,4))
  in WindowAllocated(GlyphContextWindow(glyphs,nodes,limits,count)) end end
implement glyph_window_dispose(w) = let val+ ~GlyphContextWindow(glyphs,nodes,limits,count)=w
in buf_free(glyphs); buf_free(nodes) end
implement glyph_window_status_valid(status) = case+ status of | WindowReady() => true
  | WindowSkipped() => false | WindowDomain() => false | WindowReference() => false | WindowCapacity() => false
implement glyph_window_write(s,node,glyphs,nodes,index) = let val core=glyph_storage_core(s,node)
  val ()=buf_set32(glyphs,index,core.glyph)
in buf_set32(nodes,index,node) end
fun swap(b: !Buf,a: int,c: int): void = let val first=buf_get32(b,a) and second=buf_get32(b,c)
in buf_set32(b,a,second); buf_set32(b,c,first) end
fun reverse{n:nat} .<n>. (left: int(n),glyphs: !Buf,nodes: !Buf,index: int,last: int): void =
  if left = 0 then () else let val ()=swap(glyphs,index,last) and ()=swap(nodes,index,last)
  in reverse(left-1,glyphs,nodes,iadd(index,1),isub(last,1)) end
implement glyph_window_reverse(glyphs,nodes,count) = reverse(airlock_nat(idiv(count,2)),glyphs,nodes,0,isub(count,1))
