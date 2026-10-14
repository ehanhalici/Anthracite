#include "data_font/font_native_slot_internal.hats"
fun owned(result: NativeItemShapeRead,token: FontNativeToken): FontNativeRead = case+ result of
  | ~NativeItemShaped(run) => FontNativeShaped(FontNativeRun(run,token))
  | ~NativeItemUnsupported(s) => FontNativeUnsupported(s) | ~NativeItemPlanError(e) => FontNativePlanError(e)
  | ~NativeItemTextError(e) => FontNativeTextError(e) | ~NativeItemRunError(e) => FontNativeRunError(e)
fun cached(cache: !NativeShapeCache,b: !Buf,info: SfntInfo,assets: !NativeTextAssets,
  a: !NativeTextAnalysis,contexts: !NativeTextContexts,item: NativeTextItem,token: FontNativeToken,
  language: OtShapeLanguage,masks: OtShapeMasks,scale: NativeShapeScale): FontNativeRead = let
  val+ NativeShapeCache(m,sub,pos,key)=cache
in if ine(key.font,token.font) then FontNativeCacheError(@{reason=OtReference(),offset=0})
  else owned(native_text_item_shape(b,info,cache,assets,a,contexts,item,language,masks,scale),token) end
fun borrowed(slot: &Option_vt(NativeShapeCache) >> _,b: !Buf,info: SfntInfo,assets: !NativeTextAssets,
  a: !NativeTextAnalysis,contexts: !NativeTextContexts,item: NativeTextItem,token: FontNativeToken,
  language: OtShapeLanguage,masks: OtShapeMasks,scale: NativeShapeScale): FontNativeRead = case+ slot of
  | @Some_vt(cache) => let
    val result=cached(cache,b,info,assets,a,contexts,item,token,language,masks,scale)
    prval ()=fold@(slot)
  in result end
  | @None_vt() => let prval ()=fold@(slot) in FontNativeNoFace() end
implement font_native_slot_shape(slot,b,info,assets,a,contexts,item,token,language,masks,scale) =
  if ilt(token.font,0) then FontNativeCacheError(@{reason=OtReference(),offset=0}) else case+ slot of
  | @Some_vt(cache) => let prval ()=fold@(slot)
    in borrowed(slot,b,info,assets,a,contexts,item,token,language,masks,scale) end
  | ~None_vt() => (case+ native_shape_cache_parse(b,info,token.font) of
    | ~NativeCacheRejected(e) => let val ()=slot := None_vt() in FontNativeCacheError(e) end
    | ~NativeCacheAccepted(cache) => let val ()=slot := Some_vt(cache)
      in borrowed(slot,b,info,assets,a,contexts,item,token,language,masks,scale) end)
