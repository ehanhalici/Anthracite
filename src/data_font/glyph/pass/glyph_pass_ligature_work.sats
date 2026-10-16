staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/ligation_lookup/ot_ligation_lookup_types.sats"
datatype GlyphLigatureKind = LigatureCompound | LigatureBaseMarks | LigatureMarks
datatype GlyphLigatureAffinity = LigatureCompatible | LigatureIncompatible | LigatureAffinityCapacity
typedef GlyphLigatureInput = @{count=int,status=GlyphPassStatus}
typedef GlyphLigatureStep = @{next=int,matched=bool,status=GlyphPassStatus}
fun glyph_ligature_input{n:nat}(b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  flags: OtLookupFlags,set: int,selection: GlyphSelection,node: int,maximum: int,
  glyphs: !Buf,nodes: !Buf,remaining: &int >> _): GlyphLigatureInput
fun glyph_ligature_kind{n:nat}(m: !GlyphMetadata,s: !GlyphStorage(n),nodes: !Buf,count: int): GlyphLigatureKind
fun glyph_ligature_affinity{n:nat}(b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  flags: OtLookupFlags,set: int,first: int,candidate: int,remaining: &int >> _): GlyphLigatureAffinity
fun glyph_ligature_weights{n:nat}(m: !GlyphMetadata,s: !GlyphStorage(n),nodes: !Buf,count: int,weights: !Buf): void
fun glyph_ligature_bind{n:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,nodes: !Buf,weights: !Buf,count: int): void
fun glyph_ligature_merge{n:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,nodes: !Buf,weights: !Buf,count: int,
  glyph: int,kind: GlyphLigatureKind): GlyphRunMeta
fun glyph_ligature_step{n,k:nat}(b: !Buf,t: !OtLigationTables(k,k),m: !GlyphMetadata,s: !GlyphStorage(n),meta: &GlyphRunMeta >> _,
  f: OtLookupFlags,set: int,selection: GlyphSelection,node: int,glyphs: !Buf,nodes: !Buf,weights: !Buf,remaining: &int >> _): GlyphLigatureStep
fun glyph_ligature_walk{n,k:nat}(b: !Buf,t: !OtLigationTables(k,k),m: !GlyphMetadata,s: !GlyphStorage(n),meta: &GlyphRunMeta >> _,
  f: OtLookupFlags,set: int,selection: GlyphSelection,glyphs: !Buf,nodes: !Buf,weights: !Buf,
  visited: &int >> _,matches: &int >> _): GlyphPassStatus
fun glyph_ligature_apply{n,k:nat}(b: !Buf,t: !OtLigationTables(k,k),maximum: int,m: !GlyphMetadata,
  phase: GlyphRunPhase(1),meta: GlyphRunMeta,s: GlyphStorage(n),f: OtLookupFlags,set: int,selection: GlyphSelection): GlyphPassResult(1)
fun glyph_ligature_check(m: !GlyphMetadata,meta: GlyphRunMeta,glyphs: int,f: OtLookupFlags,set: int,count: int): GlyphPassStatus
