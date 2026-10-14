#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "core_platform/x11.sats"
staload "core_runtime/event_repaint.sats"
extern fun native_event_repaint_cases(): int = "ext#native_event_repaint_cases"
fun clean(r: Repaint): bool = case+ r of | RepaintClean() => true | RepaintNeeded() => false
fun expected(k: Ev): int = if clean(event_repaint(k)) then 0 else 1
implement native_event_repaint_cases() = let
  val ignored=expected(EvNone())+expected(EvClose())+expected(EvSelReq())
  val repaint=expected(EvExpose())+expected(EvResize())+expected(EvKey())+expected(EvDown())
    +expected(EvUp())+expected(EvMotion())+expected(EvWheel())+expected(EvSelNotify())
  val merged=not(clean(repaint_merge(RepaintNeeded(),RepaintClean())))
    andalso not(clean(repaint_merge(RepaintClean(),RepaintNeeded())))
  val errors=if ignored = 0 andalso repaint = 8 andalso merged then 0 else 1
  val ()=println!("event=event_repaint errors=",iadd(errors,0))
in errors end
