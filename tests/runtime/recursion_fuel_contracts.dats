(* Compile the same private scanner and visibility helper used in production;
   including the whole query implementation would pull unused Doc dependencies. *)
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
#include "search/private/ix_query/skip_whitespace.hats"
#include "data_ast/folding/private/fold_region/mark_hidden_lines.hats"

fun ordinary_scans(): int = let
  val data = buf_make(1)
  val () = buf_set(data, 0, CHAR_SPACE)
  val finish = skip_ws_with_fuel(airlock_nat(2), data, 0, 1)
  val () = mark_hidden_lines_with_fuel(airlock_nat(2), data, 0, 1)
  val ok = ieq(finish, 1) andalso ieq(buf_get(data, 0), 1)
  val () = buf_free(data)
in if ok then 0 else 1 end

fun exhausted_scan(fold: bool): int = let
  val data = buf_make(1)
  val () = if fold then mark_hidden_lines_with_fuel(airlock_nat(0), data, 0, 1)
    else seen_int(skip_ws_with_fuel(airlock_nat(0), data, 0, 1))
  val () = buf_free(data)
in 1 end

implement main0() =
  if c_argc() = 1 then exit(ordinary_scans())
  else exit(exhausted_scan(c_strcmp(c_argv(1), "--fold") = 0))
