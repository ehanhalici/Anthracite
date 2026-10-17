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
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/substitution/gsub_sequences.sats"
staload "data_font/opentype/substitution/gsub_sequence_work.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_extension.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/resources/font_fixture.sats"
staload "font/opentype/substitution/gsub_sequence_contracts.sats"

fun font_errors(): int = if ieq(c_argc(),2) then sequence_test_fonts(c_argv(1)) else 0
fun run(): int = let
  val baseline=mem_live()
  val formats=sequence_test_formats()
  val errors=sequence_test_errors()
  val stress=sequence_test_stress()
  val extension=sequence_test_extension()
  val fonts=font_errors()
  val balanced=ieq(mem_live(),baseline)
  val ()=println!("event=gsub_sequence_conformance format_errors=",formats," malformed_errors=",errors,
    " stress_errors=",stress," extension_errors=",extension," font_errors=",fonts," ownership_balanced=",balanced)
in iadd(formats+errors+stress+extension+fonts,if balanced then 0 else 1) end
implement main0() = let val errors=run() in if igt(errors,0) then exit(errors) else () end
