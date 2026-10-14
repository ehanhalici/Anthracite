#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_values.sats"
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_anchor_cache.sats"
staload "data_font/gpos_cursive_types.sats"
staload "data_font/gpos_cursive.sats"
staload "opentype_fixture.sats"
staload "gpos_cursive_contracts.sats"
implement main0() = let
  val baseline=mem_live()
  val matches=gpos_cursive_test_matches() and malformed=gpos_cursive_test_errors()
  val stress=gpos_cursive_test_stress()
  val balanced=ieq(baseline,mem_live())
  val ()=println!("event=gpos_cursive_conformance match_errors=",matches," malformed_errors=",malformed,
    " stress_errors=",stress," ownership_balanced=",balanced)
  val errors=iadd(matches+malformed+stress,if balanced then 0 else 1)
in if igt(errors,0) then exit(errors) else () end
