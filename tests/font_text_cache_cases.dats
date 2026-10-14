#include "font_native_test.hats"
staload "data_font/font_text.sats"
staload "data_font/font_text_types.sats"
staload "data_font/private/font_text_owner.sats"
staload "core_runtime/event_repaint.sats"
staload "core_platform/x11.sats"
extern fun exhausted(): int = "mac#anth_die_int"
fun count{n:nat}{b:bool} .<n>. (fuel: int(n),slot: !option_vt(FontTextCache,b)): int =
  if fuel > 0 then case+ slot of
    | None_vt() => 0 | Some_vt(cache) => let val+ FontTextCache(key,layout,px,tail)=cache
      in iadd(1,count(fuel-1,tail)) end
  else exhausted()
fun entries(f: !Font): int = let val state=font_text_take(f)
  val total=case+ state of | None_vt() => 0 | Some_vt(session) => let
    val+ FontTextSession(assets,cache,primary,fallback,metrics)=session
  in count(airlock_nat(129),cache) end
  val ()=font_text_put(f,state)
in total end
fun fill{n:nat} .<n>. (left: int(n),f: !Font,b: !Buf,i: int): void =
  if left > 0 then let val ()=buf_set(b,0,iadd(65,imod(i,26)))
    val ()=buf_set(b,1,iadd(65,idiv(i,26))) val result=font_text_width(f,b,2)
  in fill(left-1,f,b,iadd(i,1)) end else ()
implement native_text_cache_cases(f) = let val before=entries(f) val b=buf_make(2)
  val ()=fill(airlock_nat(3),f,b,0) val warm=entries(f)
  val ()=fill(airlock_nat(3),f,b,0) val reused=entries(f)
  val ()=fill(airlock_nat(160),f,b,0) val bounded=entries(f) val ()=buf_free(b)
  val errors=if ige(warm,before) andalso ieq(warm,reused) andalso ieq(bounded,128) then 0 else 1
  val ()=println!("event=native_text_cache errors=",iadd(errors,0)," entries=",bounded)
in errors end
