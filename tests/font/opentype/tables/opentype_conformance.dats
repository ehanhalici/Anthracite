#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "font/opentype/tables/opentype_contracts.sats"
implement main0() = let
  val baseline=mem_live()
  val coverage=ot_test_coverages()
  val classes=ot_test_classes()
  val devices=ot_test_devices()
  val mutations=ot_test_mutations()
  val stress=ot_test_stress()
  val balanced=ieq(mem_live(),baseline)
  val ()=println!("event=opentype_common coverage_errors=",coverage," class_errors=",classes,
    " device_errors=",devices," mutation_errors=",mutations," stress_errors=",stress,
    " ownership_balanced=",balanced)
in if igt(coverage+classes+devices+mutations+stress,0) orelse not(balanced) then exit(1) else () end
