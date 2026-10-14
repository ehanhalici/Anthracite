staload "mem.sats"
staload "data_ast/doc.sats"
staload "data_font/font.sats"
typedef VisualPoint = @{x=int,y=int}
fun visual_caret_point(f: !Font,d: !Doc,colx: int,oy: int,scroll: int,lh: int,scratch: &Buf >> _): VisualPoint
fun visual_click_source(f: !Font,d: !Doc,x: int,y: int,colx: int,oy: int,scroll: int,lh: int,scratch: &Buf >> _): int
