#include "data_font/native/text/native_text_assets_internal.hats"
fun joining(location: NativeAssetLocation,db: UnicodeDb,c: PropertyMap(6),i: PropertyMap(8)): NativeShapeAssetsRead = let
  val path=native_asset_path(location,AssetJoining()) val result=property_load(buf_cstr(path),JoiningProperty())
  val ()=buf_free(path)
in case+ result of | ~PropertyLoaded(j) => NativeShapeAssetsAccepted(NativeShapeData(db,c,i,j))
  | ~PropertyRejected(e) => let val ()=unicode_dispose(db) and ()=property_dispose(c) and ()=property_dispose(i)
    in NativeShapeAssetsRejected(native_asset_error(AssetJoining())) end end
fun ignored(location: NativeAssetLocation,db: UnicodeDb,c: PropertyMap(6)): NativeShapeAssetsRead = let
  val path=native_asset_path(location,AssetIgnorable()) val result=property_load(buf_cstr(path),IgnorableProperty())
  val ()=buf_free(path)
in case+ result of | ~PropertyLoaded(i) => joining(location,db,c,i)
  | ~PropertyRejected(e) => let val ()=unicode_dispose(db) and ()=property_dispose(c)
    in NativeShapeAssetsRejected(native_asset_error(AssetIgnorable())) end end
fun category(location: NativeAssetLocation,db: UnicodeDb): NativeShapeAssetsRead = let
  val path=native_asset_path(location,AssetCategory()) val result=property_load(buf_cstr(path),CategoryProperty())
  val ()=buf_free(path)
in case+ result of | ~PropertyLoaded(c) => ignored(location,db,c)
  | ~PropertyRejected(e) => let val ()=unicode_dispose(db) in NativeShapeAssetsRejected(native_asset_error(AssetCategory())) end end
implement native_text_shape_assets(location) = let val path=native_asset_path(location,AssetGrapheme())
  val result=unicode_load(buf_cstr(path)) val ()=buf_free(path)
in case+ result of | ~UnicodeDataError() => NativeShapeAssetsRejected(native_asset_error(AssetGrapheme()))
  | ~UnicodeLoaded(db) => category(location,db) end
