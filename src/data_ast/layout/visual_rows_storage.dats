#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_ast/layout/visual_rows.sats"
implement visual_rows_dispose(rows) = let val+ ~VisualRows(text,map,lines,data,n,key,plans)=rows
  val ()=visual_plans_dispose(plans)
  val ()=buf_free(text) val ()=buf_free(map) val ()=buf_free(lines)
in buf_free(data) end
fun projection(a: VisualProjection,b: VisualProjection): bool = case+ a of
  | VisualSource() => (case+ b of | VisualSource() => true | VisualRendered() => false)
  | VisualRendered() => (case+ b of | VisualSource() => false | VisualRendered() => true)
(* Faces load lazily while shaping. Rows built while a face was not loaded yet
   never needed it (shaping would have loaded it), so a later load of that face
   keeps them valid; any other face change does not. *)
fun same_face(font: int,generation: int,current: int,current_generation: int): bool =
  ilt(font,0) orelse (ieq(font,current) andalso ieq(generation,current_generation))
implement visual_key_context_matches(a,k) = ieq(a.width,k.width) andalso ieq(a.px,k.px)
  andalso ieq(a.sourceStart,k.sourceStart) andalso ieq(a.sourceFinish,k.sourceFinish)
  andalso ieq(a.rawStart,k.rawStart) andalso ieq(a.rawFinish,k.rawFinish)
  andalso ieq(a.height,k.height) andalso ieq(a.ascent,k.ascent)
  andalso same_face(a.primary,a.primaryGeneration,k.primary,k.primaryGeneration)
  andalso same_face(a.fallback,a.fallbackGeneration,k.fallback,k.fallbackGeneration)
  andalso projection(a.projection,k.projection)
implement visual_rows_matches(rows,k) = let val+ VisualRows(t,m,l,d,n,a,plans)=rows
in ieq(a.version,k.version) andalso visual_key_context_matches(a,k) end
implement visual_rows_count(rows,line) = let val+ VisualRows(t,m,l,d,n,k,plans)=rows
in isub(buf_get32(l,iadd(line,1)),buf_get32(l,line)) end
implement visual_rows_at(rows,i) = let
  val+ VisualRows(t,m,l,d,n,k,plans)=rows
  val base=imul(i,VISUAL_ROW_WORDS)
in @{start=buf_get32(d,iadd(base,VISUAL_ROW_START)),finish=buf_get32(d,iadd(base,VISUAL_ROW_FINISH)),
  width=buf_get32(d,iadd(base,VISUAL_ROW_WIDTH)),line=buf_get32(d,iadd(base,VISUAL_ROW_LINE)),
  ordinal=buf_get32(d,iadd(base,VISUAL_ROW_ORDINAL)),px=buf_get32(d,iadd(base,VISUAL_ROW_PX)),
  height=buf_get32(d,iadd(base,VISUAL_ROW_HEIGHT)),ascent=buf_get32(d,iadd(base,VISUAL_ROW_ASCENT)),
  top=buf_get32(d,iadd(base,VISUAL_ROW_TOP))} end
implement visual_rows_offset(rows,source) = let val+ VisualRows(t,m,l,d,n,k,plans)=rows in buf_get32(m,source) end
extern fun capacity(rows: &VisualRows >> VisualRows): void = "mac#anth_die_void"
fun append(rows: &VisualRows >> VisualRows,row: VisualRow): void = let val+ ~VisualRows(t,m,l,old,n,k,plans)=rows var d: Buf=old
  val o=imul(n,VISUAL_ROW_WORDS)
  val ()=buf_ensure(d,imul(iadd(o,VISUAL_ROW_WORDS),WORD32_BYTES))
  val ()=buf_set32(d,iadd(o,VISUAL_ROW_START),row.start)
  val ()=buf_set32(d,iadd(o,VISUAL_ROW_FINISH),row.finish)
  val ()=buf_set32(d,iadd(o,VISUAL_ROW_WIDTH),row.width)
  val ()=buf_set32(d,iadd(o,VISUAL_ROW_LINE),row.line)
  val ()=buf_set32(d,iadd(o,VISUAL_ROW_ORDINAL),row.ordinal)
  val ()=buf_set32(d,iadd(o,VISUAL_ROW_PX),row.px)
  val ()=buf_set32(d,iadd(o,VISUAL_ROW_HEIGHT),row.height)
  val ()=buf_set32(d,iadd(o,VISUAL_ROW_ASCENT),row.ascent)
  val ()=buf_set32(d,iadd(o,VISUAL_ROW_TOP),row.top)
in rows := VisualRows(t,m,l,d,iadd(n,1),k,plans) end
implement visual_rows_append(rows,row) = let val+ VisualRows(t,m,l,data,n,k,plans)=rows
in if ige(n,VISUAL_ROW_MAX_COUNT) then capacity(rows) else append(rows,row) end
extern fun exhausted(): int = "mac#anth_die_int"
fun search{n:nat} .<n>. (left: int(n),rows: !VisualRows,x: int,lo: int,hi: int): int =
  if left = 0 then exhausted() else if ige(lo,hi) then imax(0,isub(lo,1)) else let
    val mid=iadd(lo,idiv(isub(hi,lo),2)) val row=visual_rows_at(rows,mid)
  in if ile(row.start,x) then search(left-1,rows,x,iadd(mid,1),hi) else search(left-1,rows,x,lo,mid) end
implement visual_rows_find(rows,offset) = let val+ VisualRows(t,m,l,d,n,k,plans)=rows
in search(airlock_nat(VISUAL_ROW_SEARCH_FUEL),rows,offset,0,n) end
implement visual_rows_line_pending(rows,line) = let val+ VisualRows(t,m,l,d,n,k,plans)=rows
  val first=buf_get32(l,line)
in ilt(first,n) andalso ilt(first,buf_get32(l,iadd(line,1)))
  andalso ieq(buf_get32(d,iadd(imul(first,VISUAL_ROW_WORDS),VISUAL_ROW_WIDTH)),VISUAL_ROW_PENDING_WIDTH) end
fun pending_word(lines: !Buf): int = isub(idiv(buf_len(lines),WORD32_BYTES),1)
implement visual_rows_pending(rows) = let val+ VisualRows(t,m,l,d,n,k,plans)=rows
in if ile(buf_len(l),0) then 0 else buf_get32(l,pending_word(l)) end
implement visual_rows_set_pending(rows,count) = let val+ VisualRows(t,m,l,d,n,k,plans)=rows
in if ile(buf_len(l),0) then () else buf_set32(l,pending_word(l),count) end
