#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8/utf8.sats"
staload "os/fs.sats"
staload "text/utf8/utf8_contracts.sats"

implement main0() = let
  val before=mem_live()
  val scalars=utf8_test_scalars()
  val storage=utf8_test_storage()
  val balanced=ieq(before,mem_live())
  val ()=println!("event=utf8_conformance valid_scalars=1112064 scalar_errors=",scalars,
    " storage_errors=",storage," ownership_balanced=",balanced)
  val errors=iadd(scalars+storage,if balanced then 0 else 1)
in if igt(errors,0) then exit(errors) else () end
