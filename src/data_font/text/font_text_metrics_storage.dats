#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef FONT_TEXT_METRICS_MAKE_TABLE_INITIAL_BYTES = 1179648
macdef FONT_TEXT_METRICS_MAKE_BUFFER_INITIAL_BYTES = 2097152

staload "mem.sats"
staload "airlock.sats"
staload "data_font/text/font_text_metrics.sats"
staload "data_font/resources/font.sats"
staload "os/fs.sats"
fun trace(k: FontTextMetricKey): void =
  if c_strcmp(c_getenv("ANTHRACITE_TRACE_METRIC_MISSES"),"1") = 0 then
    println!("event=metric_miss length=",k.length," bucket=",k.bucket) else ()
implement font_text_metrics_make() = let val table=buf_make(FONT_TEXT_METRICS_MAKE_TABLE_INITIAL_BYTES) val ()=buf_zero(table)
in FontTextMetrics(buf_make(FONT_TEXT_METRICS_MAKE_BUFFER_INITIAL_BYTES),table,0) end
implement font_text_metrics_dispose(m) = let val+ ~FontTextMetrics(arena,table,cursor)=m
  val ()=buf_free(arena) in buf_free(table) end
fun slot_key(k: FontTextMetricKey,i: int): FontTextMetricKey =
  @{length=k.length,px=k.px,primary=k.primary,fallback=k.fallback,primaryGeneration=k.primaryGeneration,
    fallbackGeneration=k.fallbackGeneration,bucket=i}
fun find{n:nat} .<n>. (left: int(n),table: !Buf,arena: !Buf,b: !Buf,k: FontTextMetricKey,i: int): Option(int) =
  if left = 0 then None() else
    if font_text_metric_matches(table,arena,b,slot_key(k,i)) then Some(i)
    else find(left-1,table,arena,b,k,iadd(i,1))
implement font_text_metrics_lookup(m,f,b,n,px) =
  if ilt(n,0) orelse igt(n,buf_cap(b)) then None() else let
    val+ FontTextMetrics(arena,table,cursor)=m val k=font_text_metric_key(f,b,n,px)
  in case+ find(airlock_nat(4),table,arena,b,k,imul(k.bucket,4)) of
    | Some(i) => Some(buf_get32(table,iadd(imul(i,9),8)))
    | None() => let val ()=trace(k) in None() end end
fun record(t: !Buf,k: FontTextMetricKey,offset: int,value: int): void = let val o=imul(k.bucket,9)
  val ()=buf_set32(t,iadd(o,1),offset) val ()=buf_set32(t,iadd(o,2),k.length)
  val ()=buf_set32(t,iadd(o,3),k.px) val ()=buf_set32(t,iadd(o,4),k.primaryGeneration)
  val ()=buf_set32(t,iadd(o,5),k.fallbackGeneration) val ()=buf_set32(t,iadd(o,6),k.primary)
  val ()=buf_set32(t,iadd(o,7),k.fallback) val ()=buf_set32(t,iadd(o,8),value)
in buf_set32(t,o,1) end
fun copy{n:nat} .<n>. (left: int(n),arena: !Buf,b: !Buf,offset: int,i: int): void =
  if left = 0 then () else let val ()=buf_set(arena,iadd(offset,i),buf_get(b,i))
  in copy(left-1,arena,b,offset,iadd(i,1)) end
fun vacant{n:nat} .<n>. (left: int(n),table: !Buf,i: int,victim: int): int =
  if left = 0 then victim else if ieq(buf_get32(table,imul(i,9)),0) then i else vacant(left-1,table,iadd(i,1),victim)
fun admission(t: !Buf,arena: !Buf,b: !Buf,k: FontTextMetricKey,cursor: int): FontTextMetricKey = let val base=imul(k.bucket,4)
  val i=case+ find(airlock_nat(4),t,arena,b,k,base) of
    | Some(i) => i | None() => vacant(airlock_nat(4),t,base,iadd(base,imod(cursor,4)))
in slot_key(k,i) end
fun insert(m: &FontTextMetrics >> FontTextMetrics,f: !Font,b: !Buf,n: int,px: int,value: int): void = let
  val+ ~FontTextMetrics(arena,table,cursor)=m
  val start=if igt(cursor,isub(buf_cap(arena),n)) then let val ()=buf_zero(table) in 0 end else cursor
  val k=font_text_metric_key(f,b,n,px) val ()=copy(airlock_nat(n),arena,b,start,0)
  val target=admission(table,arena,b,k,start)
  val ()=record(table,target,start,value) val ()=m := FontTextMetrics(arena,table,iadd(start,n))
in () end
implement font_text_metrics_insert(m,f,b,n,px,value) =
  if ige(n,0) andalso ile(n,buf_cap(b)) andalso ile(n,2097152) andalso ige(value,0) then insert(m,f,b,n,px,value) else ()
