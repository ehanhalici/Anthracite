#include "data_font/native_text_assets_internal.hats"
fun load(location: NativeAssetLocation): NativeTextAssetsRead = case+ native_text_shape_assets(location) of
  | ~NativeShapeAssetsRejected(e) => NativeAssetsRejected(e)
  | ~NativeShapeAssetsAccepted(data) => native_text_asset_base(location,data)
implement native_text_assets_load(location) =
  if igt(c_strlen(location.generated),4000) orelse igt(c_strlen(location.source),4000)
  then NativeAssetsRejected(@{asset=AssetGrapheme(),reason=AssetInput(),detail=4000}) else load(location)
implement native_text_aux_dispose(aux) = let val+ ~NativeTextAux(base,s,b,brackets,mirrors)=aux
  val ()=native_text_base_dispose(base) and ()=script_data_dispose(s) and ()=property_dispose(b)
  val ()=bidi_brackets_dispose(brackets)
in bidi_mirrors_dispose(mirrors) end
implement native_text_assets_dispose(assets) = let val+ ~NativeTextAssets(aux,words,lines,east)=assets
  val ()=native_text_aux_dispose(aux) and ()=property_dispose(words) and ()=property_dispose(lines)
in property_dispose(east) end
