staload "mem.sats"
staload "data_ast/doc.sats"
staload "data_font/font.sats"
staload "core_render/render.sats"
fun visual_draw_slice(f: !Font,r: !Rend,d: !Doc,a: int,b: int,colx: int,oy: int,scroll: int,lh: int,ph: int,c: uint,scratch: &Buf >> _): int
fun visual_draw_selection(f: !Font,r: !Rend,d: !Doc,colx: int,oy: int,scroll: int,lh: int,scratch: &Buf >> _): void
fun visual_draw_band(f: !Font,r: !Rend,d: !Doc,a: int,b: int,colx: int,oy: int,scroll: int,lh: int,ph: int,
  offset: int,height: int,c: uint,scratch: &Buf >> _): void
