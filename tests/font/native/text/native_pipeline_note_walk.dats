#include "font/native/text/native_pipeline_note.hats"
fun printing_of(category: int): bool =
  if ieq(category,26) orelse ieq(category,24) orelse ieq(category,25) then false else true
fun mark(kind: GdefGlyphKind): bool = case+ kind of
  | GlyphMark() => true | GlyphBase() => false | GlyphLigature() => false
  | GlyphComponent() => false | GlyphUnclassified() => false
fun added(v: GlyphView,item: NativeTextItem,category: !PropertyMap(6),stats: PipelineNoteStats): PipelineNoteStats = let
  val printable=printing_of(property_value(category,v.core.scalar)) andalso not(v.core.ignorable)
  val missing=printable andalso ieq(v.core.glyph,0)
  val invalid=ilt(v.core.sourceStart,item.sourceStart) orelse igt(v.core.sourceEnd,item.sourceEnd)
  val marked=mark(v.core.unicodeKind)
in @{items=stats.items,glyphs=iadd(stats.glyphs,1),missing=iadd(stats.missing,if missing then 1 else 0),
  spans=iadd(stats.spans,if invalid then 1 else 0),marks=iadd(stats.marks,if marked then 1 else 0),
  advances=iadd(stats.advances,if marked andalso ine(v.position.xAdvance,0) then 1 else 0),failures=stats.failures} end
fun glyphs{n:nat} .<n>. (left: int(n),run: !GlyphPositioned(1),category: !PropertyMap(6),item: NativeTextItem,
  node: int,stats: PipelineNoteStats): PipelineNoteStats = if left = 0 then stats else let
  val v=glyph_position_query(run,node) val next=added(v,item,category,stats)
in glyphs(left-1,run,category,item,v.links.next,next) end
fun counted(assets: !NativeTextAssets,run: GlyphPositioned(1),item: NativeTextItem,stats: PipelineNoteStats): PipelineNoteStats = let
  val+ NativeTextAssets(aux,w,l,e)=assets val+ NativeTextAux(base,s,b,br,m)=aux
  val+ NativeTextBase(data,n,mcm)=base val+ NativeShapeData(db,category,ignored,joining)=data
  val meta=glyph_position_meta(run)
  val next=glyphs(airlock_nat(meta.live),run,category,item,meta.head,stats)
  val ()=glyph_position_dispose(run)
in next end
fun failed(stats: PipelineNoteStats): PipelineNoteStats = @{items=stats.items,glyphs=stats.glyphs,
  missing=stats.missing,spans=stats.spans,marks=stats.marks,advances=stats.advances,failures=iadd(stats.failures,1)}
fun shaped(assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,
  face: !SfntFace,cache: !NativeShapeCache,item: NativeTextItem,stats: PipelineNoteStats): PipelineNoteStats = let
  val+ SfntFace(b,info)=face val masks: OtShapeMasks= @{initial=1u,medial=2u,final=4u,isolated=8u,mirror=16u}
in case+ native_text_item_shape(b,info,cache,assets,a,contexts,item,ShapeDefaultLanguage(),masks,@{xPpem=16,yPpem=16}) of
  | ~NativeItemShaped(run) => counted(assets,run,item,stats)
  | ~NativeItemUnsupported(s) => failed(stats) | ~NativeItemPlanError(e) => failed(stats)
  | ~NativeItemTextError(e) => failed(stats) | ~NativeItemRunError(e) => failed(stats) end
fun walk{n:nat} .<n>. (left: int(n),assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,
  items: !NativeTextItems,latin: !SfntFace,lc: !NativeShapeCache,arabic: !SfntFace,ac: !NativeShapeCache,
  index: int,stats: PipelineNoteStats): PipelineNoteStats = if left = 0 then stats else let
    val item=native_text_items_at(items,index)
    val next=if ieq(item.script.code,1098015074) then shaped(assets,a,contexts,arabic,ac,item,stats)
      else shaped(assets,a,contexts,latin,lc,item,stats)
  in walk(left-1,assets,a,contexts,items,latin,lc,arabic,ac,iadd(index,1),next) end
implement pipeline_note_walk(assets,a,contexts,items,latin,lc,arabic,ac) = let val count=native_text_items_count(items)
in walk(airlock_nat(count),assets,a,contexts,items,latin,lc,arabic,ac,0,
  @{items=count,glyphs=0,missing=0,spans=0,marks=0,advances=0,failures=0}) end
