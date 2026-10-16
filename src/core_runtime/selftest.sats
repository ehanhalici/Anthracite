staload "core_platform/platform.sats"
staload "core_render/render.sats"

fun runtime_selftest(p: !Plat, r: !Rend, started_at: lint): int
(* Compare tracked Buf bytes with a caller snapshot at the same owner boundary. *)
fun runtime_selftest_memory_check(before: int): int
