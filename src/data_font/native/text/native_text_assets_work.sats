staload "mem.sats"
staload "data_font/native/shape/native_shape_types.sats"
staload "data_font/native/text/native_text_assets_types.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/unicode/unicode_property.sats"
fun native_asset_path(location: NativeAssetLocation,kind: NativeAssetKind): Buf
fun native_asset_error(kind: NativeAssetKind): NativeAssetError
fun native_text_shape_assets(location: NativeAssetLocation): NativeShapeAssetsRead
fun native_text_asset_base(location: NativeAssetLocation,data: NativeShapeData): NativeTextAssetsRead
fun native_text_asset_scripts(location: NativeAssetLocation,base: NativeTextBase): NativeTextAssetsRead
fun native_text_base_dispose(base: NativeTextBase): void
fun native_text_aux_dispose(aux: NativeTextAux): void
fun native_text_asset_boundaries(location: NativeAssetLocation,aux: NativeTextAux): NativeTextAssetsRead
