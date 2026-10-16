staload "data_font/resources/font.sats"
staload "data_font/text/font_text_types.sats"
fun font_text_take(f: !Font): Option_vt(FontTextSession)
fun font_text_put(f: !Font,state: Option_vt(FontTextSession)): void
fun font_text_session_release(state: Option_vt(FontTextSession)): void
