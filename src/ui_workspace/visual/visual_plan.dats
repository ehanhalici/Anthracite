#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "os/fs.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_font/resources/font.sats"
staload "data_font/resources/font_hit.sats"
staload "data_font/resources/font_paint.sats"
staload "data_font/text/font_text.sats"
staload "data_font/text/span/font_span.sats"
staload "data_font/text/span/font_span_types.sats"
staload "data_font/text/run/font_run.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "ui_workspace/visual/visual_plan.sats"
macdef SHAPE_UNITS_PER_PIXEL = 64
macdef MAX_QUERY_PIXELS = 33554431
fun fallback(f: !Font,rows: !VisualRows,index: int,scratch: &Buf >> _): FontSpanRead = let
  val row=visual_rows_at(rows,index) val+ VisualRows(text,map,lines,data,count,key,plans)=rows
  val ()=buf_set_len(scratch,0) val ()=buf_append_at(scratch,text,row.start,isub(row.finish,row.start))
in font_text_row_plan(f,scratch,isub(row.finish,row.start)) end
fun from_paragraph(f: !Font,rows: !VisualRows,index: int,paragraph: VisualParagraph): FontSpanRead = let
  val row=visual_rows_at(rows,index) val+ VisualParagraph(analysis,base,length,bytes)=paragraph
  val result=font_text_line_plan(f,analysis,isub(row.start,base),isub(row.finish,base))
  val+ VisualRows(text,map,lines,data,count,key,plans)=rows
  val ()=visual_paragraph_put(plans,row.line,paragraph)
in result end
fun fresh(f: !Font,rows: !VisualRows,index: int,scratch: &Buf >> _): FontSpanRead = let
  val row=visual_rows_at(rows,index) val+ VisualRows(text,map,lines,data,count,key,plans)=rows
  val paragraph=visual_paragraph_take(plans,row.line)
in case+ paragraph of | ~None_vt() => fallback(f,rows,index,scratch)
  | ~Some_vt(analysis) => from_paragraph(f,rows,index,analysis) end
fun ready(status: FontRunStatus): bool = case+ status of | FontRunReady() => true | _ => false
fun acquire(f: !Font,rows: !VisualRows,index: int,scratch: &Buf >> _): FontSpanRead = let
  val+ VisualRows(text,map,lines,data,count,key,plans)=rows val cached=visual_plans_take(plans,index)
in case+ cached of | ~None_vt() => fresh(f,rows,index,scratch)
  | ~Some_vt(layout) => if ready(font_span_check(f,layout)) then FontSpanAccepted(layout)
    else let val ()=font_span_dispose(layout) in fresh(f,rows,index,scratch) end end
fun base_x(layout: !FontSpanLayout,row: VisualRow,width: int,colx: int): int =
  if ieq(font_span_direction(layout),1) then iadd(colx,imax(0,isub(width,row.width))) else colx
fun painted(f: !Font,r: !Rend,rows: !VisualRows,index: int,layout: FontSpanLayout,paint: TextPaint,colx: int,y: int,color: uint): int = let
  val+ VisualRows(text,map,lines,data,count,key,plans)=rows val row=visual_rows_at(rows,index)
  val x=base_x(layout,row,key.width,colx)
  val baseline=case+ paint of | PaintGlyphs(range) => iadd(y,key.ascent) | PaintSelection(range,height) => y
  val status=font_span_paint(f,r,layout,paint,n_i2d(x),n_i2d(baseline),color)
  val units=font_span_width(layout)
  val pixels=iadd(idiv(units,SHAPE_UNITS_PER_PIXEL),if ieq(imod(units,SHAPE_UNITS_PER_PIXEL),0) then 0 else 1)
  val ()=visual_plans_put(plans,index,layout)
in if ready(status) then pixels else 0 end
implement visual_plan_paint(f,r,rows,index,paint,colx,y,color,scratch) =
  case+ acquire(f,rows,index,scratch) of | ~FontSpanRejected(error) => 0
  | ~FontSpanAccepted(layout) => painted(f,r,rows,index,layout,paint,colx,y,color)
fun queried(rows: !VisualRows,index: int,layout: FontSpanLayout,colx: int,query: TextQuery): @{base=int,value=int} = let
  val+ VisualRows(text,map,lines,data,count,key,plans)=rows val row=visual_rows_at(rows,index)
  val base=base_x(layout,row,key.width,colx)
  val local_query=case+ query of | QueryCaret(byte) => QueryCaret(byte)
    | QueryClick(pixel) => QueryClick(imul(imin(MAX_QUERY_PIXELS,imax(0,isub(pixel,base))),SHAPE_UNITS_PER_PIXEL))
  val value=font_span_text_hit(layout,local_query,isub(row.finish,row.start))
  val ()=visual_plans_put(plans,index,layout)
in @{base=base,value=value} end
implement visual_plan_query(f,rows,index,colx,query,scratch) =
  case+ acquire(f,rows,index,scratch) of | ~FontSpanRejected(error) => @{base=colx,value=0}
  | ~FontSpanAccepted(layout) => queried(rows,index,layout,colx,query)
