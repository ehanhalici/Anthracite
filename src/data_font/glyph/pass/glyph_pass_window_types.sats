staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
datavtype GlyphContextWindow = GlyphContextWindow of (Buf,Buf,OtContextLimits,int)
datatype GlyphWindowStatus = WindowReady | WindowSkipped | WindowDomain | WindowReference | WindowCapacity
typedef GlyphWindowSpan = @{status=GlyphWindowStatus,start=int,count=int,input=int}
datavtype GlyphWindowRead = WindowAllocated of GlyphContextWindow | WindowRejected of GlyphWindowStatus
typedef GlyphWindowSelection = @{flags=OtLookupFlags,set=int,selection=GlyphSelection}
