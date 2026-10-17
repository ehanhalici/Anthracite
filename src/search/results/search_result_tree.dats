#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "search/results/search_results.sats"
implement search_row_is_header(meta,row) = ige(row,0) andalso ilt(row,idiv(buf_len(meta),imul(SEARCH_RESULT_WORDS,WORD32_BYTES)))
  andalso ieq(buf_get32(meta,iadd(imul(row,SEARCH_RESULT_WORDS),SEARCH_RESULT_MATCH)),SEARCH_RESULT_FILE_HEADER)
fun walk{n:nat} .<n>. (left: int(n),meta: !Buf,collapsed: !Buf,target: int,i: int,visible: int,hidden: bool): int =
  if left = 0 then (if ilt(target,0) then visible else ~1) else let
    val header=search_row_is_header(meta,i) val skip: bool=if header then false else hidden
    val hide_children=if header then ilt(i,buf_len(collapsed)) andalso ieq(buf_get(collapsed,i),1) else hidden
    val selected: bool=if skip then false else ieq(visible,target)
  in if selected then i
    else walk(left-1,meta,collapsed,target,iadd(i,1),iadd(visible,if skip then 0 else 1),hide_children) end
implement search_visible_count(meta,collapsed) = walk(airlock_nat(idiv(buf_len(meta),imul(SEARCH_RESULT_WORDS,WORD32_BYTES))),meta,collapsed,~1,0,0,false)
implement search_source_row(meta,collapsed,visible) =
  if ilt(visible,0) then ~1 else walk(airlock_nat(idiv(buf_len(meta),imul(SEARCH_RESULT_WORDS,WORD32_BYTES))),meta,collapsed,visible,0,0,false)
implement search_toggle_group(meta,collapsed,row) =
  if not(search_row_is_header(meta,row)) then false else let
    val ()=buf_ensure(collapsed,iadd(row,1))
    val old=buf_get(collapsed,row) val length=buf_len(collapsed)
    val ()=buf_set(collapsed,row,if ieq(old,1) then 0 else 1)
    val ()=buf_set_len(collapsed,imax(length,iadd(row,1)))
  in true end
fun next_result{n:nat} .<n>. (left: int(n),meta: !Buf,row: int,direction: int,count: int): int =
  if left = 0 then ~1 else let
    val candidate=if ilt(row,0) then isub(count,1) else if ige(row,count) then 0 else row
  in if search_row_is_header(meta,candidate) then next_result(left-1,meta,iadd(candidate,direction),direction,count)
    else candidate end
implement search_next_result(meta,current,direction) = let
  val count=idiv(buf_len(meta),imul(SEARCH_RESULT_WORDS,WORD32_BYTES)) val step=if ilt(direction,0) then ~1 else 1
in next_result(airlock_nat(count),meta,iadd(current,step),step,count) end
