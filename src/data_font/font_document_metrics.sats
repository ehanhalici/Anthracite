staload "data_font/font.sats"
typedef FontDocumentMetrics = @{ascent=int,descent=int,height=int}
fun font_document_metrics(f: !Font): FontDocumentMetrics
fun font_document_line_height(f: !Font,minimum: int): int
