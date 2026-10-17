#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/document/doc_anchor.sats"
macdef ANCHOR_INDEX_HEADER_WORDS = 1
macdef ANCHOR_ENTRY_WORDS = 6
macdef ANCHOR_KIND = 0
macdef ANCHOR_LABEL_START = 1
macdef ANCHOR_LABEL_FINISH = 2
macdef ANCHOR_TARGET_START = 3
macdef ANCHOR_TARGET_FINISH = 4
macdef ANCHOR_MARKER = 5
macdef ANCHOR_BLOCK = 0
macdef ANCHOR_HEADING = 1
typedef AnchorEntry = @{kind=int,labelStart=int,labelFinish=int,target=AnchorTarget}
typedef ParagraphRun = @{parent=int,start=int,finish=int,line=int}
extern fun anchor_abort(): void = "mac#anth_die_void"
fun whitespace(byte: int): bool = ieq(byte,CHAR_SPACE) orelse ieq(byte,CHAR_TAB) orelse ieq(byte,CHAR_LF) orelse ieq(byte,CHAR_CR)
fun id_byte(byte: int): bool = (ige(byte,CHAR_LOWER_A) andalso ile(byte,CHAR_LOWER_Z))
  orelse (ige(byte,CHAR_UPPER_A) andalso ile(byte,CHAR_UPPER_Z))
  orelse (ige(byte,CHAR_ZERO) andalso ile(byte,CHAR_NINE)) orelse ieq(byte,CHAR_MINUS)
fun trim_end{n:nat} .<n>. (left: int(n),d: !Doc,start: int,finish: int): int =
  if finish <= start then start else if left = 0 then finish
  else if whitespace(doc_byte(d,isub(finish,1))) then trim_end(left-1,d,start,isub(finish,1)) else finish
fun label_start{n:nat} .<n>. (left: int(n),d: !Doc,start: int,finish: int): int =
  if finish <= start then start else if left = 0 then finish
  else if id_byte(doc_byte(d,isub(finish,1))) then label_start(left-1,d,start,isub(finish,1)) else finish
fun line_marker(d: !Doc,start: int,finish: int): @(int,int) = let
  val endpos=trim_end(airlock_nat(isub(finish,start)),d,start,finish)
  val label=label_start(airlock_nat(isub(endpos,start)),d,start,endpos)
  val marker=isub(label,1)
  val valid=igt(endpos,label) andalso ige(marker,start) andalso ieq(doc_byte(d,marker),CHAR_CARET)
    andalso (ieq(marker,start) orelse whitespace(doc_byte(d,isub(marker,1))))
in @(if valid then marker else ~1,endpos) end
fun block_rank(kind: NodeKind): int =
  if is_kind(kind,KLi) then 3 else if is_kind(kind,KPara) then 2
  else if is_kind(kind,KQuote) orelse is_kind(kind,KCallout) orelse is_kind(kind,KTable) orelse is_kind(kind,KCode) then 1 else 0
fun stack_trim{n:nat} .<n>. (left: int(n),d: !Doc,stack: !Buf,point: int): void =
  if left = 0 then () else let val length=buf_len(stack)
  in if ieq(length,0) then () else let val node=buf_get32(stack,isub(idiv(length,WORD32_BYTES),1))
    in if ile(doc_node_end(d,node),point) then let val ()=buf_set_len(stack,isub(length,WORD32_BYTES))
      in stack_trim(left-1,d,stack,point) end else () end end
fun stack_push(stack: &Buf >> _,node: int): void = let val length=buf_len(stack)
  val ()=buf_ensure(stack,iadd(length,WORD32_BYTES)) val ()=buf_set32(stack,idiv(length,WORD32_BYTES),node)
in buf_set_len(stack,iadd(length,WORD32_BYTES)) end
fun paragraph_extend(d: !Doc,node: int,run: &ParagraphRun >> _): void =
  if not(is_kind(doc_node_kind(d,node),KPara)) then () else let
    val start=doc_node_start(d,node) val finish=doc_node_end(d,node)
    val parent=doc_node_parent(d,node) val line=doc_line_of(d,start)
    val connected=ieq(parent,run.parent) andalso ieq(line,iadd(run.line,1))
  in run := @{parent=parent,start=if connected then run.start else start,finish=finish,line=doc_line_of(d,imax(start,isub(finish,1)))} end
