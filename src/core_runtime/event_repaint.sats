staload "core_platform/x11.sats"
macdef EVENT_DRAIN_BATCH_LIMIT = 64
datatype Repaint = RepaintNeeded | RepaintClean
fun event_repaint(k: Ev): Repaint
fun repaint_merge(a: Repaint,b: Repaint): Repaint
fun event_batch_has_budget(batch_left: int, pending: int): bool
