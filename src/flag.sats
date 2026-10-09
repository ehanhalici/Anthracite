(* Shared two-state flag type. Boolean-like integer arguments (0/1) are
   replaced by this datatype across the code base so that call sites
   cannot pass arbitrary integers where a flag is expected. *)

datatype Toggle = Off | On

fun toggle_of(b: bool): Toggle
fun is_on(t: Toggle): bool
fun is_off(t: Toggle): bool
fun toggle_int(t: Toggle): int

datatype DirMark = DirYes | DirNo | DirAsk

fun dir_mark_of(n: int): DirMark
fun dir_mark_int(k: DirMark): int
fun is_dir_mark(a: DirMark, b: DirMark): bool
