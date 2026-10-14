#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gsub_single_types.sats"
staload "os/fs.sats"
staload "data_font/gsub_single.sats"
staload "opentype_fixture.sats"
staload "font_fixture.sats"
staload "gsub_single_contracts.sats"

datatype TestMode = SyntheticSingles | FontSingles
fun fonts(mode: TestMode): int = case+ mode of
  | SyntheticSingles() => 0
  | FontSingles() => single_test_font(c_argv(1),SingleLatin())+single_test_font(c_argv(2),SingleArabic())
fun run(mode: TestMode): int = let
  val baseline=mem_live()
  val formats=single_test_formats()
  val mutations=single_test_mutations()
  val stress=single_test_stress()
  val font_errors=fonts(mode)
  val balanced=ieq(mem_live(),baseline)
  val ()=println!("event=gsub_single_conformance format_errors=",formats," mutation_errors=",mutations,
    " stress_errors=",stress," font_errors=",font_errors," ownership_balanced=",balanced)
in iadd(formats+mutations+stress+font_errors,if balanced then 0 else 1) end
implement main0() = let
  val errors=if ieq(c_argc(),1) then run(SyntheticSingles())
    else if ieq(c_argc(),3) then run(FontSingles()) else 2
in if igt(errors,0) then exit(errors) else () end
