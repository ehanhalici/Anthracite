staload "mem.sats"
staload "data_font/font.sats"
staload "data_text/source_grapheme.sats"
fun font_source_grapheme_query(f: !Font,b: !Buf,length: int,offset: int): Option_vt(SourceBoundaries)
