staload "mem.sats"
staload "data_font/resources/font.sats"
staload "data_font/text/font_text_types.sats"
staload "data_font/text/span/font_span_types.sats"
staload "data_font/native/text/native_text_assets_types.sats"
staload "core_render/render.sats"
(* Initialization shell only. On success the session allocates its own unique
   primary/fallback face IDs from the global registry (FontNativeRun contract). *)
fun font_text_enable(f: !Font,location: NativeAssetLocation): FontTextEnable
fun font_text_active(f: !Font): bool
fun font_text_width(f: !Font,b: !Buf,length: int): FontTextResult
(* Serialized paragraph base direction: value is 0 (LTR) or 1 (RTL). *)
fun font_text_direction_code(f: !Font,b: !Buf,length: int): FontTextResult
fun font_text_draw(f: !Font,r: !Rend,b: !Buf,length: int,x: int,y: int,color: uint): FontTextResult
(* Byte-indexed flags: 1 is an EGC boundary, 3 also permits a UAX #14 break. *)
fun font_text_boundaries(f: !Font,b: !Buf,length: int): Buf
fun font_text_wrap_metrics(f: !Font,b: !Buf,length: int): @(Buf,Buf)
(* Transfer a measured cache plan, or shape once on a miss. Caller owns it. *)
fun font_text_row_plan(f: !Font,b: !Buf,length: int): FontSpanRead
