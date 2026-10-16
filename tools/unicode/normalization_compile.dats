#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/source/text_source.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_draft.sats"
staload "data_text/normalization/normalization_source.sats"
staload "data_text/normalization/normalization_graph.sats"
staload "data_text/normalization/normalization_graph_build.sats"
staload "data_text/normalization/normalization_exclusions.sats"
staload "data_text/normalization/normalization_writer.sats"

fun exclusions(draft: !NormalizationDraft): bool = case+ text_file_read(c_argv(2)) of
  | ~TextFileError(code) => false
  | ~TextFile(source) => let
      val valid = normalization_draft_exclude(draft,source)
      val () = buf_free(source)
    in valid end

fun compile_draft(draft: !NormalizationDraft): bool = let
  val acyclic = normalization_draft_graph(draft)
  val excluded = acyclic andalso exclusions(draft)
in excluded andalso normalization_draft_write(draft,c_argv(3)) end

fun compile_source(source: !Buf): bool = case+ normalization_source(source) of
  | ~DraftRejected(error) => false
  | ~DraftLoaded(draft) => let
      val valid = compile_draft(draft)
      val () = normalization_draft_dispose(draft)
    in valid end

fun run(): bool = case+ text_file_read(c_argv(1)) of
  | ~TextFileError(code) => false
  | ~TextFile(source) => let
      val valid = compile_source(source)
      val () = buf_free(source)
    in valid end

implement main0() = if ine(c_argc(),4) then exit(2) else if run() then () else exit(1)
