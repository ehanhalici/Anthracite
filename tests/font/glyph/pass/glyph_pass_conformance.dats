#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "font/glyph/pass/glyph_pass_contracts.sats"
staload "font/opentype/substitution/gsub_single_contracts.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_types.sats"
staload "font/glyph/core/glyph_lookup_contracts.sats"
staload "font/glyph/core/glyph_sequence_contracts.sats"
staload "font/glyph/core/glyph_nominal_contracts.sats"
staload "font/glyph/core/glyph_ligation_contracts.sats"
staload "font/glyph/core/glyph_window_contracts.sats"
staload "font/glyph/core/glyph_reverse_contracts.sats"
staload "font/glyph/substitution/glyph_substitution_cache_contracts.sats"
staload "font/glyph/context/glyph_context_arena_contracts.sats"
staload "font/glyph/substitution/glyph_substitution_engine_contracts.sats"
staload "font/glyph/substitution/glyph_substitution_stage_contracts.sats"
staload "data_text/unicode/unicode_property.sats"
staload "font/glyph/core/glyph_unicode_contracts.sats"
staload "font/opentype/shape/ot_shape_contracts.sats"
fun nominal_fonts(): int = if ieq(c_argc(),5) orelse ieq(c_argc(),6) orelse ieq(c_argc(),7) then
  nominal_test_fonts(c_argv(1),c_argv(2),c_argv(3),c_argv(4)) else 0
fun fonts(): int = if ieq(c_argc(),1) then 0 else if ieq(c_argc(),3) orelse ieq(c_argc(),5) orelse ieq(c_argc(),6) orelse ieq(c_argc(),7) then
  pass_test_font(c_argv(1),SingleLatin())+pass_test_font(c_argv(2),SingleArabic())+seq_test_fonts(c_argv(2))
    +ligation_test_fonts(c_argv(1),c_argv(2))+substitution_cache_fonts(c_argv(1),c_argv(2))+nominal_fonts() else 1
typedef PassCounts = @{basic=int,sparse=int,stress=int,fonts=int,cache=int,lookup=int,neighbor=int,
  sequence=int,sequenceCache=int,sequenceMultiple=int,sequenceAlternate=int,ligation=int,window=int,reverse=int}
fun reverse_tests(): int = let
  val basic=reverse_pass_basic() and cache=reverse_pass_cache() and rollback=reverse_pass_rollback()
  val masks=reverse_pass_masks() and stress=reverse_pass_stress()
  val ()=println!("event=glyph_reverse_pass basic_errors=",basic," cache_errors=",cache,
    " rollback_errors=",rollback," mask_errors=",masks," stress_errors=",stress)
in basic+cache+rollback+masks+stress end
fun substitution_tests(): int = let
  val encodings=substitution_engine_encodings() and mutations=substitution_engine_mutations()
  val rollback=substitution_engine_rollback() and priority=substitution_engine_priority() and stress=substitution_engine_stress()
  val stage=substitution_stage_cases()
  val plans=shape_test_cases()
  val ()=println!("event=ot_shape_plans errors=",plans)
  val schedule=plans+shape_test_execution()
  val ()=println!("event=ot_shape_schedule errors=",schedule)
  val ()=println!("event=glyph_substitution_engine encoding_errors=",encodings," mutation_errors=",mutations,
    " rollback_errors=",rollback," priority_errors=",priority," stress_errors=",stress," stage_errors=",stage)
in encodings+mutations+rollback+priority+stress+stage+schedule end
fun unicode_test_ignored(category: !PropertyMap(6)): int = case+ property_load(c_argv(6),IgnorableProperty()) of
  | ~PropertyRejected(e) => 1 | ~PropertyLoaded(ignored) => let
    val properties=unicode_glyph_test_properties(category,ignored) and substitutions=unicode_glyph_test_substitution(category,ignored)
    val ()=property_dispose(ignored)
    val ()=println!("event=glyph_unicode properties_errors=",properties," substitution_errors=",substitutions)
  in properties+substitutions end
fun unicode_tests(): int = if not(ieq(c_argc(),7)) then 0 else case+ property_load(c_argv(5),CategoryProperty()) of
  | ~PropertyRejected(e) => 1 | ~PropertyLoaded(category) => let
    val errors=unicode_test_ignored(category) val ()=property_dispose(category) in errors end
fun synthetic(): PassCounts = let
  val basic=pass_test_basic() and sparse=pass_test_sparse() and stress=pass_test_stress()
  val font_errors=fonts()
  val cache_errors=pass_test_cached()+pass_test_cache_stress()+substitution_cache_contexts()+substitution_cache_errors()
  val lookup_errors=lookup_test_filters()+lookup_test_properties()+lookup_test_references()+lookup_test_capacity()
  val neighbor_errors=lookup_test_neighbors()+lookup_test_neighbor_sparse()+lookup_test_neighbor_stress()+lookup_test_neighbor_rejections()
  val sequence_cache=seq_test_cache() and sequence_multiple=seq_test_multiple() and sequence_alternate=seq_test_alternate()
  val sequence_errors=sequence_cache+sequence_multiple+sequence_alternate+seq_test_filters()+seq_test_rejections()+seq_test_stress()
  val ligation=ligation_test_basic()+ligation_test_associations()+ligation_test_masks()+ligation_test_cache()
  val window=window_test_basic()+window_test_masks()+window_test_rejections()+window_test_associations()
  val arena=context_arena_edits()+context_arena_rejections()+context_arena_stress()
  val ()=println!("event=glyph_context_arena errors=",arena)
  val reverse=reverse_tests()+arena+substitution_tests()+unicode_tests()
in @{basic=basic,sparse=sparse,stress=stress,fonts=font_errors,cache=cache_errors,lookup=lookup_errors,
  neighbor=neighbor_errors,sequence=sequence_errors,sequenceCache=sequence_cache,sequenceMultiple=sequence_multiple,
  sequenceAlternate=sequence_alternate,ligation=ligation,window=window,reverse=reverse} end
fun report(c: PassCounts,balanced: bool): void = let
  val ()=println!("event=glyph_sequence_conformance cache_errors=",c.sequenceCache,
    " multiple_errors=",c.sequenceMultiple," alternate_errors=",c.sequenceAlternate)
in println!("event=glyph_pass_conformance basic_errors=",c.basic," sparse_errors=",c.sparse,
  " stress_errors=",c.stress," font_errors=",c.fonts," cache_errors=",c.cache,
  " lookup_errors=",c.lookup," neighbor_errors=",c.neighbor," sequence_errors=",c.sequence,
  " ligation_errors=",c.ligation," window_errors=",c.window," reverse_errors=",c.reverse," buf_balanced=",balanced) end
implement main0() = let
  val before=mem_live()
  val c=synthetic()
  val balanced=ieq(before,mem_live())
  val ()=report(c,balanced)
  val errors=iadd(c.basic+c.sparse+c.stress+c.fonts+c.cache+c.lookup+c.neighbor+c.sequence+c.ligation+c.window+c.reverse,if balanced then 0 else 1)
in if igt(errors,0) then exit(errors) else () end
