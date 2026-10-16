#include "data_font/text/span/font_span_internal.hats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/text/span/private/font_span_partition.sats"
fun shape_failure_code(result: !FontNativeRead): int = case+ result of
  | FontNativeShaped(run) => 0 | FontNativeNoFace() => 1 | FontNativeCacheError(error) => 2
  | FontNativeUnsupported(script) => 3 | FontNativePlanError(error) => 4
  | FontNativeTextError(error) => 5 | FontNativeRunError(error) => 6
fun ot_reason_code(reason: OtErrorReason): int = case+ reason of
  | OtBounds() => 1 | OtFormat() => 2 | OtGlyphDomain() => 3 | OtOrder() => 4 | OtCoverageIndex() => 5
  | OtPadding() => 6 | OtReference() => 7 | OtUnsupported() => 8 | OtCapacity() => 9
fun ot_reason(result: !FontNativeRead): int = case+ result of
  | FontNativePlanError(error) => ot_reason_code(error.reason)
  | FontNativeCacheError(error) => ot_reason_code(error.reason)
  | FontNativeShaped(run) => 0 | FontNativeNoFace() => 0 | FontNativeUnsupported(script) => 0
  | FontNativeTextError(error) => error.detail | FontNativeRunError(error) => 0
fun ready(status: FontRunStatus): bool = case+ status of
  | FontRunReady() => true | FontRunFace() => false | FontRunScale() => false
  | FontRunOverflow() => false | FontRunRaster() => false | FontRunGraph() => false
fun skip_part(item: NativeTextItem): FontSpanPart = @{kind=SpanSkipPart(),start=item.start,finish=item.finish,
  sourceStart=item.sourceStart,sourceEnd=item.sourceEnd,level=item.level,width=0,x=0}
fun installed(layout: !FontSpanLayout,index: int,item: NativeTextItem,run: FontNativeRun): Option_vt(FontSpanFailure) = let
  val+ FontSpanLayout(a,items,runs,rows,order,n,width,direction)=layout
  val ()=font_span_runs_put(runs,index,run) val extent=font_span_runs_measure(runs,index)
in if not(ready(extent.status)) orelse ilt(extent.xAdvance,0) then Some_vt(SpanOverflow()) else let
  val row: FontSpanPart= @{kind=SpanTextPart(),start=item.start,finish=item.finish,sourceStart=item.sourceStart,sourceEnd=item.sourceEnd,
    level=item.level,width=extent.xAdvance,x=0}
  val ()=font_span_set_part(layout,index,row)
in None_vt() end end
fun skipped(layout: !FontSpanLayout,index: int,item: NativeTextItem,reason: FontSpanFailure): Option_vt(FontSpanFailure) = let
  val ()=font_span_set_part(layout,index,skip_part(item))
in Some_vt(reason) end
fun logged(layout: !FontSpanLayout,index: int,item: NativeTextItem,result: !FontNativeRead): void = let
  val code=shape_failure_code(result)
in if ine(code,0) then println!("event=native_span_shaping reason_code=",code," detail=",ot_reason(result)," source_start=",item.sourceStart,
  " source_end=",item.sourceEnd," script=",item.script.code) else () end
fun stored(layout: !FontSpanLayout,index: int,item: NativeTextItem,result: FontNativeRead): Option_vt(FontSpanFailure) = let
  val ()=logged(layout,index,item,result)
in case+ result of
  | ~FontNativeShaped(run) => installed(layout,index,item,run)
  | ~FontNativeNoFace() => Some_vt(SpanShaping()) | ~FontNativeCacheError(e) => Some_vt(SpanShaping())
  | ~FontNativePlanError(e) => Some_vt(SpanShaping()) | ~FontNativeTextError(e) => Some_vt(SpanShaping())
  | ~FontNativeRunError(e) => Some_vt(SpanShaping())
  | ~FontNativeUnsupported(s) => skipped(layout,index,item,SpanUnsupported()) end
fun notdef_stored(layout: !FontSpanLayout,index: int,item: NativeTextItem,result: FontNativeRead): Option_vt(FontSpanFailure) = let
  val ()=logged(layout,index,item,result)
