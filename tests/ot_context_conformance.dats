#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_context_types.sats"
staload "os/fs.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_context.sats"
staload "opentype_fixture.sats"
staload "font_fixture.sats"
staload "ot_context_contracts.sats"

implement main0() = let
  val baseline=mem_live()
  val matches=context_test_match()
  val priority=context_test_priority()
  val malformed=context_test_errors()
  val stress=context_test_stress()
  val balanced=ieq(baseline,mem_live())
  val ()=println!("event=ot_context_conformance match_errors=",matches," priority_errors=",priority,
    " malformed_errors=",malformed," stress_errors=",stress," ownership_balanced=",balanced)
  val errors=iadd(matches+priority+malformed+stress,if balanced then 0 else 1)
in if igt(errors,0) then exit(errors) else () end
