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
fun forward{n:nat}(b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,o: GlyphWindowSelection,node: int,
  w: !GlyphContextWindow,limits: OtContextLimits,back: GlyphWindowRows,remaining: &int >> _): GlyphWindowSpan = let
  val+ GlyphContextWindow(glyphs,nodes,maximum,capacity)=w
  val rows=glyph_window_forward(b,m,s,meta,o,node,iadd(limits.input,limits.look),limits.input,back.count,glyphs,nodes,remaining)
in @{status=rows.status,start=back.count,count=iadd(back.count,rows.count),input=imin(limits.input,rows.input)} end
fun gathered{n:nat}(b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,o: GlyphWindowSelection,node: int,
  w: !GlyphContextWindow,limits: OtContextLimits,remaining: &int >> _): GlyphWindowSpan = let
  val+ GlyphContextWindow(glyphs,nodes,maximum,capacity)=w
  val back=glyph_window_back(b,m,s,meta,o,node,limits.back,glyphs,nodes,remaining)
in if not(glyph_window_status_valid(back.status)) then @{status=back.status,start=0,count=0,input=0}
  else forward(b,m,s,meta,o,node,w,limits,back,remaining) end
fun fits(limits: OtContextLimits,maximum: OtContextLimits): bool =
  ige(limits.back,0) andalso ige(limits.input,1) andalso ige(limits.look,0)
    andalso ile(limits.back,maximum.back) andalso ile(limits.input,maximum.input) andalso ile(limits.look,maximum.look)
implement glyph_window_gather_limits(b,m,s,meta,o,node,w,limits,remaining) = let
  val+ GlyphContextWindow(glyphs,nodes,maximum,capacity)=w
  val status=glyph_window_check(b,m,s,meta,o,node)
in if not(glyph_window_status_valid(status)) then @{status=status,start=0,count=0,input=0}
  else if not(fits(limits,maximum)) then @{status=WindowReference(),start=0,count=0,input=0}
  else if ile(remaining,0) then @{status=WindowCapacity(),start=0,count=0,input=0}
  else let val ()=remaining := isub(remaining,1) in gathered(b,m,s,meta,o,node,w,limits,remaining) end end
implement glyph_window_gather(b,m,s,meta,o,node,w,remaining) = let val+ GlyphContextWindow(glyphs,nodes,limits,capacity)=w
in glyph_window_gather_limits(b,m,s,meta,o,node,w,limits,remaining) end
