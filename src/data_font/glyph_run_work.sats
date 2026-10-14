staload "mem.sats"
staload "data_font/glyph_run_types.sats"
fun glyph_run_expansion_meta(meta: GlyphRunMeta,node: int,last: int,added: int): GlyphRunMeta
fun glyph_run_node{n:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,node: int): bool
fun glyph_run_glyph(meta: GlyphRunMeta,glyph: int): bool
fun glyph_run_seed(meta: GlyphRunMeta,seed: GlyphSeed): bool
fun glyph_run_seed_core(seed: GlyphSeed): GlyphCore
fun glyph_run_new_glyph(core: GlyphCore,glyph: int): GlyphCore
fun glyph_run_multiple_core(core: GlyphCore,glyph: int,index: int,count: int): GlyphCore
fun glyph_run_new_mask(core: GlyphCore,mask: uint): GlyphCore
fun glyph_run_new_cluster(core: GlyphCore,cluster: int): GlyphCore
(* Called only after ordered-node selection has proved the complete interval. *)
fun glyph_run_cluster_merge{n:nat}(storage: !GlyphStorage(n),meta: GlyphRunMeta,nodes: !Buf,count: int): void
fun glyph_run_previous{n:nat}(s: !GlyphStorage(n),node: int,previous: int): void
fun glyph_run_next{n:nat}(s: !GlyphStorage(n),node: int,next: int): void
fun glyph_run_initial{n:nat}(s: !GlyphStorage(n),node: int,core: GlyphCore,previous: int,next: int): void
fun glyph_run_outputs(meta: GlyphRunMeta,output: !Buf,count: int): bool
fun glyph_run_insert{n:nat}(s: !GlyphStorage(n),core: GlyphCore,start: int,node: int,
  next: int,output: !Buf,count: int): int
fun glyph_run_selection{n:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,nodes: !Buf,count: int): GlyphEditStatus
fun glyph_run_merge{n:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,nodes: !Buf,count: int,glyph: int): GlyphRunMeta
datatype GlyphMergeKind = MergeLigature | MergeAssociation
fun glyph_run_merge_counted{n:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,nodes: !Buf,weights: !Buf,
  count: int,glyph: int,kind: GlyphMergeKind): GlyphRunMeta
fun glyph_run_attachment_check{n:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,node: int,p: GlyphPosition): GlyphAttachmentCheck
fun glyph_run_association{n:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,node: int): GlyphAssociationView
