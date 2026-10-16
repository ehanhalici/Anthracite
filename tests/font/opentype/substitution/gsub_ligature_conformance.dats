#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "os/fs.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
staload "data_font/opentype/substitution/gsub_ligatures.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/resources/font_fixture.sats"
staload "font/opentype/substitution/gsub_ligature_contracts.sats"

fun fonts(): int = if ieq(c_argc(),3) then
  ligature_test_font(c_argv(1),LigatureLatin())+ligature_test_font(c_argv(2),LigatureArabic()) else 0
implement main0() = let
  val baseline=mem_live()
  val priority=ligature_test_priority()
  val malformed=ligature_test_errors()
  val stress=ligature_test_stress()
  val font_errors=fonts()
  val balanced=ieq(baseline,mem_live())
  val ()=println!("event=gsub_ligature_conformance priority_errors=",priority," malformed_errors=",malformed,
    " stress_errors=",stress," font_errors=",font_errors," ownership_balanced=",balanced)
  val errors=iadd(priority+malformed+stress+font_errors,if balanced then 0 else 1)
in if igt(errors,0) then exit(errors) else () end
