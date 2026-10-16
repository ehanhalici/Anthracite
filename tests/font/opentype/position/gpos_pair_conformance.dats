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
staload "data_font/opentype/position/gpos_value_cache_types.sats"
staload "data_font/opentype/position/gpos_value_cache.sats"
staload "data_font/opentype/position/gpos_pair_types.sats"
staload "data_font/opentype/position/gpos_pairs.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/position/gpos_pair_contracts.sats"
staload "os/fs.sats"
datatype TestMode = SyntheticPairs | FontPairs
fun fonts(mode: TestMode): int = case+ mode of
  | SyntheticPairs() => 0 | FontPairs() => gpos_pair_test_font(c_argv(1))
fun run(mode: TestMode): int = let
  val baseline=mem_live()
  val matches=gpos_pair_test_matches() and malformed=gpos_pair_test_errors()
  val stress=gpos_pair_test_stress()
  val font_errors=fonts(mode)
  val balanced=ieq(baseline,mem_live())
  val ()=println!("event=gpos_pair_conformance match_errors=",matches," malformed_errors=",malformed,
    " stress_errors=",stress," font_errors=",font_errors," ownership_balanced=",balanced)
in iadd(matches+malformed+stress+font_errors,if balanced then 0 else 1) end
implement main0() = let
  val errors=if ieq(c_argc(),1) then run(SyntheticPairs())
    else if ieq(c_argc(),2) then run(FontPairs()) else 2
in if igt(errors,0) then exit(errors) else () end
