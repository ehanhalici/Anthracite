#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gdef_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/glyph_pass_ligature_work.sats"
fun components(core: GlyphCore): int = case+ core.association of | LigatureOwner() => core.components
  | Unassociated() => 1 | LigatureMark() => 1 | LigatureForward() => 1
fun weight(m: !GlyphMetadata,core: GlyphCore,i: int): int =
  if ieq(i,0) then components(core) else let val p=glyph_metadata_core_property(m,core) in
    case+ p.property.kind of | GlyphMark() => 0 | GlyphBase() => components(core)
    | GlyphLigature() => components(core) | GlyphComponent() => components(core) | GlyphUnclassified() => components(core) end
fun walk{n,k:nat} .<k>. (left: int(k),m: !GlyphMetadata,s: !GlyphStorage(n),nodes: !Buf,weights: !Buf,i: int): void =
  if left = 0 then () else let val core=glyph_storage_core(s,buf_get32(nodes,i))
    val ()=buf_set32(weights,i,weight(m,core,i))
  in walk(left-1,m,s,nodes,weights,iadd(i,1)) end
implement glyph_ligature_weights(m,s,nodes,count,weights) = walk(airlock_nat(count),m,s,nodes,weights,0)