in case+ result of
  | ~FontNativeShaped(run) => installed(layout,index,item,run)
  | ~FontNativeNoFace() => skipped(layout,index,item,SpanMissing())
  | ~FontNativeCacheError(e) => skipped(layout,index,item,SpanMissing())
  | ~FontNativePlanError(e) => skipped(layout,index,item,SpanMissing())
  | ~FontNativeTextError(e) => skipped(layout,index,item,SpanMissing())
  | ~FontNativeRunError(e) => skipped(layout,index,item,SpanMissing())
  | ~FontNativeUnsupported(s) => skipped(layout,index,item,SpanUnsupported()) end
fun tab(layout: !FontSpanLayout,index: int,item: NativeTextItem,result: FontNativeRead,pen: llint): Option_vt(FontSpanFailure) =
  case+ stored(layout,index,item,result) of | ~Some_vt(error) => Some_vt(error)
  | ~None_vt() => font_span_tab_place(layout,index,pen)
fun line_end(layout: !FontSpanLayout,index: int,item: NativeTextItem,result: FontNativeRead): Option_vt(FontSpanFailure) =
  case+ stored(layout,index,item,result) of | ~Some_vt(error) => Some_vt(error)
  | ~None_vt() => let val ()=font_span_line_end_place(layout,index) in None_vt() end
fun notdef_face(level: int): FontGlyphFace =
  if ine(imod(level, 2), 0) then GlyphFallbackFace() else GlyphPrimaryFace()
fun notdef_font(level: int, options: FontSpanOptions): int =
  if ine(imod(level, 2), 0) then options.fallback else options.primary
fun notdef(f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,c: !NativeTextContexts,
  layout: !FontSpanLayout,options: FontSpanOptions,index: int,item: NativeTextItem): Option_vt(FontSpanFailure) = let
  val masks: OtShapeMasks= @{initial=1u,medial=2u,final=4u,isolated=8u,mirror=16u}
  val face=notdef_face(item.level) val id=notdef_font(item.level,options)
  val read=font_shape_native_item(f,assets,a,c,item,face,id,ShapeDefaultLanguage(),masks,options.scale)
in notdef_stored(layout,index,item,read) end
fun placed(f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,c: !NativeTextContexts,
  layout: !FontSpanLayout,options: FontSpanOptions,index: int,item: NativeTextItem,pen: llint): Option_vt(FontSpanFailure) =
  case+ font_span_candidate(f,assets,a,item) of
  | SpanTabCandidate() => tab(layout,index,item,font_span_space_shape(f,assets,options),pen)
  | SpanLineEndCandidate() => line_end(layout,index,item,font_span_space_shape(f,assets,options))
  | SpanPrimaryCandidate() => stored(layout,index,item,font_span_shape(f,assets,a,c,item,options))
  | SpanFallbackCandidate() => stored(layout,index,item,font_span_shape(f,assets,a,c,item,options))
  | SpanMissingCandidate() => let val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes)=a
    val ()=println!("event=native_span_coverage first_scalar=",scalar_value(text,item.start))
  in notdef(f,assets,a,c,layout,options,index,item) end
fun pending(error: FontSpanFailure): bool = case+ error of
  | SpanAnalysis() => false | SpanItems() => false | SpanContext() => false | SpanShaping() => false
  | SpanCapacity() => false | SpanOverflow() => false | SpanParagraph() => false
  | SpanMissing() => true | SpanUnsupported() => true
fun walk{n:nat} .<n>. (left: int(n),f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,c: !NativeTextContexts,
  layout: !FontSpanLayout,options: FontSpanOptions,index: int,pen: llint): Option_vt(FontSpanFailure) =
  if pen > 2147483647LL then Some_vt(SpanOverflow()) else if left = 0 then None_vt() else let
    val+ FontSpanLayout(analysis,items,runs,rows,order,count,width,direction)=layout val item=native_text_items_at(items,index)
  in case+ placed(f,assets,a,c,layout,options,index,item,pen) of
    | ~Some_vt(error) => if pending(error) then walk(left-1,f,assets,a,c,layout,options,iadd(index,1),pen)
      else Some_vt(error)
    | ~None_vt() => let val part=font_span_part(layout,index)
      in walk(left-1,f,assets,a,c,layout,options,iadd(index,1),pen+g0int2int_int_llint(part.width)) end end
implement font_span_fill(f,assets,a,c,layout,options) = let
  val+ FontSpanLayout(analysis,items,runs,rows,order,n,width,direction)=layout
in walk(n,f,assets,a,c,layout,options,0,0LL) end
