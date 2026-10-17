#include "data_font/native/text/native_text_assets_internal.hats"
fun modifier(location: NativeAssetLocation,data: NativeShapeData,n: NormalizationData): NativeTextAssetsRead = let
  val path=native_asset_path(location,AssetModifierMarks()) val result=property_load(buf_cstr(path),ModifierMarkProperty())
  val ()=buf_free(path)
in case+ result of | ~PropertyLoaded(mcm) => native_text_asset_scripts(location,NativeTextBase(data,n,mcm))
  | ~PropertyRejected(e) => let val ()=native_shape_data_dispose(data) and ()=normalization_dispose(n)
    in NativeAssetsRejected(native_asset_error(AssetModifierMarks())) end end
implement native_text_asset_base(location,data) = let val path=native_asset_path(location,AssetNormalization())
  val result=normalization_load(buf_cstr(path)) val ()=buf_free(path)
in case+ result of | ~NormalizationLoaded(n) => modifier(location,data,n)
  | ~NormalizationRejected(e) => let val ()=native_shape_data_dispose(data)
    in NativeAssetsRejected(native_asset_error(AssetNormalization())) end end
implement native_text_base_dispose(base) = let val+ ~NativeTextBase(data,n,mcm)=base
  val ()=native_shape_data_dispose(data) and ()=normalization_dispose(n)
in property_dispose(mcm) end
