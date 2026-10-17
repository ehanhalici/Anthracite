#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "core_runtime/selftest.sats"

macdef FIXTURE_BYTES = 37

fun check_boundary(): int = let
  val before = mem_live()
  val allocation = buf_make(FIXTURE_BYTES)
  val detects_live_owner = ieq(runtime_selftest_memory_check(before), 0)
  val () = buf_free(allocation)
  val detects_cleanup = ieq(runtime_selftest_memory_check(before), 1)
in
  if detects_live_owner andalso detects_cleanup then 0 else 1
end

implement main0() = let
  val empty_boundary = check_boundary()
  val caller_owned = buf_make(FIXTURE_BYTES)
  val occupied_boundary = check_boundary()
  val () = buf_free(caller_owned)
  val errors = iadd(empty_boundary, occupied_boundary)
  val () = println!("event=selftest_memory_contracts errors=", errors)
in
  if igt(errors, 0) then exit(1) else ()
end
