#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_ast/layout/visual_rows.sats"
implement visual_rows_dispose(rows) = let val+ ~VisualRows(text,map,lines,data,n,key)=rows
  val ()=buf_free(text) val ()=buf_free(map) val ()=buf_free(lines)
in buf_free(data) end
fun projection(a: VisualProjection,b: VisualProjection): bool = case+ a of
  | VisualSource() => (case+ b of | VisualSource() => true | VisualRendered() => false)
  | VisualRendered() => (case+ b of | VisualSource() => false | VisualRendered() => true)
implement visual_rows_matches(rows,k) = let val+ VisualRows(t,m,l,d,n,a)=rows
in ieq(a.version,k.version) andalso ieq(a.width,k.width) andalso ieq(a.px,k.px)
  andalso ieq(a.height,k.height) andalso ieq(a.ascent,k.ascent)
  andalso ieq(a.primary,k.primary) andalso ieq(a.fallback,k.fallback)
  andalso ieq(a.primaryGeneration,k.primaryGeneration) andalso ieq(a.fallbackGeneration,k.fallbackGeneration)
  andalso projection(a.projection,k.projection) end
implement visual_rows_count(rows,line) = let val+ VisualRows(t,m,l,d,n,k)=rows
in isub(buf_get32(l,iadd(line,1)),buf_get32(l,line)) end
implement visual_rows_at(rows,i) = let
  val+ VisualRows(t,m,l,d,n,k)=rows
  val base=imul(i,VISUAL_ROW_WORDS)
in @{start=buf_get32(d,iadd(base,VISUAL_ROW_START)),finish=buf_get32(d,iadd(base,VISUAL_ROW_FINISH)),
  width=buf_get32(d,iadd(base,VISUAL_ROW_WIDTH)),line=buf_get32(d,iadd(base,VISUAL_ROW_LINE)),
  ordinal=buf_get32(d,iadd(base,VISUAL_ROW_ORDINAL))} end
implement visual_rows_offset(rows,source) = let val+ VisualRows(t,m,l,d,n,k)=rows in buf_get32(m,source) end
extern fun capacity(rows: &VisualRows >> VisualRows): void = "mac#anth_die_void"
fun append(rows: &VisualRows >> VisualRows,row: VisualRow): void = let val+ ~VisualRows(t,m,l,old,n,k)=rows var d: Buf=old
  val o=imul(n,VISUAL_ROW_WORDS)
  val ()=buf_ensure(d,imul(iadd(o,VISUAL_ROW_WORDS),WORD32_BYTES))
  val ()=buf_set32(d,iadd(o,VISUAL_ROW_START),row.start)
  val ()=buf_set32(d,iadd(o,VISUAL_ROW_FINISH),row.finish)
  val ()=buf_set32(d,iadd(o,VISUAL_ROW_WIDTH),row.width)
  val ()=buf_set32(d,iadd(o,VISUAL_ROW_LINE),row.line)
  val ()=buf_set32(d,iadd(o,VISUAL_ROW_ORDINAL),row.ordinal)
in rows := VisualRows(t,m,l,d,iadd(n,1),k) end
implement visual_rows_append(rows,row) = let val+ VisualRows(t,m,l,data,n,k)=rows
in if ige(n,VISUAL_ROW_MAX_COUNT) then capacity(rows) else append(rows,row) end
extern fun exhausted(): int = "mac#anth_die_int"
fun search{n:nat} .<n>. (left: int(n),rows: !VisualRows,x: int,lo: int,hi: int): int =
  if left = 0 then exhausted() else if ige(lo,hi) then imax(0,isub(lo,1)) else let
    val mid=iadd(lo,idiv(isub(hi,lo),2)) val row=visual_rows_at(rows,mid)
  in if ile(row.start,x) then search(left-1,rows,x,iadd(mid,1),hi) else search(left-1,rows,x,lo,mid) end
implement visual_rows_find(rows,offset) = let val+ VisualRows(t,m,l,d,n,k)=rows
in search(airlock_nat(VISUAL_ROW_SEARCH_FUEL),rows,offset,0,n) end
