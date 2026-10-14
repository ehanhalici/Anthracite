#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
staload "glyph_run_contracts.sats"
implement main0() = let
  val baseline=mem_live()
  val basic=run_test_basic() and ligatures=run_test_ligatures()
  val positions=run_test_positions() and stress=run_test_stress()
  val balanced=ieq(baseline,mem_live())
  val ()=println!("event=glyph_run_conformance basic_errors=",basic," ligature_errors=",ligatures,
    " position_errors=",positions," stress_errors=",stress," ownership_balanced=",balanced)
  val errors=iadd(basic+ligatures+positions+stress,if balanced then 0 else 1)
in if igt(errors,0) then exit(errors) else () end
