#include "data_font/native_text_assets_internal.hats"
fun mirrors(location: NativeAssetLocation,base: NativeTextBase,s: ScriptData,b: PropertyMap(2),brackets: BidiBrackets): NativeTextAssetsRead = let
  val path=native_asset_path(location,AssetMirrors()) val result=bidi_mirrors_load(buf_cstr(path)) val ()=buf_free(path)
in case+ result of | ~MirrorsLoaded(m) => native_text_asset_boundaries(location,NativeTextAux(base,s,b,brackets,m))
  | ~MirrorsRejected(e) => let val ()=native_text_base_dispose(base) and ()=script_data_dispose(s)
    val ()=property_dispose(b) and ()=bidi_brackets_dispose(brackets)
  in NativeAssetsRejected(native_asset_error(AssetMirrors())) end end
fun brackets(location: NativeAssetLocation,base: NativeTextBase,s: ScriptData,b: PropertyMap(2)): NativeTextAssetsRead = let
  val path=native_asset_path(location,AssetBrackets()) val result=bidi_brackets_load(buf_cstr(path)) val ()=buf_free(path)
in case+ result of | ~BracketsLoaded(brackets) => mirrors(location,base,s,b,brackets)
  | ~BracketsRejected(e) => let val ()=native_text_base_dispose(base) and ()=script_data_dispose(s) and ()=property_dispose(b)
    in NativeAssetsRejected(native_asset_error(AssetBrackets())) end end
fun bidi(location: NativeAssetLocation,base: NativeTextBase,s: ScriptData): NativeTextAssetsRead = let
  val path=native_asset_path(location,AssetBidi()) val result=property_load(buf_cstr(path),BidiProperty()) val ()=buf_free(path)
in case+ result of | ~PropertyLoaded(b) => brackets(location,base,s,b)
  | ~PropertyRejected(e) => let val ()=native_text_base_dispose(base) and ()=script_data_dispose(s)
    in NativeAssetsRejected(native_asset_error(AssetBidi())) end end
implement native_text_asset_scripts(location,base) = let
  val script=native_asset_path(location,AssetScripts()) and ext=native_asset_path(location,AssetExtensions())
  val result=script_data_load(buf_cstr(script),buf_cstr(ext)) val ()=buf_free(script) and ()=buf_free(ext)
in case+ result of | ~ScriptDataAccepted(s) => bidi(location,base,s)
  | ~ScriptDataRejected(e) => let val ()=native_text_base_dispose(base)
    in NativeAssetsRejected(native_asset_error(AssetScripts())) end end
