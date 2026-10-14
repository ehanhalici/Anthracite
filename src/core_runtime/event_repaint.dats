#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "core_platform/x11.sats"
staload "core_runtime/event_repaint.sats"
implement event_repaint(k) = case+ k of
  | EvNone() => RepaintClean() | EvClose() => RepaintClean()
  | EvSelReq() => RepaintClean()
  | EvExpose() => RepaintNeeded() | EvResize() => RepaintNeeded()
  | EvKey() => RepaintNeeded() | EvDown() => RepaintNeeded()
  | EvUp() => RepaintNeeded() | EvMotion() => RepaintNeeded()
  | EvWheel() => RepaintNeeded() | EvSelNotify() => RepaintNeeded()
implement repaint_merge(a,b) = case+ a of
  | RepaintNeeded() => RepaintNeeded() | RepaintClean() => b
