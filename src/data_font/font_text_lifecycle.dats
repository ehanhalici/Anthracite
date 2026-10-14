#include "data_font/font_text_internal.hats"
implement font_text_session_release(state) = case+ state of
  | ~None_vt() => () | ~Some_vt(session) => let val+ ~FontTextSession(assets,cache,primary,fallback,metrics)=session
    val ()=font_text_metrics_dispose(metrics) val ()=font_text_cache_release(cache) in native_text_assets_dispose(assets) end
fun inactive(state: !Option_vt(FontTextSession)): bool = case+ state of
  | None_vt() => true | Some_vt(session) => false
implement font_text_enable(f,location,primary,fallback) = let val state=font_text_take(f)
  val off=inactive(state) val ()=font_text_put(f,state)
in if not(off) then FontTextAlreadyEnabled() else case+ native_text_assets_load(location) of
  | ~NativeAssetsRejected(error) => FontTextAssetsFailed(error)
  | ~NativeAssetsAccepted(assets) => let
    val ()=font_text_put(f,Some_vt(FontTextSession(assets,None_vt(),primary,fallback,font_text_metrics_make())))
  in FontTextEnabled() end end
