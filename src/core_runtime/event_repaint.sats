staload "core_platform/x11.sats"
datatype Repaint = RepaintNeeded | RepaintClean
fun event_repaint(k: Ev): Repaint
fun repaint_merge(a: Repaint,b: Repaint): Repaint
