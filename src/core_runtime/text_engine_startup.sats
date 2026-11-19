staload "data_font/resources/font.sats"
staload "data_font/native/text/native_text_assets_types.sats"
fun workspace_text_location(): NativeAssetLocation
fun workspace_arabic_font_path(): string
fun workspace_primary_font_path(): string
fun workspace_arabic_font_start(f: !Font): void
fun workspace_font_start(f: !Font): bool
(* Unicode assets for a Font whose faces are already loaded, without status
   lines: worker threads must not interleave output with the main thread. *)
fun workspace_worker_text_start(f: !Font): bool
