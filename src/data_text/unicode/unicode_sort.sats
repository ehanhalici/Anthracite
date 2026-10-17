staload "mem.sats"
(* Stable three-byte radix ordering of nonnegative Unicode scalar keys.
   Row width/key column are numeric word offsets, not semantic modes. *)
fun unicode_rows_sort(rows: !Buf, count: int, width: int, key_column: int): void
(* Stable full-word ordering for nonnegative signed 32-bit serialization keys. *)
fun word_rows_sort(rows: !Buf, count: int, width: int, key_column: int): void
