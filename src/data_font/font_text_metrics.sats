staload "mem.sats"
staload "data_font/font.sats"
datavtype FontTextMetrics = FontTextMetrics of (Buf,Buf,int)
typedef FontTextMetricKey = @{length=int,px=int,primary=int,fallback=int,primaryGeneration=int,fallbackGeneration=int,bucket=int}
fun font_text_metrics_make(): FontTextMetrics
fun font_text_metrics_dispose(m: FontTextMetrics): void
fun font_text_metrics_lookup(m: !FontTextMetrics,f: !Font,b: !Buf,n: int,px: int): Option(int)
fun font_text_metrics_insert(m: &FontTextMetrics >> FontTextMetrics,f: !Font,b: !Buf,n: int,px: int,value: int): void
fun font_text_metric_key(f: !Font,b: !Buf,n: int,px: int): FontTextMetricKey
fun font_text_metric_matches(table: !Buf,arena: !Buf,b: !Buf,key: FontTextMetricKey): bool