fun owner_advance{n:nat} .<n>. (fuel: int(n),d: !Doc,stack: &Buf >> _,cursor: &int >> _,point: int,run: &ParagraphRun >> _): void =
  if not(recursion_fuel_available(fuel)) then () else if ige(cursor,doc_nnodes(d)) then ()
  else if igt(doc_node_start(d,cursor),point) then () else let
    val node=cursor val ()=cursor := iadd(cursor,1)
    val ()=stack_trim(airlock_nat(idiv(buf_len(stack),WORD32_BYTES)),d,stack,doc_node_start(d,node))
    val ()=if igt(block_rank(doc_node_kind(d,node)),0) then stack_push(stack,node) else ()
    val ()=paragraph_extend(d,node,run)
  in owner_advance(fuel-1,d,stack,cursor,point,run) end
fun owner_choose{n:nat} .<n>. (left: int(n),d: !Doc,stack: !Buf,marker: int,i: int,best: int,rank: int): int =
  if left = 0 then best else let val node=buf_get32(stack,i) val kind=doc_node_kind(d,node)
    val candidate=block_rank(kind)
  in if is_kind(kind,KCode) andalso ilt(marker,doc_node_end(d,node)) then ~2
    else owner_choose(left-1,d,stack,marker,iadd(i,1),if ige(candidate,rank) then node else best,imax(rank,candidate)) end
fun block_target(d: !Doc,stack: &Buf >> _,cursor: &int >> _,start: int,marker: int,finish: int,run: &ParagraphRun >> _): AnchorTarget = let
  val content=trim_end(airlock_nat(isub(marker,start)),d,start,marker)
  val point=if igt(content,start) then marker else isub(trim_end(airlock_nat(start),d,0,start),1)
  val ()=owner_advance(airlock_nat(MAX_REC_FUEL),d,stack,cursor,point,run)
  val ()=stack_trim(airlock_nat(idiv(buf_len(stack),WORD32_BYTES)),d,stack,point)
  val node=owner_choose(airlock_nat(idiv(buf_len(stack),WORD32_BYTES)),d,stack,marker,0,~1,0)
  val fallback=if ige(point,0) then doc_line_start(d,doc_line_of(d,point)) else start
  val paragraph=ige(node,0) andalso is_kind(doc_node_kind(d,node),KPara)
in @{found=ine(node,~2),start=if paragraph then run.start else if ige(node,0) then doc_node_start(d,node) else fallback,
  finish=if ige(node,0) then doc_node_end(d,node) else finish,marker=marker} end
fun append_entry(index: &Buf >> _,entry: AnchorEntry): void = let
  val length=buf_len(index) val at=idiv(length,WORD32_BYTES)
  val ()=buf_ensure(index,iadd(length,imul(ANCHOR_ENTRY_WORDS,WORD32_BYTES)))
  val ()=buf_set32(index,iadd(at,ANCHOR_KIND),entry.kind)
  val ()=buf_set32(index,iadd(at,ANCHOR_LABEL_START),entry.labelStart)
  val ()=buf_set32(index,iadd(at,ANCHOR_LABEL_FINISH),entry.labelFinish)
  val ()=buf_set32(index,iadd(at,ANCHOR_TARGET_START),entry.target.start)
  val ()=buf_set32(index,iadd(at,ANCHOR_TARGET_FINISH),entry.target.finish)
  val ()=buf_set32(index,iadd(at,ANCHOR_MARKER),entry.target.marker)
in buf_set_len(index,iadd(length,imul(ANCHOR_ENTRY_WORDS,WORD32_BYTES))) end
fun block_entries{n:nat} .<n>. (left: int(n),d: !Doc,index: &Buf >> _,stack: &Buf >> _,cursor: &int >> _,line: int,run: &ParagraphRun >> _): void =
  if left = 0 then () else let
    val start=doc_line_start(d,line)
    val finish=if ilt(iadd(line,1),doc_nlines(d)) then doc_line_start(d,iadd(line,1)) else doc_len(d)
    val (marker,labelFinish)=line_marker(d,start,finish)
    val ()=if ige(marker,0) then let val target=block_target(d,stack,cursor,start,marker,finish,run)
      in if target.found then append_entry(index,@{kind=ANCHOR_BLOCK,labelStart=iadd(marker,1),labelFinish=labelFinish,target=target}) else () end else ()
  in block_entries(left-1,d,index,stack,cursor,iadd(line,1),run) end
