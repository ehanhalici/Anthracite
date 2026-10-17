#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_engine.sats"
staload "data_text/normalization/normalization_data.sats"
typedef CompositionState = @{starter=int, previous=int, output=int}

fun candidate(data: !NormalizationData, values: !Buf, cp: int, ccc: int, state: CompositionState): int =
  if ilt(state.starter,0) orelse not(ieq(state.previous,0) orelse ilt(state.previous,ccc)) then ~1
  else normalization_compose_pair(data,buf_get32(values,state.starter),cp)

fun merge(values: !Buf, starts: !Buf, ends: !Buf, i: int, cp: int, state: CompositionState): CompositionState = let
  val at = state.starter
  val () = buf_set32(values,at,cp)
  val () = buf_set32(starts,at,imin(buf_get32(starts,at),buf_get32(starts,i)))
  val () = buf_set32(ends,at,imax(buf_get32(ends,at),buf_get32(ends,i)))
in state end

fun append(values: !Buf, starts: !Buf, ends: !Buf, i: int, cp: int, ccc: int, state: CompositionState): CompositionState = let
  val start = buf_get32(starts,i)
  val finish = buf_get32(ends,i)
  val () = buf_set32(values,state.output,cp)
  val () = buf_set32(starts,state.output,start)
  val () = buf_set32(ends,state.output,finish)
  val starter = if ieq(ccc,0) then state.output else state.starter
in @{starter=starter,previous=ccc,output=iadd(state.output,1)} end

fun compose_one(data: !NormalizationData, values: !Buf, starts: !Buf, ends: !Buf, i: int, state: CompositionState): CompositionState = let
  val cp = buf_get32(values,i)
  val row = normalization_info(data,cp)
  val combined = candidate(data,values,cp,row.ccc,state)
in if ige(combined,0) then merge(values,starts,ends,i,combined,state)
  else append(values,starts,ends,i,cp,row.ccc,state) end

fun compose {n:nat} .<n>. (
  n: int(n), data: !NormalizationData, values: !Buf, starts: !Buf, ends: !Buf, i: int, state: CompositionState
): int = if n = 0 then state.output else let
  val next = compose_one(data,values,starts,ends,i,state)
in compose(n-1,data,values,starts,ends,iadd(i,1),next) end

implement normalization_compose(data,text) = let
  val+ ~NormalText(values,starts,ends,total,errors) = text
  val actual = compose(airlock_nat(total),data,values,starts,ends,0,@{starter= ~1,previous=0,output=0})
in ScalarText(values,starts,ends,actual,errors) end

implement normalization_finish(text) = let
  val+ ~NormalText(values,starts,ends,total,errors) = text
in ScalarText(values,starts,ends,total,errors) end
