staload "mem.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_font/resources/font.sats"
staload "data_font/resources/font_hit.sats"
staload "data_font/resources/font_paint.sats"
staload "core_render/render.sats"
fun visual_plan_paint(f: !Font,r: !Rend,rows: !VisualRows,index: int,paint: TextPaint,
  colx: int,y: int,color: uint,scratch: &Buf >> _): int
fun visual_plan_query(f: !Font,rows: !VisualRows,index: int,colx: int,query: TextQuery,scratch: &Buf >> _): @{base=int,value=int}
