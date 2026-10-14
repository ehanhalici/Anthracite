staload "mem.sats"
staload "data_font/glyph_pass_types.sats"
(* Reusable, linked matching slots. Slot IDs are arena-local; values are stable
   source-run node IDs. Each active context owns its own logical slot chain. *)
datavtype GlyphContextArena = GlyphContextArena of (Buf,int,int)
typedef GlyphContextChain = @{head=int,tail=int,count=int}
typedef GlyphContextSlot = @{status=GlyphPassStatus,id=int}
typedef GlyphContextChainRead = @{status=GlyphPassStatus,chain=GlyphContextChain}
typedef GlyphContextNode = @{status=GlyphPassStatus,node=int}
typedef GlyphContextInsertion = @{node=int,first=int,added=int}
