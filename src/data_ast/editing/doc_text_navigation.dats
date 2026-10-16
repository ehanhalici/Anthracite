#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "data_ast/document/doc.sats"
staload "data_text/utf8/utf8.sats"
extern fun navigation_failed(): int = "mac#anth_die_int"
fun byte_at(d: !Doc,limit: int,offset: int,relative: int): int =
  if ilt(relative,isub(limit,offset)) then doc_byte(d,iadd(offset,relative)) else 0
fun next(d: !Doc,offset: int,limit: int): int = let
  val window: Utf8Window= @{available=imin(4,isub(limit,offset)),first=doc_byte(d,offset),
    second=byte_at(d,limit,offset,1),third=byte_at(d,limit,offset,2),fourth=byte_at(d,limit,offset,3)}
  val step=utf8_window_step(window,offset)
in case+ step.kind of | Utf8Scalar() => step.next | Utf8Malformed() => step.next | Utf8End() => navigation_failed() end
fun advance{fuel:nat} .<fuel>. (fuel: int(fuel),d: !Doc,start: int,limit: int,count: int): int =
  if ige(start,limit) orelse ile(count,0) then start else if fuel = 0 then navigation_failed()
  else advance(fuel-1,d,next(d,start,limit),limit,isub(count,1))
fun count{fuel:nat} .<fuel>. (fuel: int(fuel),d: !Doc,start: int,limit: int,total: int): int =
  if ige(start,limit) then total else if fuel = 0 then navigation_failed()
  else count(fuel-1,d,next(d,start,limit),limit,iadd(total,1))
implement doc_advance_cps(d,start,limit,n) = advance(MAX_REC_FUEL,d,start,limit,n)
implement doc_codepoints(d,start,limit) = count(MAX_REC_FUEL,d,start,limit,0)
