staload "mem.sats"

(* Caller retains the root and each joined path until its users finish. *)
fun selftest_fixture_open(root: &Buf >> Buf): bool
fun selftest_fixture_path(root: string, relative: string): Buf
