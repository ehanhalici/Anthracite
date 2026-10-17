#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "font/opentype/definition/gdef_contracts.sats"
datatype TestMode = CoreContracts | FontContracts
fun fonts(mode: TestMode): int = case+ mode of
  | CoreContracts() => 0
  | FontContracts() => gdef_test_font(c_argv(1),97,769,GlyphBase()) +
      gdef_test_font(c_argv(2),1576,1614,GlyphUnclassified())
fun run(mode: TestMode): int = let
  val baseline=mem_live()
  val metadata=gdef_test_metadata()
  val flags=gdef_test_flags()
  val marks=gdef_test_marks()
  val attach=gdef_test_attach()
  val font_errors=fonts(mode)
  val balanced=ieq(mem_live(),baseline)
  val ()=println!("event=gdef_conformance metadata_errors=",metadata," flag_errors=",flags,
    " mark_errors=",marks," attach_errors=",attach," font_errors=",font_errors," ownership_balanced=",balanced)
in iadd(metadata+flags+marks+attach+font_errors,if balanced then 0 else 1) end
implement main0() = let
  val errors=if ieq(c_argc(),1) then run(CoreContracts())
    else if ieq(c_argc(),3) then run(FontContracts()) else 2
in if igt(errors,0) then exit(errors) else () end
