#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_values.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/position/gpos_value_contracts.sats"
staload "data_font/opentype/position/gpos_single_types.sats"
staload "data_font/opentype/position/gpos_single.sats"
staload "font/opentype/position/gpos_single_contracts.sats"
staload "os/fs.sats"
datatype TestMode = SyntheticPositions | FontPositions
fun fonts(mode: TestMode): int = case+ mode of
  | SyntheticPositions() => 0 | FontPositions() => gpos_single_test_font(c_argv(1))
fun run(mode: TestMode): int = let
  val baseline=mem_live()
  val matches: int=gpos_single_test_matches() and malformed: int=gpos_single_test_errors()
  val stress: int=gpos_single_test_stress()
  val font_errors=fonts(mode)
  val balanced=ieq(baseline,mem_live())
  val ()=println!("event=gpos_single_conformance match_errors=",matches," malformed_errors=",malformed,
    " stress_errors=",stress," font_errors=",font_errors," ownership_balanced=",balanced)
in iadd(iadd(matches,malformed),iadd(stress,iadd(font_errors,if balanced then 0 else 1))) end
implement main0() = let
  val errors=if ieq(c_argc(),1) then run(SyntheticPositions())
    else if ieq(c_argc(),2) then run(FontPositions()) else 2
in if igt(errors,0) then exit(errors) else () end
