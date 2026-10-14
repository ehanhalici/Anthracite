#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/normalization_types.sats"
staload "normalization_contracts.sats"
staload "data_text/normalization_load.sats"
staload "data_text/normalization_data.sats"

fun run_loaded(data: !NormalizationData): int = let
  val before = mem_live()
  val source = normalization_source_contracts()
  val provenance = normalization_provenance_contracts(data)
  val blob = normalization_blob_contracts(c_argv(1))
  val balanced = ieq(before,mem_live())
  val () = println!("event=normalization_contracts source_errors=",source," provenance_errors=",provenance," blob_errors=",blob," balanced=",balanced)
in iadd(source,iadd(provenance,iadd(blob,if balanced then 0 else 1))) end

fun run(): int = case+ normalization_load(c_argv(1)) of
  | ~NormalizationRejected(error) => 1
  | ~NormalizationLoaded(data) => let
      val errors = run_loaded(data)
      val () = normalization_dispose(data)
    in errors end

implement main0() = if ine(c_argc(),2) then exit(2) else if igt(run(),0) then exit(1) else ()
