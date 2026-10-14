#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_work.sats"
staload "data_font/glyph_pass_window_types.sats"
staload "data_font/glyph_pass_window_work.sats"
extern fun window_back_failed(): int = "mac#anth_die_int"
fun walk{n,k:nat} .<k>. (left: int(k),b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,o: GlyphWindowSelection,
  node: int,maximum: int,glyphs: !Buf,nodes: !Buf,count: int,remaining: &int >> _): GlyphWindowRows =
  if ieq(node,~1) orelse ige(count,maximum) then @{status=WindowReady(),count=count,input=0}
  else if left = 0 then let val failed=window_back_failed() in @{status=WindowReference(),count=failed,input=0} end
  else if ile(remaining,0) then @{status=WindowCapacity(),count=0,input=0} else let
    val ()=remaining := isub(remaining,1)
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
    val keep=glyph_metadata_allows_core(b,m,o.flags,o.set,core)
    val ()=if keep then glyph_window_write(s,node,glyphs,nodes,count) else ()
  in walk(left-1,b,m,s,meta,o,links.previous,maximum,glyphs,nodes,iadd(count,if keep then 1 else 0),remaining) end
implement glyph_window_back(b,m,s,meta,o,node,maximum,glyphs,nodes,remaining) = let
  val links=glyph_storage_links(s,node)
  val result=walk(airlock_nat(meta.live),b,m,s,meta,o,links.previous,maximum,glyphs,nodes,0,remaining)
  val ()=if glyph_window_status_valid(result.status) then glyph_window_reverse(glyphs,nodes,result.count) else ()
in result end
