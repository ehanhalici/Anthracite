staload "mem.sats"
staload "data_font/native_shape_types.sats"
staload "data_text/normalization_types.sats"
staload "data_text/unicode_property.sats"
staload "data_text/script_data_types.sats"
staload "data_text/bidi_bracket_data.sats"
staload "data_text/bidi_mirror.sats"
datatype NativeAssetKind = AssetGrapheme | AssetCategory | AssetIgnorable | AssetJoining
  | AssetNormalization | AssetModifierMarks | AssetScripts | AssetExtensions | AssetBidi | AssetBrackets | AssetMirrors
  | AssetWords | AssetLines | AssetEastAsian
datatype NativeAssetFailure = AssetInput | AssetData
typedef NativeAssetLocation = @{generated=string,source=string}
typedef NativeAssetError = @{asset=NativeAssetKind,reason=NativeAssetFailure,detail=int}
datavtype NativeTextBase = NativeTextBase of (NativeShapeData,NormalizationData,PropertyMap(9))
datavtype NativeTextAux = NativeTextAux of (NativeTextBase,ScriptData,PropertyMap(2),BidiBrackets,BidiMirrors)
datavtype NativeTextAssets = NativeTextAssets of (NativeTextAux,PropertyMap(1),PropertyMap(4),PropertyMap(5))
datavtype NativeTextAssetsRead = NativeAssetsAccepted of NativeTextAssets | NativeAssetsRejected of NativeAssetError
datavtype NativeShapeAssetsRead = NativeShapeAssetsAccepted of NativeShapeData | NativeShapeAssetsRejected of NativeAssetError
