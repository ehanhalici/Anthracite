#include "font/native/text/native_pipeline_test.hats"
fun note(assets: !NativeTextAssets,latin: !SfntFace,arabic: !SfntFace): int =
  if ieq(c_argc(),6) then pipeline_note_cases(assets,latin,arabic,c_argv(5)) else 0
fun faces(assets: !NativeTextAssets,latin: !SfntFace): int = case+ sfnt_open(c_argv(4)) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(arabic) => let val errors=pipeline_shape_cases(assets,latin,arabic)
    val checked=note(assets,latin,arabic)
    val ()=sfnt_dispose(arabic) in errors+checked end
fun loaded(assets: !NativeTextAssets): int = case+ sfnt_open(c_argv(3)) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(latin) => let val errors=faces(assets,latin)
    val ()=sfnt_dispose(latin) in errors end
fun cases(): int = if ine(c_argc(),5) andalso ine(c_argc(),6) then 1 else
  case+ native_text_assets_load(@{generated=c_argv(1),source=c_argv(2)}) of
  | ~NativeAssetsRejected(e) => 1 | ~NativeAssetsAccepted(assets) => let
    val ranges=pipeline_range_cases(assets) and contexts=pipeline_context_cases(assets) and shapes=loaded(assets)
    val coverage=pipeline_coverage_cases(assets)
    val ()=println!("event=native_pipeline ranges=",ranges," contexts=",contexts," shapes=",shapes," coverage=",coverage)
    val ()=native_text_assets_dispose(assets)
  in ranges+contexts+shapes+coverage end
fun ownership(before: int): int = if ieq(before,mem_live()) then 0 else 1
implement main0() = let val before=mem_live() val errors=cases()
  val owned=ownership(before)
  val ()=println!("event=native_pipeline_result errors=",errors," buf_errors=",owned)
in if igt(iadd(errors,owned),0) then exit(1) else () end
