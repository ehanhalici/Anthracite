#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "flag.sats"

implement toggle_of(b) = if b then On else Off

implement is_on(t) = case+ t of
  | On() => true
  | Off() => false

implement is_off(t) = not(is_on(t))

implement toggle_int(t) = if is_on(t) then 1 else 0

implement dir_mark_of(n) =
  if n = 1 then DirYes
  else if n = 0 then DirNo
  else DirAsk

fun dir_mark_code(k: DirMark): int = case+ k of
  | DirYes() => 1
  | DirNo() => 0
  | DirAsk() => 2

implement dir_mark_int(k) = dir_mark_code(k)

implement is_dir_mark(a, b) = dir_mark_code(a) = dir_mark_code(b)
