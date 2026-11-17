#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "core_platform/x11.sats"
staload "core_runtime/event_repaint.sats"

macdef EVENT_VARIANTS = 11

fun event_at(i: int): Ev =
  if ieq(i,0) then EvNone() else if ieq(i,1) then EvClose()
  else if ieq(i,2) then EvResize() else if ieq(i,3) then EvExpose()
  else if ieq(i,4) then EvKey() else if ieq(i,5) then EvDown()
  else if ieq(i,6) then EvUp() else if ieq(i,7) then EvMotion()
  else if ieq(i,8) then EvWheel() else if ieq(i,9) then EvSelReq() else EvSelNotify()

fun needed(r: Repaint): bool = case+ r of
  | RepaintClean() => false | RepaintNeeded() => true

fun events{n:nat} .<n>. (remaining: int(n),i: int): int =
  if remaining > 0 then let
    val expected=ine(i,0) andalso ine(i,1) andalso ine(i,9)
    val error=if needed(event_repaint(event_at(i))) = expected then 0 else 1
  in iadd(error,events(remaining-1,iadd(i,1))) end else 0

fun merges(): bool =
  not(needed(repaint_merge(RepaintClean(),RepaintClean())))
  andalso needed(repaint_merge(RepaintClean(),RepaintNeeded()))
  andalso needed(repaint_merge(RepaintNeeded(),RepaintClean()))
  andalso needed(repaint_merge(RepaintNeeded(),RepaintNeeded()))

fun drain_sim {batch:nat} .<batch>. (
  batch_left: int(batch), pending: &int >> _, dirty: Repaint
): Repaint =
  if batch_left = 0 then dirty
  else if not(event_batch_has_budget(batch_left, pending)) then dirty
  else let
    val k = event_at(imod(pending, EVENT_VARIANTS))
    val () = pending := isub(pending, 1)
  in
    drain_sim(batch_left - 1, pending, repaint_merge(dirty, event_repaint(k)))
  end

fun batch_burst(): int = let
  var pending: int = 100
  val r1 = drain_sim(airlock_nat(EVENT_DRAIN_BATCH_LIMIT), pending, RepaintClean())
  val f1_ok = needed(r1) andalso ieq(pending, isub(100, EVENT_DRAIN_BATCH_LIMIT))
  val r2 = drain_sim(airlock_nat(EVENT_DRAIN_BATCH_LIMIT), pending, RepaintClean())
  val f2_ok = needed(r2) andalso ieq(pending, 0)
  val r3 = drain_sim(airlock_nat(EVENT_DRAIN_BATCH_LIMIT), pending, RepaintClean())
  val f3_ok = not(needed(r3)) andalso ieq(pending, 0)
in
  if f1_ok andalso f2_ok andalso f3_ok then 0 else 1
end

implement main0() = let
  val errors=iadd(events(EVENT_VARIANTS,0),iadd(if merges() then 0 else 1, batch_burst()))
  val ()=println!("event=event_repaint_contracts errors=",errors)
in if igt(errors,0) then exit(1) else () end
