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
staload "data_font/opentype/position/gpos_anchor_cache_types.sats"
staload "data_font/opentype/position/gpos_anchor_cache.sats"
staload "data_font/opentype/position/gpos_mark_shared_types.sats"
staload "data_font/opentype/position/gpos_mark_shared.sats"
staload "data_font/opentype/position/gpos_mark_ligature_types.sats"
staload "data_font/opentype/position/gpos_mark_ligature.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/position/gpos_mark_ligature_contracts.sats"
staload "os/fs.sats"
datatype TestMode = SyntheticLigatureMarks | FontLigatureMarks
fun fonts(mode: TestMode): int = case+ mode of
  | SyntheticLigatureMarks() => 0 | FontLigatureMarks() => mark_ligature_test_fonts(c_argv(1),c_argv(2))
fun run(mode: TestMode): int = let
  val baseline=mem_live()
  val matches=mark_ligature_test_matches() and malformed=mark_ligature_test_errors()
  val stress=mark_ligature_test_stress() and font_errors=fonts(mode)
  val balanced=ieq(baseline,mem_live())
  val ()=println!("event=gpos_mark_ligature_conformance match_errors=",matches," malformed_errors=",malformed,
    " stress_errors=",stress," font_errors=",font_errors," ownership_balanced=",balanced)
in iadd(matches+malformed+stress+font_errors,if balanced then 0 else 1) end
implement main0() = let
  val errors=if ieq(c_argc(),1) then run(SyntheticLigatureMarks())
    else if ieq(c_argc(),3) then run(FontLigatureMarks()) else 2
in if igt(errors,0) then exit(errors) else () end
