#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8.sats"
staload "data_text/utf8_work.sats"
extern fun decode_exhausted(): int = "mac#anth_die_int"
implement utf8_unit(step,offset) = case+ step.kind of
  | Utf8End() => @{cp=decode_exhausted(),next=offset,errors=0}
  | Utf8Scalar() => @{cp=step.value,next=step.next,errors=0}
  | Utf8Malformed() => @{cp=65533,next=step.next,errors=1}
fun measure {fuel:nat} .<fuel>. (
  fuel: int(fuel),source: !Buf,length: int,offset: int,count: int,errors: int
): Utf8Measure =
  if ige(offset,length) then @{count=count,errors=errors}
  else if fuel = 0 then @{count=decode_exhausted(),errors=0}
  else let val item=utf8_unit(utf8_step(source,length,offset),offset) in
    measure(fuel-1,source,length,item.next,iadd(count,1),iadd(errors,item.errors)) end
implement utf8_measure(source,length) = measure(airlock_nat(length),source,length,0,0,0)

