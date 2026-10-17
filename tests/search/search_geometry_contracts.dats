#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "ui_workspace/search/ui_search.sats"
fun geometry(lh: int,width: int,height: int): int = let
  val g=search_geometry(lh,width,height)
  val controls=ige(g.queryTop,iadd(g.secondY,g.buttonHeight))
    andalso ige(g.statusTop,iadd(g.queryTop,g.queryHeight)) andalso ige(g.resultsTop,iadd(g.statusTop,lh))
  val first=ieq(search_scope_hit(g,8,g.buttonTop),SEARCH_SCOPE_VAULT)
  val second=ieq(search_scope_hit(g,g.secondX,g.secondY),SEARCH_SCOPE_DOCUMENT)
  val gap=ieq(search_scope_hit(g,8,isub(g.queryTop,1)),~1)
  val outside=ieq(search_visible_hit(g,isub(g.resultsTop,1),5),~1)
  val after=ieq(search_visible_hit(g,iadd(g.resultsTop,imul(g.rows,g.rowHeight)),5),~1)
  val hit=if igt(g.rows,0) then ieq(search_visible_hit(g,g.resultsTop,5),5) else true
in if controls andalso first andalso second andalso gap andalso outside andalso after andalso hit then 0 else 1 end
fun sizes{n:nat} .<n>. (left: int(n),lh: int): int =
  if left = 0 then 0 else geometry(lh,160,0)+geometry(lh,160,800)+geometry(lh,280,480)
    +geometry(lh,800,800)+sizes(left-1,iadd(lh,1))
fun timeout_cases(): int = let
  val idle=ieq(search_flash_wait(0L,0L),~1)
  val initial=ieq(search_flash_wait(7L,7L+SEARCH_FLASH_DURATION_NS),1000)
  val rounded=ieq(search_flash_wait(1000000L,1000001L),1)
  val exact=ieq(search_flash_wait(1000001L,1000001L),0)
  val expired=ieq(search_flash_wait(1000002L,1000001L),0)
in if idle andalso initial andalso rounded andalso exact andalso expired then 0 else 1 end
implement main0() = if igt(iadd(sizes(49,12),timeout_cases()),0) then exit(1) else ()
