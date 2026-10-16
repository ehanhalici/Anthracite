#include "data_font/native/text/native_text_assets_internal.hats"
fun east(location: NativeAssetLocation,aux: NativeTextAux,words: PropertyMap(1),lines: PropertyMap(4)): NativeTextAssetsRead = let
  val path=native_asset_path(location,AssetEastAsian()) val result=property_load(buf_cstr(path),EastAsianProperty())
  val ()=buf_free(path)
in case+ result of | ~PropertyLoaded(east) => NativeAssetsAccepted(NativeTextAssets(aux,words,lines,east))
  | ~PropertyRejected(e) => let val ()=native_text_aux_dispose(aux) and ()=property_dispose(words) and ()=property_dispose(lines)
    in NativeAssetsRejected(native_asset_error(AssetEastAsian())) end end
fun lines(location: NativeAssetLocation,aux: NativeTextAux,words: PropertyMap(1)): NativeTextAssetsRead = let
  val path=native_asset_path(location,AssetLines()) val result=property_load(buf_cstr(path),LineProperty()) val ()=buf_free(path)
in case+ result of | ~PropertyLoaded(lines) => east(location,aux,words,lines)
  | ~PropertyRejected(e) => let val ()=native_text_aux_dispose(aux) and ()=property_dispose(words)
    in NativeAssetsRejected(native_asset_error(AssetLines())) end end
implement native_text_asset_boundaries(location,aux) = let val path=native_asset_path(location,AssetWords())
  val result=property_load(buf_cstr(path),WordProperty()) val ()=buf_free(path)
in case+ result of | ~PropertyLoaded(words) => lines(location,aux,words)
  | ~PropertyRejected(e) => let val ()=native_text_aux_dispose(aux)
    in NativeAssetsRejected(native_asset_error(AssetWords())) end end
