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
fun mark(kind: GdefGlyphKind): bool = case+ kind of | GlyphMark() => true
  | GlyphBase() => false | GlyphLigature() => false | GlyphUnclassified() => false | GlyphComponent() => false
fun rest{n,k:nat} .<k>. (left: int(k),m: !GlyphMetadata,s: !GlyphStorage(n),nodes: !Buf,i: int): bool =
  if left = 0 then true else let val core=glyph_storage_core(s,buf_get32(nodes,i))
    val property=glyph_metadata_core_property(m,core)
  in mark(property.property.kind) andalso rest(left-1,m,s,nodes,iadd(i,1)) end
implement glyph_ligature_kind(m,s,nodes,count) =
  if not(rest(airlock_nat(isub(count,1)),m,s,nodes,1)) then LigatureCompound() else let
    val core=glyph_storage_core(s,buf_get32(nodes,0)) val property=glyph_metadata_core_property(m,core)
  in case+ property.property.kind of | GlyphMark() => LigatureMarks() | GlyphBase() => LigatureBaseMarks()
    | GlyphLigature() => LigatureCompound() | GlyphComponent() => LigatureCompound() | GlyphUnclassified() => LigatureCompound() end
