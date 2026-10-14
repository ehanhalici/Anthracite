#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_parse.sats"
staload "data_font/ot_layout_tags.sats"
staload "data_font/ot_layout_plan.sats"
staload "data_font/ot_layout_feature_set.sats"
staload "data_font/ot_layout_language.sats"
staload "opentype_fixture.sats"
staload "ot_layout_contracts.sats"

datatype TestMode = SyntheticContracts | FontContracts
fun fonts(mode: TestMode): int = case+ mode of
  | SyntheticContracts() => 0
  | FontContracts() => layout_test_font(c_argv(1),LayoutLatin())+
      layout_test_font(c_argv(2),LayoutArabic())
fun run(mode: TestMode): int = let
  val baseline=mem_live()
  val structure=layout_test_structure()+layout_test_extensions()
  val selection=layout_test_selection()+layout_test_stages()
  val fallback=layout_test_fallback()
  val flags=layout_test_flags()
  val sets=layout_test_sets()
  val capacity=layout_test_capacity()
  val stress=layout_test_stress()
  val params=layout_test_params()
  val font_errors=fonts(mode)
  val balanced=ieq(mem_live(),baseline)
  val ()=println!("event=ot_layout_conformance structure_errors=",structure,
    " selection_errors=",selection," fallback_errors=",fallback," flag_errors=",flags," set_errors=",sets,
    " capacity_errors=",capacity," stress_errors=",stress," params_errors=",params,
    " font_errors=",font_errors," ownership_balanced=",balanced)
in iadd(structure+selection+fallback+flags+sets+capacity+stress+params+font_errors,if balanced then 0 else 1) end
implement main0() = let
  val errors=if ieq(c_argc(),1) then run(SyntheticContracts())
    else if ieq(c_argc(),3) then run(FontContracts()) else 2
in if igt(errors,0) then exit(errors) else () end
