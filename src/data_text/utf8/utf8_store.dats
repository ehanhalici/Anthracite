#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/utf8/utf8_work.sats"
extern fun store_mismatch(): void = "mac#anth_die_void"
fun store_scalar(values: !Buf,starts: !Buf,ends: !Buf,index: int,item: Utf8Unit,start: int): void = let
  val ()=buf_set32(values,index,item.cp)
  val ()=buf_set32(starts,index,start)
in buf_set32(ends,index,item.next) end
fun store {n:nat} .<n>. (n: int(n),source: !Buf,length: int,offset: int,
  values: !Buf,starts: !Buf,ends: !Buf,index: int): void =
  if n = 0 then (if ine(offset,length) then store_mismatch() else ())
  else let
    val item=utf8_unit(utf8_step(source,length,offset),offset)
    val ()=store_scalar(values,starts,ends,index,item,offset)
  in store(n-1,source,length,item.next,values,starts,ends,iadd(index,1)) end
implement utf8_store(source,length,values,starts,ends,count) =
  store(airlock_nat(count),source,length,0,values,starts,ends,0)
