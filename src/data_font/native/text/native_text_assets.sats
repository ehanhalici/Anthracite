staload "data_font/native/text/native_text_assets_types.sats"
(* Filesystem shell only: load once, before layout/drawing; owners are shared
   by borrowing and never reread per text span or child document. *)
fun native_text_assets_load(location: NativeAssetLocation): NativeTextAssetsRead
fun native_text_assets_dispose(assets: NativeTextAssets): void
