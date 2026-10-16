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
implement main0() = let
  val baseline=mem_live()
  val formats=gpos_test_formats() and values=gpos_test_values()
  val anchors=gpos_test_anchors() and malformed=gpos_test_errors()
  val balanced=ieq(baseline,mem_live())
  val ()=println!("event=gpos_value_conformance format_errors=",formats," value_errors=",values,
    " anchor_errors=",anchors," malformed_errors=",malformed," ownership_balanced=",balanced)
  val errors=iadd(formats+values+anchors+malformed,if balanced then 0 else 1)
in if igt(errors,0) then exit(errors) else () end
