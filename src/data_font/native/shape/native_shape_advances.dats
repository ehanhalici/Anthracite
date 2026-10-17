#include "data_font/native/shape/native_shape_internal.hats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
staload "data_font/opentype/definition/gdef_types.sats"
extern fun native_advance_graph_failed(): void = "mac#anth_die_void"
fun mark(kind: GdefGlyphKind): bool = case+ kind of | GlyphMark() => true
  | GlyphBase() => false | GlyphLigature() => false | GlyphComponent() => false | GlyphUnclassified() => false
fun cleared(m: !GlyphMetadata,core: GlyphCore,p: GlyphPosition): GlyphPosition = let
  val property=glyph_metadata_core_property(m,core)
in if core.ignorable then
  @{xAdvance=0,yAdvance=0,xOffset=0,yOffset=p.yOffset,attachment=p.attachment,parent=p.parent,anchorX=p.anchorX,anchorY=p.anchorY}
  else if mark(property.property.kind) then
  @{xAdvance=0,yAdvance=0,xOffset=p.xOffset,yOffset=p.yOffset,attachment=p.attachment,parent=p.parent,anchorX=p.anchorX,anchorY=p.anchorY}
  else p end
fun walk{n,k:nat} .<k>. (left: int(k),s: !GlyphStorage(n),meta: GlyphRunMeta,m: !GlyphMetadata,node: int): void =
  if left = 0 then (if ieq(node,~1) then () else native_advance_graph_failed())
  else if not(glyph_run_node(s,meta,node)) then native_advance_graph_failed() else let
    val core=glyph_storage_core(s,node) and p=glyph_storage_position(s,node) and links=glyph_storage_links(s,node)
    val ()=glyph_storage_set_position(s,node,cleared(m,core,p))
  in walk(left-1,s,meta,m,links.next) end
implement native_shape_clear_advances(cache,p) = let
  val+ NativeShapeCache(m,sub,pos,face)=cache
  val+ ~PositionAccumulating(run,scale)=p val+ ~GlyphRun(phase,meta,s)=run
  val ()=walk(airlock_nat(meta.live),s,meta,m,meta.head)
in PositionAccumulating(GlyphRun(phase,meta,s),scale) end
