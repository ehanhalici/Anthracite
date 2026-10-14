staload "mem.sats"
staload "data_font/font_span_types.sats"
staload "data_font/native_text_assets_types.sats"
staload "data_font/font_text_metrics.sats"
datavtype FontTextCache = FontTextCache of (Buf,FontSpanLayout,int,Option_vt(FontTextCache))
datavtype FontTextSession = FontTextSession of (NativeTextAssets,Option_vt(FontTextCache),int,int,FontTextMetrics)
datatype FontTextEnable = FontTextEnabled | FontTextAlreadyEnabled | FontTextAssetsFailed of NativeAssetError
datatype FontTextResult = FontTextValue of int | FontTextInactive | FontTextFailed of FontSpanFailure
