staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_mark_shared_types.sats"
fun gpos_mark_header(b: !Buf,span: OtSpan,glyphs: int): GposMarkHeaderRead
fun gpos_mark_fields(count: int,role: GposMarkFields): Buf
fun gpos_mark_anchors(b: !Buf,s: OtSpan,count: int,floor: int,role: GposMarkFields,presence: OtAnchorPresence): OtAnchorCacheRead