fun heading_entries{n:nat} .<n>. (left: int(n),d: !Doc,index: &Buf >> _,i: int): void =
  if left = 0 then () else let
    val ()=if is_heading(doc_node_kind(d,i)) then let
      val start=doc_node_cstart(d,i) val finish=doc_node_cend(d,i)
      val target: AnchorTarget= @{found=true,start=doc_node_start(d,i),finish=imax(doc_node_end(d,i),doc_node_fold_end(d,i)),marker=doc_node_start(d,i)}
    in append_entry(index,@{kind=ANCHOR_HEADING,labelStart=start,labelFinish=trim_end(airlock_nat(isub(finish,start)),d,start,finish),target=target}) end else ()
  in heading_entries(left-1,d,index,iadd(i,1)) end
fun index_prepare(d: !Doc,index: &Buf >> _): void =
  if igt(buf_len(index),0) then () else let
    val ()=buf_ensure(index,imul(ANCHOR_INDEX_HEADER_WORDS,WORD32_BYTES))
    val ()=buf_set_len(index,imul(ANCHOR_INDEX_HEADER_WORDS,WORD32_BYTES))
    var stack=buf_make(0) var cursor: int=0
    var run: ParagraphRun= @{parent= ~2,start=0,finish=0,line= ~2}
    val ()=block_entries(airlock_nat(doc_nlines(d)),d,index,stack,cursor,0,run)
    val ()=buf_free(stack)
  in heading_entries(airlock_nat(doc_nnodes(d)),d,index,0) end
fun label_equal{n:nat} .<n>. (left: int(n),d: !Doc,anchor: !Buf,source: int,query: int): bool =
  if left = 0 then true else ieq(doc_byte(d,source),buf_get(anchor,query))
    andalso label_equal(left-1,d,anchor,iadd(source,1),iadd(query,1))
fun index_find{n:nat} .<n>. (left: int(n),d: !Doc,index: !Buf,anchor: !Buf,offset: int,kind: int,at: int): AnchorTarget =
  if left = 0 then @{found=false,start=0,finish=0,marker=0} else let
    val start=buf_get32(index,iadd(at,ANCHOR_LABEL_START)) val finish=buf_get32(index,iadd(at,ANCHOR_LABEL_FINISH))
    val matches=ieq(buf_get32(index,iadd(at,ANCHOR_KIND)),kind) andalso ieq(isub(finish,start),isub(buf_len(anchor),offset))
      andalso label_equal(airlock_nat(isub(finish,start)),d,anchor,start,offset)
  in if matches then @{found=true,start=buf_get32(index,iadd(at,ANCHOR_TARGET_START)),finish=buf_get32(index,iadd(at,ANCHOR_TARGET_FINISH)),marker=buf_get32(index,iadd(at,ANCHOR_MARKER))}
    else index_find(left-1,d,index,anchor,offset,kind,iadd(at,ANCHOR_ENTRY_WORDS)) end
implement doc_resolve_anchor(d,anchor) =
  if ieq(buf_len(anchor),0) then @{found=true,start=0,finish=doc_len(d),marker=0} else let
    var index=doc_anchor_index_take(d) val ()=index_prepare(d,index)
    val block=ieq(buf_get(anchor,0),CHAR_CARET)
    val count=idiv(isub(idiv(buf_len(index),WORD32_BYTES),ANCHOR_INDEX_HEADER_WORDS),ANCHOR_ENTRY_WORDS)
    val target=index_find(airlock_nat(count),d,index,anchor,if block then 1 else 0,if block then ANCHOR_BLOCK else ANCHOR_HEADING,ANCHOR_INDEX_HEADER_WORDS)
    val ()=doc_anchor_index_put(d,index)
  in target end
