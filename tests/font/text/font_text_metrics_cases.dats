#include "font/native/ownership/font_native_test.hats"
staload "data_font/text/font_text_metrics.sats"
extern fun native_text_metrics_cases(f: !Font): int = "ext#native_text_metrics_cases"
fun hit(result: Option_vt(int),value: int): bool = case+ result of
  | ~None_vt() => false | ~Some_vt(actual) => ieq(actual,value)
fun absent(result: Option_vt(int)): bool = case+ result of | ~None_vt() => true | ~Some_vt(value) => false
fun collision(m: &FontTextMetrics >> FontTextMetrics,f: !Font): int = let
  val a=buf_make(2) val b=buf_make(2)
  val ()=buf_set(a,0,65) val ()=buf_set(a,1,97) val ()=buf_set(b,0,66) val ()=buf_set(b,1,66)
  val ()=font_text_metrics_insert(m,f,a,2,16,123)
  val matched=hit(font_text_metrics_lookup(m,f,a,2,16),123)
    andalso absent(font_text_metrics_lookup(m,f,b,2,16)) andalso absent(font_text_metrics_lookup(m,f,a,2,24))
  val ()=font_text_metrics_insert(m,f,b,2,16,456)
  val replaced=hit(font_text_metrics_lookup(m,f,a,2,16),123) andalso hit(font_text_metrics_lookup(m,f,b,2,16),456)
  val ()=buf_free(a) val ()=buf_free(b)
in if matched andalso replaced then 0 else 1 end
fun fill{n:nat} .<n>. (left: int(n),m: &FontTextMetrics >> FontTextMetrics,f: !Font,b: !Buf): void =
  if left = 0 then () else let val ()=font_text_metrics_insert(m,f,b,1024,16,789)
  in fill(left-1,m,f,b) end
fun pair(b: !Buf,i: int,choice: int): void = let
  val ()=buf_set(b,i,if ieq(choice,0) then 65 else 66)
in buf_set(b,iadd(i,1),if ieq(choice,0) then 97 else 66) end
fun collision_key(b: !Buf,i: int): void = let
  val ()=pair(b,0,imod(i,2)) val ()=pair(b,2,imod(idiv(i,2),2))
in pair(b,4,imod(idiv(i,4),2)) end
fun populate{n:nat} .<n>. (left: int(n),m: &FontTextMetrics >> FontTextMetrics,f: !Font,b: !Buf,i: int): void =
  if left = 0 then () else let val ()=collision_key(b,i)
    val ()=font_text_metrics_insert(m,f,b,6,16,iadd(100,i))
  in populate(left-1,m,f,b,iadd(i,1)) end
fun check{n:nat} .<n>. (left: int(n),m: !FontTextMetrics,f: !Font,b: !Buf,i: int): int =
  if left = 0 then 0 else let val ()=collision_key(b,i)
    val error=if hit(font_text_metrics_lookup(m,f,b,6,16),iadd(100,i)) then 0 else 1
  in iadd(error,check(left-1,m,f,b,iadd(i,1))) end
fun ways(m: &FontTextMetrics >> FontTextMetrics,f: !Font): int = let val b=buf_make(6)
  val ()=populate(airlock_nat(4),m,f,b,0) val errors=check(airlock_nat(4),m,f,b,0)
  val ()=populate(airlock_nat(1),m,f,b,4) val ()=collision_key(b,4)
  val accepted=hit(font_text_metrics_lookup(m,f,b,6,16),104) val ()=buf_free(b)
in iadd(errors,if accepted then 0 else 1) end
fun arena(m: &FontTextMetrics >> FontTextMetrics,f: !Font): int = let val b=buf_make(1024) val ()=buf_zero(b)
  val before=mem_live() val ()=fill(airlock_nat(2050),m,f,b)
  val bounded=ieq(mem_live(),before) andalso hit(font_text_metrics_lookup(m,f,b,1024,16),789)
  val reload=font_use_file(f,c_argv(3))
  val stale=absent(font_text_metrics_lookup(m,f,b,1024,16)) val ()=buf_free(b)
in if bounded andalso reload andalso stale then 0 else 1 end
implement native_text_metrics_cases(f) = let val before=mem_live() var m=font_text_metrics_make()
  val errors=iadd(iadd(collision(m,f),ways(m,f)),arena(m,f)) val ()=font_text_metrics_dispose(m)
  val result=iadd(errors,if ieq(mem_live(),before) then 0 else 1)
  val ()=println!("event=native_text_metrics errors=",result)
in result end
