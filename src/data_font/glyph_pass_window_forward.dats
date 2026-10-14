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
staload "data_font/gsub_ligature_types.sats"
staload "data_font/glyph_pass_ligature_work.sats"
extern fun window_forward_failed(): int = "mac#anth_die_int"
fun selected_prefix{n:nat}(b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,o: GlyphWindowSelection,
  first: int,node: int,count: int,input: int,remaining: &int >> _): GlyphWindowRows =
  if ine(input,count) then @{status=WindowReady(),count=count,input=input} else let val core=glyph_storage_core(s,node) in
    if not(glyph_pass_selected(o.selection,core.mask)) then @{status=WindowReady(),count=count,input=input}
    else case+ glyph_ligature_affinity(b,m,s,meta,o.flags,o.set,first,node,remaining) of
      | LigatureCompatible() => @{status=WindowReady(),count=count,input=iadd(input,1)}
      | LigatureIncompatible() => @{status=WindowReady(),count=count,input=input}
      | LigatureAffinityCapacity() => @{status=WindowCapacity(),count=0,input=0} end
fun input_prefix{n:nat}(b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,o: GlyphWindowSelection,
  first: int,node: int,maximum: int,count: int,input: int,remaining: &int >> _): GlyphWindowRows =
  if ige(count,maximum) then @{status=WindowReady(),count=count,input=input}
  else selected_prefix(b,m,s,meta,o,first,node,count,input,remaining)
fun walk{n,k:nat} .<k>. (left: int(k),b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,o: GlyphWindowSelection,
  first: int,node: int,maximum: int,inputMaximum: int,start: int,glyphs: !Buf,nodes: !Buf,count: int,input: int,remaining: &int >> _): GlyphWindowRows =
  if ieq(node,~1) orelse ige(count,maximum) then @{status=WindowReady(),count=count,input=input}
  else if left = 0 then let val failed=window_forward_failed() in @{status=WindowReference(),count=failed,input=0} end
  else if ile(remaining,0) then @{status=WindowCapacity(),count=0,input=0} else let
    val ()=remaining := isub(remaining,1)
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
  in if not(glyph_metadata_allows_core(b,m,o.flags,o.set,core))
    then walk(left-1,b,m,s,meta,o,first,links.next,maximum,inputMaximum,start,glyphs,nodes,count,input,remaining) else let
      val next=input_prefix(b,m,s,meta,o,first,node,inputMaximum,count,input,remaining)
      val ()=glyph_window_write(s,node,glyphs,nodes,iadd(start,count))
    in if not(glyph_window_status_valid(next.status)) then next
      else walk(left-1,b,m,s,meta,o,first,links.next,maximum,inputMaximum,start,glyphs,nodes,iadd(count,1),next.input,remaining) end end
implement glyph_window_forward(b,m,s,meta,o,node,maximum,inputMaximum,start,glyphs,nodes,remaining) = let
  val links=glyph_storage_links(s,node)
  val ()=glyph_window_write(s,node,glyphs,nodes,start)
in walk(airlock_nat(meta.live),b,m,s,meta,o,node,links.next,maximum,inputMaximum,start,glyphs,nodes,1,1,remaining) end
