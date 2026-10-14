staload "data_font/font.sats"
staload "data_font/font_text_types.sats"
staload "data_font/font_span.sats"
staload "data_font/font_span_types.sats"
staload "data_font/native_text_assets_types.sats"
staload "mem.sats"
fun font_text_cache_release(slot: Option_vt(FontTextCache)): void
fun font_text_cache_prepare(slot: &Option_vt(FontTextCache) >> Option_vt(FontTextCache),f: !Font,assets: !NativeTextAssets,
  b: !Buf,length: int,options: FontSpanOptions): Option_vt(FontSpanFailure)
fun font_text_cache_matches(cache: !FontTextCache,f: !Font,b: !Buf,length: int,px: int): bool
fun font_text_cache_select(slot: Option_vt(FontTextCache),f: !Font,b: !Buf,length: int,px: int):
  @(Option_vt(FontTextCache),Option_vt(FontTextCache))
fun font_text_cache_retain(slot: Option_vt(FontTextCache),count: int,bytes: int): Option_vt(FontTextCache)
