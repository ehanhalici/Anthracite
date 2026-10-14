staload "mem.sats"
staload "data_font/font.sats"
staload "data_font/font_run.sats"
staload "data_font/font_native_types.sats"
staload "data_font/font_span_types.sats"
staload "core_render/render.sats"
fun font_span_runs_make(count: int): FontSpanRuns
fun font_span_runs_put(runs: !FontSpanRuns,index: int,run: FontNativeRun): void
fun font_span_runs_measure(runs: !FontSpanRuns,index: int): FontRunExtent
fun font_span_runs_check(runs: !FontSpanRuns,index: int,f: !Font): FontRunStatus
fun font_span_runs_draw(runs: !FontSpanRuns,index: int,f: !Font,r: !Rend,x: double,y: double,color: uint): FontRunExtent
fun font_span_runs_dispose(runs: FontSpanRuns): void
