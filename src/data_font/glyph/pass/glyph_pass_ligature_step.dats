#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
staload "data_font/opentype/substitution/gsub_ligatures.sats"
staload "data_font/glyph/pass/glyph_pass_ligature_work.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup_types.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup_work.sats"
fun merge{n:nat}(m: !GlyphMetadata,s: !GlyphStorage(n),meta: &GlyphRunMeta >> _,nodes: !Buf,weights: !Buf,
  count: int,glyph: int,next: int): GlyphLigatureStep = case+ glyph_run_selection(s,meta,nodes,count) of
  | GlyphUpdated() => let
    val last=glyph_storage_links(s,buf_get32(nodes,isub(count,1)))
    val kind=glyph_ligature_kind(m,s,nodes,count)
    val ()=glyph_ligature_weights(m,s,nodes,count,weights)
    val ()=meta := glyph_ligature_merge(s,meta,nodes,weights,count,glyph,kind)
  in @{next=last.next,matched=true,status=GlyphPassApplied()} end
  | GlyphOverflow() => @{next=next,matched=false,status=GlyphPassCapacity()}
  | GlyphUnchanged() => @{next=next,matched=false,status=GlyphPassReference()}
  | GlyphCapacity() => @{next=next,matched=false,status=GlyphPassCapacity()}
  | GlyphNode() => @{next=next,matched=false,status=GlyphPassReference()}
  | GlyphDomain() => @{next=next,matched=false,status=GlyphPassDomain()}
  | GlyphSource() => @{next=next,matched=false,status=GlyphPassReference()}
  | GlyphOrder() => @{next=next,matched=false,status=GlyphPassReference()}
  | GlyphAssociationError() => @{next=next,matched=false,status=GlyphPassReference()}
fun queried{n,k:nat}(b: !Buf,t: !OtLigationTables(k,k),m: !GlyphMetadata,s: !GlyphStorage(n),meta: &GlyphRunMeta >> _,
  input: GlyphLigatureInput,glyphs: !Buf,nodes: !Buf,weights: !Buf,next: int,remaining: &int >> _): GlyphLigatureStep =
  case+ input.status of | GlyphPassApplied() => let val query=ot_ligation_tables_query(b,t,glyphs,input.count,0,remaining) in
    case+ query.status of | LigatureMiss() => @{next=next,matched=false,status=GlyphPassApplied()}
    | LigatureBudget() => @{next=next,matched=false,status=GlyphPassCapacity()}
    | LigatureHit() => merge(m,s,meta,nodes,weights,query.result.components,query.result.glyph,next) end
  | GlyphPassDomain() => @{next=next,matched=false,status=GlyphPassDomain()}
  | GlyphPassReference() => @{next=next,matched=false,status=GlyphPassReference()}
  | GlyphPassCapacity() => @{next=next,matched=false,status=GlyphPassCapacity()}
fun prepared{n,k:nat}(b: !Buf,t: !OtLigationTables(k,k),m: !GlyphMetadata,s: !GlyphStorage(n),meta: &GlyphRunMeta >> _,
  f: OtLookupFlags,set: int,selection: GlyphSelection,node: int,maximum: int,glyphs: !Buf,nodes: !Buf,weights: !Buf,remaining: &int >> _): GlyphLigatureStep = let
  val links=glyph_storage_links(s,node)
in if ieq(maximum,0) then @{next=links.next,matched=false,status=GlyphPassApplied()} else let
  val input=glyph_ligature_input(b,m,s,meta,f,set,selection,node,maximum,glyphs,nodes,remaining)
in queried(b,t,m,s,meta,input,glyphs,nodes,weights,links.next,remaining) end end
implement glyph_ligature_step(b,t,m,s,meta,f,set,selection,node,glyphs,nodes,weights,remaining) = let
  val core=glyph_storage_core(s,node)
  val needed=ot_ligation_tables_input(b,t,core.glyph,remaining)
in case+ needed.status of | LigationInputReady() => prepared(b,t,m,s,meta,f,set,selection,node,needed.maximum,glyphs,nodes,weights,remaining)
  | LigationInputBudget() => let val links=glyph_storage_links(s,node) in @{next=links.next,matched=false,status=GlyphPassCapacity()} end end
