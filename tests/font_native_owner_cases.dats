#include "font_native_test.hats"
fun ready(status: FontRunStatus): bool = case+ status of
  | FontRunReady() => true | FontRunFace() => false | FontRunScale() => false
  | FontRunOverflow() => false | FontRunRaster() => false | FontRunGraph() => false
fun stale(status: FontRunStatus): bool = case+ status of
  | FontRunFace() => true | FontRunReady() => false | FontRunScale() => false
  | FontRunOverflow() => false | FontRunRaster() => false | FontRunGraph() => false
fun accepted(result: FontNativeRead): Option_vt(FontNativeRun) = case+ result of
  | ~FontNativeShaped(run) => Some_vt(run) | ~FontNativeNoFace() => None_vt()
  | ~FontNativeCacheError(e) => None_vt() | ~FontNativeUnsupported(s) => None_vt()
  | ~FontNativePlanError(e) => None_vt() | ~FontNativeTextError(e) => None_vt() | ~FontNativeRunError(e) => None_vt()
fun shape(f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,
  item: NativeTextItem,face: FontGlyphFace,id: int): Option_vt(FontNativeRun) = let
  val masks: OtShapeMasks= @{initial=1u,medial=2u,final=4u,isolated=8u,mirror=16u}
in accepted(font_shape_native_item(f,assets,a,contexts,item,face,id,ShapeDefaultLanguage(),masks,@{xPpem=16,yPpem=16})) end
fun ink_count(face: FontGlyphFace): int = case+ face of | GlyphPrimaryFace() => 2 | GlyphFallbackFace() => 4
fun drawn(f: !Font,r: !Rend,run: !FontNativeRun): bool = let
  val+ FontNativeRun(positioned,token)=run
  val expected=ink_count(token.face)
  val result=font_draw_native_run(f,r,run,20.0,40.0,0xFFFFFFFFu)
  val ok=ready(result.status) andalso ieq(result.drawn,expected)
  val ()=if ok then () else println!("event=native_font_draw expected=",expected," drawn=",result.drawn," ready=",ready(result.status))
in ok end
fun blocked(f: !Font,r: !Rend,run: !FontNativeRun): bool = let
  val result=font_draw_native_run(f,r,run,20.0,40.0,0xFFFFFFFFu)
in stale(result.status) andalso ieq(result.drawn,0) end
fun scale(status: FontRunStatus): bool = case+ status of
  | FontRunScale() => true | FontRunReady() => false | FontRunFace() => false
  | FontRunOverflow() => false | FontRunRaster() => false | FontRunGraph() => false
fun resized(f: !Font,run: !FontNativeRun): bool = let
  val ()=font_set_px(f,18) val rejected=scale(font_native_run_check(f,run))
  val ()=font_set_px(f,16)
in rejected andalso ready(font_native_run_check(f,run)) end
fun registry_result(result: FontNativeRead): bool = case+ result of
  | ~FontNativeCacheError(e) => true | ~FontNativeNoFace() => false
  | ~FontNativeShaped(run) => let val ()=font_native_run_dispose(run) in false end
  | ~FontNativeUnsupported(s) => false | ~FontNativePlanError(e) => false
  | ~FontNativeTextError(e) => false | ~FontNativeRunError(e) => false
fun registry(f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,item: NativeTextItem): bool = let
  val masks: OtShapeMasks= @{initial=1u,medial=2u,final=4u,isolated=8u,mirror=16u}
in registry_result(font_shape_native_item(f,assets,a,contexts,item,GlyphPrimaryFace(),53,
  ShapeDefaultLanguage(),masks,@{xPpem=16,yPpem=16})) end
fun reloaded(f: !Font,r: !Rend,primary: !FontNativeRun,fallback: !FontNativeRun): int = let
  val invalid=font_use_file(f,c_argv(2))
  val preserved=not(invalid) andalso ready(font_native_run_check(f,primary))
  val changed=font_use_file(f,c_argv(3))
  val ok=preserved andalso changed andalso blocked(f,r,primary) andalso drawn(f,r,fallback)
in if ok then 0 else 1 end
fun replacement(f: !Font,r: !Rend,assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,
  item: NativeTextItem,primary: !FontNativeRun): int = case+ shape(f,assets,a,contexts,item,GlyphFallbackFace(),52) of
  | ~None_vt() => 1 | ~Some_vt(fresh) => let val errors=reloaded(f,r,primary,fresh)
    val ()=font_native_run_dispose(fresh) in errors end
fun pair(f: !Font,r: !Rend,assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,
  item: NativeTextItem,primary: !FontNativeRun,fallback: !FontNativeRun): int = let
  val original=drawn(f,r,primary) andalso drawn(f,r,fallback)
  val changed=font_use_fallback_file(f,c_argv(4))
  val ok=original andalso changed andalso blocked(f,r,fallback) andalso ready(font_native_run_check(f,primary))
  val replaced=replacement(f,r,assets,a,contexts,item,primary)
in if ok then replaced else iadd(replaced,1) end
fun fallback(f: !Font,r: !Rend,assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,
  item: NativeTextItem,primary: !FontNativeRun): int = case+ shape(f,assets,a,contexts,item,GlyphFallbackFace(),52) of
  | ~None_vt() => 1 | ~Some_vt(run) => let val errors=pair(f,r,assets,a,contexts,item,primary,run)
    val ()=font_native_run_dispose(run) in errors end
fun primary(f: !Font,r: !Rend,assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,
  items: !NativeTextItems): int = case+ shape(f,assets,a,contexts,native_text_items_at(items,0),GlyphPrimaryFace(),51) of
  | ~None_vt() => 1 | ~Some_vt(run) => let
    val stable=resized(f,run) andalso registry(f,assets,a,contexts,native_text_items_at(items,0))
      andalso ready(font_native_run_check(f,run))
    val errors=fallback(f,r,assets,a,contexts,native_text_items_at(items,1),run)
    val ()=font_native_run_dispose(run) in if stable then errors else iadd(errors,1) end
implement native_font_cases(r,assets,a,contexts,items) = let val f=font_open()
  val loaded=font_use_file(f,c_argv(3)) and fb=font_use_fallback_file(f,c_argv(4))
  val ()=font_set_px(f,16)
  val errors=if loaded andalso fb then primary(f,r,assets,a,contexts,items) else 1
  val ()=font_free(f)
in errors end
