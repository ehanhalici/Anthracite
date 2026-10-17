staload "mem.sats"
staload "data_font/text/span/font_span_types.sats"
staload "data_font/native/text/native_text_assets_types.sats"
staload "data_font/text/font_text_metrics.sats"
datavtype FontTextCache = FontTextCache of (Buf,FontSpanLayout,int,Option_vt(FontTextCache))
datavtype FontTextSession = FontTextSession of (NativeTextAssets,Option_vt(FontTextCache),int,int,FontTextMetrics)
datavtype FontTextEnable = FontTextEnabled | FontTextAlreadyEnabled | FontTextAssetsFailed of NativeAssetError
datavtype FontTextResult = FontTextValue of int | FontTextInactive | FontTextFailed of FontSpanFailure
