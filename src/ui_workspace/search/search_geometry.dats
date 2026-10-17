#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/search/ui_search.sats"
macdef SEARCH_PADDING_PIXELS = 8
macdef SEARCH_GAP_PIXELS = 6
macdef SEARCH_HEADER_INSET_PIXELS = 4
macdef SEARCH_BUTTON_LABEL_EMS = 6
macdef NANOSECONDS_PER_MILLISECOND = 1000000L
implement search_geometry(lh0,width,height) = let
  val lh=imax(1,lh0) val top=iadd(UI_TOPBAR_HEIGHT,SEARCH_HEADER_INSET_PIXELS)
  val row=iadd(lh,SEARCH_PADDING_PIXELS) val available=imax(1,isub(width,imul(2,SEARCH_PADDING_PIXELS)))
  val stacked=ilt(available,imul(lh,SEARCH_BUTTON_LABEL_EMS))
  val bw=if stacked then available else idiv(isub(available,SEARCH_PADDING_PIXELS),2)
  val second_x=if stacked then SEARCH_PADDING_PIXELS else iadd(imul(2,SEARCH_PADDING_PIXELS),bw)
  val second_y=if stacked then iadd(top,iadd(row,SEARCH_GAP_PIXELS)) else top
  val query=iadd(second_y,iadd(row,SEARCH_GAP_PIXELS))
  val status=iadd(query,iadd(row,SEARCH_GAP_PIXELS)) val results=iadd(status,iadd(lh,SEARCH_GAP_PIXELS))
in @{buttonTop=top,buttonHeight=row,buttonWidth=bw,secondX=second_x,secondY=second_y,
  queryTop=query,queryHeight=row,statusTop=status,resultsTop=results,rowHeight=row,
  rows=idiv(imax(0,isub(height,results)),row)} end
fun inside(x: int,y: int,left: int,top: int,width: int,height: int): bool =
  ige(x,left) andalso ilt(x,iadd(left,width)) andalso ige(y,top) andalso ilt(y,iadd(top,height))
implement search_scope_hit(g,x,y) =
  if inside(x,y,SEARCH_PADDING_PIXELS,g.buttonTop,g.buttonWidth,g.buttonHeight) then SEARCH_SCOPE_VAULT
  else if inside(x,y,g.secondX,g.secondY,g.buttonWidth,g.buttonHeight) then SEARCH_SCOPE_DOCUMENT else ~1
implement search_visible_hit(g,y,scroll) = let val row=idiv(isub(y,g.resultsTop),g.rowHeight)
in if ilt(y,g.resultsTop) orelse ige(row,g.rows) then ~1 else iadd(scroll,row) end
implement search_flash_wait(now,deadline) =
  if deadline <= 0L then ~1 else if now >= deadline then 0
  else g0int2int_lint_int((min(deadline-now,SEARCH_FLASH_DURATION_NS)+NANOSECONDS_PER_MILLISECOND-1L)/NANOSECONDS_PER_MILLISECOND)
