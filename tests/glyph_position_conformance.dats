#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "os/fs.sats"
staload "data_font/opentype_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_position_types.sats"
staload "glyph_position_contracts.sats"
staload "glyph_position_context_contracts.sats"
staload "native_shape_contracts.sats"
fun buffer_errors(baseline: int): int = if ieq(baseline,mem_live()) then 0 else 1
typedef PositionErrors = @{scale=int,single=int,pair=int,cursive=int,lookup=int,measure=int,mark=int,graph=int,stage=int,context=int}
fun synthetic(): PositionErrors = let
  val scale_errors: int=position_test_scale_cases()
  val single_errors: int=position_test_single_cases()
  val pair_errors: int=position_test_pair_cases()
  val cursive_errors: int=position_test_cursive_cases()
  val lookup_errors: int=position_test_lookup_cases()+position_test_lookup_pair_cases()+position_test_lookup_mark_cases()+position_test_lookup_error_cases()
  val measure_errors: int=position_test_measure_cases()
  val mark_errors: int=position_test_mark_cases()
  val graph_errors: int=position_test_graph_cases()
  val stage_errors: int=position_test_stage_cases()+native_test_script_cases()
  val context=position_context_basic()+position_context_nested()+position_context_rollback()+position_context_cache()
    +position_context_encodings()+position_context_stress()+position_context_order()
in @{scale=scale_errors,single=single_errors,pair=pair_errors,cursive=cursive_errors,
  lookup=lookup_errors,measure=measure_errors,mark=mark_errors,graph=graph_errors,stage=stage_errors,context=context} end
fun fonts(): int = if ieq(c_argc(),5) orelse ieq(c_argc(),6) orelse ieq(c_argc(),9) then position_test_fonts(c_argv(1),c_argv(2),c_argv(3),c_argv(4))
  else if ieq(c_argc(),1) then 0 else 2
fun normalized(): int = if ieq(c_argc(),6) orelse ieq(c_argc(),9) then position_test_normalized(c_argv(1),c_argv(2),c_argv(3),c_argv(5)) else 0
fun native_tests(): int = if ieq(c_argc(),9) then native_test_suite() else 0
fun total(e: PositionErrors): int = e.scale+e.single+e.pair+e.cursive+e.lookup+e.measure+e.mark+e.graph+e.stage+e.context
fun report(e: PositionErrors,font_errors: int,normalized_errors: int,ownership: int): void = let
  val ()=println!("event=glyph_position_conformance scale_errors=",e.scale," single_errors=",e.single," pair_errors=",e.pair)
  val ()=println!("event=glyph_position_attachments mark_errors=",e.mark," graph_errors=",e.graph," buffer_errors=",ownership)
  val ()=println!("event=glyph_position_fonts errors=",font_errors)
  val ()=println!("event=glyph_position_cursive errors=",e.cursive)
  val ()=println!("event=glyph_position_lookup errors=",e.lookup)
  val ()=println!("event=font_run_measure errors=",e.measure)
  val ()=println!("event=glyph_position_stage errors=",e.stage)
  val ()=println!("event=glyph_position_context errors=",e.context)
in println!("event=glyph_normalized errors=",normalized_errors) end
implement main0() = let
  val baseline=mem_live()
  val cases=synthetic() and font_errors=fonts() and normalized_errors=normalized()
  val native_errors=native_tests()
  val ownership=buffer_errors(baseline)
  val errors=iadd(iadd(total(cases),font_errors),iadd(normalized_errors,iadd(ownership,native_errors)))
  val ()=report(cases,font_errors,normalized_errors,ownership)
  val ()=println!("event=native_shape errors=",native_errors)
in if igt(errors,0) then exit(errors) else () end
