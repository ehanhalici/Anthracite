#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "os/fs.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/substitution/gsub_reverse_types.sats"
staload "data_font/opentype/substitution/gsub_reverse.sats"
staload "data_font/opentype/coverage/ot_cov_cache_types.sats"
staload "data_font/opentype/coverage/ot_cov_cache.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/resources/font_fixture.sats"
staload "font/opentype/substitution/gsub_reverse_contracts.sats"

implement main0() = let
  val baseline=mem_live()
  val context=reverse_test_context()
  val malformed=reverse_test_errors()
  val cache=reverse_test_cache()
  val stress=reverse_test_stress()
  val balanced=ieq(baseline,mem_live())
  val ()=println!("event=gsub_reverse_conformance context_errors=",context," malformed_errors=",malformed,
    " cache_errors=",cache," stress_errors=",stress," ownership_balanced=",balanced)
  val errors=iadd(context+malformed+cache+stress,if balanced then 0 else 1)
in if igt(errors,0) then exit(errors) else () end
