staload "mem.sats"
staload "data_font/font.sats"
staload "data_font/font_run.sats"
staload "data_font/font_span_types.sats"
staload "data_font/native_text_assets_types.sats"
staload "data_font/native_shape_types.sats"
staload "core_render/render.sats"
typedef FontSpanOptions = @{primary=int,fallback=int,scale=NativeShapeScale}
(* One paragraph/line. The caller owns the source and Font. Both measurement
   and rendering consume this same immutable positioned layout. *)
fun font_span_make(f: !Font,assets: !NativeTextAssets,source: !Buf,length: int,options: FontSpanOptions): FontSpanRead
fun font_span_width(layout: !FontSpanLayout): int
fun font_span_direction(layout: !FontSpanLayout): int
fun font_span_draw(f: !Font,r: !Rend,layout: !FontSpanLayout,x: double,baseline: double,color: uint): FontRunStatus
fun font_span_dispose(layout: FontSpanLayout): void
fun font_span_check(f: !Font,layout: !FontSpanLayout): FontRunStatus
