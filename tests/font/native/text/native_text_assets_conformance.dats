#include "data_font/native/text/native_text_assets_internal.hats"
fun good(location: NativeAssetLocation): int = case+ native_text_assets_load(location) of
  | ~NativeAssetsRejected(e) => 1 | ~NativeAssetsAccepted(a) => let
    val+ NativeTextAssets(aux,words,lines,east)=a val+ NativeTextAux(base,s,b,brackets,mirrors)=aux
    val+ NativeTextBase(shape,n,mcm)=base val+ NativeShapeData(db,c,i,j)=shape
    val set=script_data_set(s,1576) val script=script_data_at(s,set,0)
    val ok=ieq(property_value(i,8205),1) andalso ieq(property_value(j,1576),3)
      andalso ieq(property_value(mcm,1620),1) andalso ieq(property_value(mcm,1614),0)
      andalso ieq(script.code,1098015074) andalso ieq(bidi_mirror_codepoint(mirrors,40,1),41)
    val ()=native_text_assets_dispose(a)
  in if ok then 0 else 1 end
fun asset_code(kind: NativeAssetKind): int = case+ kind of
  | AssetGrapheme() => 0 | AssetCategory() => 1 | AssetIgnorable() => 2 | AssetJoining() => 3
  | AssetNormalization() => 4 | AssetModifierMarks() => 5 | AssetScripts() => 6 | AssetExtensions() => 7
  | AssetBidi() => 8 | AssetBrackets() => 9 | AssetMirrors() => 10 | AssetWords() => 11 | AssetLines() => 12 | AssetEastAsian() => 13
fun rejected(location: NativeAssetLocation): int = case+ native_text_assets_load(location) of
  | ~NativeAssetsRejected(e) => (if ieq(asset_code(e.asset),9) then 0 else 1)
  | ~NativeAssetsAccepted(a) => let val ()=native_text_assets_dispose(a) in 1 end
fun empty(location: NativeAssetLocation): int = case+ native_text_assets_load(location) of
  | ~NativeAssetsRejected(e) => (if ieq(asset_code(e.asset),0) then 0 else 1)
  | ~NativeAssetsAccepted(a) => let val ()=native_text_assets_dispose(a) in 1 end
fun cases(): int = if ine(c_argc(),3) then 1 else
  good(@{generated=c_argv(1),source=c_argv(2)})
  +rejected(@{generated=c_argv(1),source="/__anthracite_missing_native_source__"})
  +empty(@{generated="/__anthracite_missing_native_assets__",source=c_argv(2)})
fun ownership(before: int): int = if ieq(before,mem_live()) then 0 else 1
implement main0() = let val before=mem_live() val errors=cases() val buffers=ownership(before)
  val ()=println!("event=native_text_assets errors=",errors," buf_errors=",buffers)
in if igt(iadd(errors,buffers),0) then exit(1) else () end
