staload "mem.sats"
staload "data_font/resources/font.sats"
staload "data_text/grapheme/source_grapheme.sats"
fun font_source_grapheme_query(f: !Font,b: !Buf,length: int,offset: int): Option_vt(SourceBoundaries)
