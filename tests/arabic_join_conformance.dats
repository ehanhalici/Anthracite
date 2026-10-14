#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_property.sats"
staload "data_text/arabic_join_types.sats"
staload "data_text/arabic_join.sats"
staload "data_font/glyph_run_types.sats"
staload "arabic_join_contracts.sats"
fun run(map: !PropertyMap(3)): int = let
  val plan=arabic_test_plan()
  val masks=arabic_test_masks() and examples=arabic_test_examples(map,plan)
  val boundaries=arabic_test_boundaries(map,plan) and rules=arabic_test_rules(map,plan)
  val stress=arabic_test_stress(map,plan)
  val ()=arabic_mask_dispose(plan)
  val ()=println!("event=arabic_join_conformance mask_errors=",masks," example_errors=",examples,
    " boundary_errors=",boundaries," rule_errors=",rules," stress_errors=",stress)
in masks+examples+boundaries+rules+stress end
fun load(path: string): int = case+ property_load(path,JoiningProperty()) of
  | ~PropertyRejected(e) => 1 | ~PropertyLoaded(map) => let
    val errors=run(map) val ()=property_dispose(map)
  in errors end
implement main0() = let
  val before=mem_live()
  val errors=if ieq(c_argc(),2) then load(c_argv(1)) else 1
  val balanced=ieq(before,mem_live())
  val ()=println!("event=arabic_join_ownership buf_balanced=",balanced)
  val result=iadd(errors,if balanced then 0 else 1)
in if igt(result,0) then exit(result) else () end
