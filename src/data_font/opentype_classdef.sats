staload "mem.sats"
staload "data_font/opentype_types.sats"
fun ot_classdef_parse(b: !Buf,span: OtSpan,glyphs: int): OtClassRead
fun ot_classdef_value(b: !Buf,classes: OtClassInfo,glyph: int): int
